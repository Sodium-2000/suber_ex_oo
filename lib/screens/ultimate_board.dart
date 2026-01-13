import 'package:flutter/material.dart';
import 'dart:async';
import 'package:super_xo/screens/small_board.dart';
import 'package:super_xo/localization/app_localizations.dart';
import 'package:super_xo/models/game_mode.dart';
import 'package:super_xo/services/websocket_service.dart';
import 'package:super_xo/models/websocket_message.dart';
import 'package:super_xo/screens/settings_screen.dart';
import 'package:super_xo/services/sound_service.dart';

class UltimateBoard extends StatefulWidget {
  final GameMode gameMode;
  final WebSocketService? wsService;
  final String? playerId;
  final String? playerSymbol;
  final String? roomCode;
  final Map<String, dynamic>? initialGameState; // For reconnection

  const UltimateBoard({
    super.key,
    required this.gameMode,
    this.wsService,
    this.playerId,
    this.playerSymbol,
    this.roomCode,
    this.initialGameState,
  });

  @override
  State<UltimateBoard> createState() => _UltimateBoard();
}

class _UltimateBoard extends State<UltimateBoard> {
  String currentTurn = 'x';
  List<String> bigBoard = List.filled(9, '');
  String? bigWinner;
  bool isUltimateGameOver = false;
  int activeBoard = -1; // -1 means player can play in any non-completed board
  List<int>? winningTriple;
  // keys to access SmallBoard state for undo
  final List<GlobalKey> smallBoardKeys = List.generate(9, (_) => GlobalKey());

  // move history: entries are (player, boardIndex, cellIndex)
  final List<Map<String, dynamic>> moveHistory = [];

  // WebSocket subscription for online mode
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  // Sound service
  final _soundService = SoundService();

  // Online mode state
  bool get isOnlineMode => widget.gameMode == GameMode.online;
  String? _currentPlayerSymbol; // Track current symbol (can swap on restart)
  bool get isMyTurn => !isOnlineMode || currentTurn == _currentPlayerSymbol;
  bool _isOpponentDisconnected = false;
  bool _isReconnecting = false;
  bool _hasRequestedRestart = false;
  bool _opponentRequestedRestart = false;
  bool _isGamePaused = false;

  // Pending move tracking for reconnection
  Map<String, dynamic>? _pendingMove;
  Timer? _moveTimeoutTimer;

  @override
  void initState() {
    super.initState();

    // Initialize current player symbol
    _currentPlayerSymbol = widget.playerSymbol;

    // Initialize sound service
    _soundService.initialize();

    // Initialize from reconnection data if available
    if (widget.initialGameState != null) {
      print('🔄 UltimateBoard: Initializing from game state on reconnection');
      print('🔄 Game state data: ${widget.initialGameState}');
      _initializeFromGameState(widget.initialGameState!);
    } else {
      print('⚠️ UltimateBoard: No initialGameState provided');
    }

    if (isOnlineMode) {
      _listenToWebSocketMessages();
    }
  }

  void _listenToWebSocketMessages() {
    _wsSubscription = widget.wsService?.messages.listen(
      (message) {
        final type = message['type'];
        final payload = message['payload'];

        switch (type) {
          case 'MOVE_MADE':
            _handleOpponentMove(payload);
            break;
          case 'GAME_RESTARTED':
            _handleGameRestarted(payload);
            break;
          case 'RESTART_REQUESTED':
            _handleRestartRequested(payload);
            break;
          case 'OPPONENT_LEFT':
            _handleOpponentLeft();
            break;
          case 'PLAYER_DISCONNECTED':
            _handlePlayerDisconnected(payload);
            break;
          case 'PLAYER_RECONNECTED':
            _handlePlayerReconnected(payload);
            break;
          case 'RECONNECTED':
            _handleReconnected(payload);
            break;
          case 'ROOM_TIMEOUT':
            _handleRoomTimeout(payload);
            break;
          case 'GAME_PAUSED':
            _handleGamePaused(payload);
            break;
          case 'GAME_RESUMED':
            _handleGameResumed(payload);
            break;
          case 'ROOM_CLOSING_SOON':
            _handleRoomClosingSoon(payload);
            break;
          case 'CONNECTION_LOST':
            _handleConnectionLost();
            break;
        }
      },
      onError: (error) {
        // Connection lost, attempt to reconnect
        if (!_isReconnecting) {
          _attemptReconnection();
        }
      },
      onDone: () {
        // Connection closed, attempt to reconnect
        if (!_isReconnecting) {
          _attemptReconnection();
        }
      },
    );
  }

  Future<void> _attemptReconnection() async {
    if (_isReconnecting) return;

    setState(() {
      _isReconnecting = true;
    });

    try {
      // Try to reconnect to server
      await widget.wsService?.connect('wss://super-xo-backend.onrender.com');

      // Send reconnection message
      widget.wsService?.send(
        ReconnectMessage(
          playerId: widget.playerId!,
          roomCode: widget.roomCode!,
        ),
      );

      // Re-listen to messages
      _listenToWebSocketMessages();
    } catch (e) {
      setState(() {
        _isReconnecting = false;
      });

      // Show error and exit to menu
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: Text(tr('connection_failed')),
            content: Text(tr('server_unreachable')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _exitGame();
                },
                child: Text(tr('return_to_menu')),
              ),
            ],
          ),
        );
      }
    }
  }

  void _handleOpponentMove(Map<String, dynamic> payload) {
    // Clear pending move on any move confirmation
    _pendingMove = null;
    _moveTimeoutTimer?.cancel();
    
    final moveData = MoveData.fromJson(payload);
    // In online mode, process ALL moves from server (including our own)
    // This ensures synchronization - the client doesn't play locally

    final boardIndex = moveData.boardIndex;
    final cellIndex = moveData.cellIndex;
    final playedBy = moveData.playedBy;

    // Clear all previous highlights before setting the new one
    for (int i = 0; i < 9; i++) {
      final key = smallBoardKeys[i];
      if (key.currentState != null) {
        try {
          SmallBoardState s = key.currentState as SmallBoardState;
          s.clearHighlight();
        } catch (_) {}
      }
    }

    // Update the specific cell in the small board
    final smallBoardKey = smallBoardKeys[boardIndex];
    final smallBoardState = smallBoardKey.currentState as SmallBoardState?;
    if (smallBoardState != null) {
      smallBoardState.playCell(cellIndex, playedBy);
    }

    // Update game state
    setState(() {
      // push to history
      moveHistory.add({
        'player': playedBy,
        'board': boardIndex,
        'cell': cellIndex,
        'prevActive': activeBoard,
      });

      // toggle turn
      currentTurn = (playedBy == 'x') ? 'o' : 'x';

      // route next active board
      if (cellIndex >= 0 && cellIndex < 9) {
        if (bigBoard[cellIndex] == '') {
          activeBoard = cellIndex;
        } else {
          activeBoard = -1;
        }
      } else {
        activeBoard = -1;
      }
    });
  }

  void _handleGameRestarted(Map<String, dynamic> payload) {
    // Reset local game state WITHOUT sending message back to server
    setState(() {
      moveHistory.clear();
      currentTurn = 'x';

      // Update player symbol if server sent new one (roles swapped)
      if (payload['playerSymbol'] != null) {
        _currentPlayerSymbol = payload['playerSymbol'];
      }

      bigWinner = null;
      winningTriple = null;
      isUltimateGameOver = false;
      bigBoard = List.filled(9, '');
      resetCounter++; // 🔥 triggers SmallBoards to rebuild/reset
      activeBoard = -1;
      _hasRequestedRestart = false;
      _opponentRequestedRestart = false;
    });
  }

  void _handleRestartRequested(Map<String, dynamic> payload) {
    setState(() {
      _opponentRequestedRestart = true;
    });

    // Show notification that opponent wants to restart
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(payload['message'] ?? 'Opponent wants to restart'),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'Restart',
          textColor: Colors.white,
          onPressed: () {
            if (!_hasRequestedRestart) {
              // Send restart approval to server
              setState(() {
                _hasRequestedRestart = true;
              });
              widget.wsService?.send(RestartGameMessage());
            }
          },
        ),
      ),
    );
  }

  void _handlePlayerDisconnected(Map<String, dynamic> payload) {
    setState(() {
      _isOpponentDisconnected = true;
      _isGamePaused = true;
    });

    // Show a non-blocking notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('player_disconnected')),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handlePlayerReconnected(Map<String, dynamic> payload) {
    setState(() {
      _isOpponentDisconnected = false;
      _isReconnecting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(payload['message'] ?? 'Opponent reconnected'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleReconnected(Map<String, dynamic> payload) {
    // Successfully reconnected, restore game state from server
    _initializeFromGameState(payload);

    // Resend pending move if exists
    if (_pendingMove != null) {
      print('🔄 Resending pending move after reconnection');
      try {
        widget.wsService?.send(
          MakeMoveMessage(
            boardIndex: _pendingMove!['boardIndex'],
            cellIndex: _pendingMove!['cellIndex'],
          ),
        );
        // Restart the timeout timer
        _moveTimeoutTimer?.cancel();
        _moveTimeoutTimer = Timer(const Duration(seconds: 5), () {
          if (_pendingMove != null && mounted) {
            print('⚠️ Move confirmation timeout after resend - clearing pending move');
            _pendingMove = null;
          }
        });
      } catch (e) {
        print('❌ Error resending pending move: $e');
        _pendingMove = null;
        _moveTimeoutTimer?.cancel();
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reconnected successfully!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _initializeFromGameState(Map<String, dynamic> payload) {
    print('🔄 _initializeFromGameState called');
    final gameState = payload['gameState'];
    final serverActiveBoard = payload['activeBoard'];
    final serverCurrentTurn = payload['currentTurn'];

    print('🔄 gameState: $gameState');
    print('🔄 serverActiveBoard: $serverActiveBoard');
    print('🔄 serverCurrentTurn: $serverCurrentTurn');

    if (gameState != null) {
      // Restore the game state from server
      final smallBoards = gameState['smallBoards'] as List<dynamic>;
      final bigBoard = gameState['bigBoard'] as List<dynamic>;

      print('🔄 Restoring ${smallBoards.length} small boards');

      setState(() {
        // Update current turn and active board
        if (serverCurrentTurn != null) {
          currentTurn = serverCurrentTurn;
        }
        if (serverActiveBoard != null) {
          activeBoard = serverActiveBoard;
        }

        // Update big board winners
        this.bigBoard = List<String>.from(bigBoard);

        _isReconnecting = false;
      });

      // Wait for the next frame to ensure all SmallBoard widgets are built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('🔄 PostFrameCallback: Restoring small boards');
        // Apply all moves to each small board
        for (
          int boardIndex = 0;
          boardIndex < smallBoards.length;
          boardIndex++
        ) {
          final boardData = smallBoards[boardIndex];
          final cells = List<String>.from(boardData['cells']);
          final winner = boardData['winner'] ?? '';
          final isGameOver = boardData['isGameOver'] ?? false;

          print(
            '🔄 Board $boardIndex: cells=$cells, winner=$winner, isGameOver=$isGameOver',
          );

          // Get the small board state
          final smallBoardKey = smallBoardKeys[boardIndex];
          final smallBoardState =
              smallBoardKey.currentState as SmallBoardState?;

          if (smallBoardState != null) {
            print('✅ Restoring board $boardIndex');
            // Restore the entire board state at once
            smallBoardState.restoreState(cells, winner, isGameOver);
          } else {
            print('❌ Board $boardIndex state is null!');
          }
        }
      });
    } else {
      print('❌ gameState is null!');
      setState(() {
        _isReconnecting = false;
      });
    }
  }

  void _handleRoomTimeout(Map<String, dynamic> payload) {
    // Room was closed due to inactivity
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(tr('room_timeout')),
        content: Text(payload['message'] ?? 'Room closed due to inactivity'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _exitGame();
            },
            child: Text(tr('return_to_menu')),
          ),
        ],
      ),
    );
  }

  void _handleGamePaused(Map<String, dynamic> payload) {
    // Clear any pending move when game is paused
    _pendingMove = null;
    _moveTimeoutTimer?.cancel();
    
    setState(() {
      _isGamePaused = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(payload['reason'] ?? 'Game paused'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleGameResumed(Map<String, dynamic> payload) {
    setState(() {
      _isGamePaused = false;
      _isOpponentDisconnected = false;
      _isReconnecting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(payload['message'] ?? 'Game resumed'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleRoomClosingSoon(Map<String, dynamic> payload) {
    final timeLeft = payload['timeLeft'] ?? 60;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room closing in $timeLeft seconds. Reconnect now!'),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Reconnect',
          onPressed: _attemptReconnection,
        ),
      ),
    );
  }

  void _handleConnectionLost() {
    setState(() {
      _isReconnecting = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connection lost. Attempting to reconnect...'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Center(
          child: Text(
            tr('exit_title'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        content: FittedBox(
          child: Center(
            child: Text(
              tr('exit_message'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              tr('cancel'),
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _exitGame();
            },
            child: Text(
              tr('exit'),
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceAround,
      ),
    );
  }

  void _exitGame() {
    // If in online mode, send leave room message
    if (isOnlineMode) {
      widget.wsService?.send(LeaveRoomMessage());
      // Dispose WebSocket connection
      widget.wsService?.dispose();
    }

    // Navigate back to start menu (remove all routes and go to root)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _leaveRoom() {
    // Send leave room message and exit
    widget.wsService?.send(LeaveRoomMessage());
    _exitGame();
  }

  void _handleOpponentLeft() {
    // Reset restart flags when opponent leaves
    setState(() {
      _hasRequestedRestart = false;
      _opponentRequestedRestart = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Center(
          child: Text(
            tr('opponent_left'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        content: Text(
          tr('opponent_disconnected'),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to menu
            },
            child: Text(
              tr('return_to_menu'),
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  @override
  void dispose() {
    // Cancel move timeout timer
    _moveTimeoutTimer?.cancel();
    
    // Cancel WebSocket subscription
    _wsSubscription?.cancel();

    if (isOnlineMode) {
      // Only send leave message, don't dispose the WebSocket service
      // The lobby screen manages the WebSocket lifecycle
      widget.wsService?.send(LeaveRoomMessage());
    }
    super.dispose();
  }

  void handleMove(String playedBy, int cellIndex) {
    setState(() {
      currentTurn = (playedBy == 'x') ? 'o' : 'x';
    });
  }

  // more explicit handler used by SmallBoard: (playedBy, boardIndex, cellIndex)
  void handleMoveFull(String playedBy, int boardIndex, int cellIndex) {
    // Don't allow moves if game is paused
    if (_isGamePaused) {
      return;
    }
    
    // In online mode, send to server and wait for server to broadcast back
    if (isOnlineMode) {
      try {
        // Cancel any existing pending move timeout
        _moveTimeoutTimer?.cancel();
        
        // Set pending move
        _pendingMove = {
          'boardIndex': boardIndex,
          'cellIndex': cellIndex,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        
        // Send the move
        widget.wsService?.send(
          MakeMoveMessage(boardIndex: boardIndex, cellIndex: cellIndex),
        );
        
        // Start timeout timer for move confirmation
        _moveTimeoutTimer = Timer(const Duration(seconds: 5), () {
          if (_pendingMove != null && mounted) {
            print('⚠️ Move confirmation timeout - attempting reconnection');
            _pendingMove = null;
            if (!_isReconnecting) {
              _attemptReconnection();
            }
          }
        });
        
        return; // Don't update state locally - wait for server confirmation
      } catch (e) {
        print('❌ Error sending move: $e');
        // If sending fails, clear pending move and try to reconnect
        _pendingMove = null;
        _moveTimeoutTimer?.cancel();
        if (!_isReconnecting) {
          _attemptReconnection();
        }
        return;
      }
    }

    // Local mode: Clear all previous highlights before new move
    for (int i = 0; i < 9; i++) {
      if (i != boardIndex) {
        final key = smallBoardKeys[i];
        if (key.currentState != null) {
          try {
            SmallBoardState s = key.currentState as SmallBoardState;
            s.clearHighlight();
          } catch (_) {}
        }
      }
    }

    // Local mode: update immediately
    setState(() {
      // push to history (record previous activeBoard so undo can fully restore)
      moveHistory.add({
        'player': playedBy,
        'board': boardIndex,
        'cell': cellIndex,
        'prevActive': activeBoard,
      });

      // toggle turn
      currentTurn = (playedBy == 'x') ? 'o' : 'x';

      // route next active board
      if (cellIndex >= 0 && cellIndex < 9) {
        if (bigBoard[cellIndex] == '') {
          activeBoard = cellIndex;
        } else {
          activeBoard = -1;
        }
      } else {
        activeBoard = -1;
      }
    });
  }

  void handleBoardWon(String winner, int index) {
    setState(() {
      // store winner; allow 'draw' as a marker of completed board
      bigBoard[index] = winner;
      checkBigWinner();
    });
  }

  // undo the last move if possible
  void undoLastMove() {
    if (moveHistory.isEmpty || isUltimateGameOver) return;
    final last = moveHistory.removeLast();
    final String player = last['player'];
    final int boardIndex = last['board'];
    final int cellIndex = last['cell'];
    final int? prevActive = last['prevActive'];

    // call child's undo
    final key = smallBoardKeys[boardIndex];
    if (key.currentState != null) {
      try {
        dynamic s = key.currentState;
        s.undoMoveAt(cellIndex);
      } catch (_) {}
    }

    setState(() {
      if (bigBoard[boardIndex] != '') {
        final key2 = smallBoardKeys[boardIndex];
        if (key2.currentState != null) {
          try {
            dynamic s = key2.currentState;
            String w = s.computeWinner();
            if (w == '') {
              bigBoard[boardIndex] = '';
            } else {
              bigBoard[boardIndex] = w;
            }
          } catch (_) {
            bigBoard[boardIndex] = '';
          }
        } else {
          bigBoard[boardIndex] = '';
        }
      }

      // toggle turn back
      currentTurn = (player == 'x') ? 'x' : 'o';

      // restore previous active board (where play was allowed before the undone move)
      activeBoard = prevActive ?? -1;
      // clear any big winner (undo cancels game end)
      bigWinner = null;
      isUltimateGameOver = false;
    });

    // Clear all highlights first
    for (int i = 0; i < 9; i++) {
      final key = smallBoardKeys[i];
      if (key.currentState != null) {
        try {
          SmallBoardState s = key.currentState as SmallBoardState;
          s.clearHighlight();
        } catch (_) {}
      }
    }

    // Update highlight to show the new last move (if any)
    if (moveHistory.isNotEmpty) {
      final newLast = moveHistory.last;
      final int newBoardIndex = newLast['board'];
      final int newCellIndex = newLast['cell'];
      final key = smallBoardKeys[newBoardIndex];
      if (key.currentState != null) {
        try {
          SmallBoardState s = key.currentState as SmallBoardState;
          s.setLastMove(newCellIndex);
        } catch (_) {}
      }
    }
  }

  void checkBigWinner() {
    // Horizontal
    for (int i = 0; i < 9; i += 3) {
      if (bigBoard[i] != '' &&
          bigBoard[i] != 'draw' &&
          bigBoard[i] == bigBoard[i + 1] &&
          bigBoard[i] == bigBoard[i + 2]) {
        bigWinner = bigBoard[i];
        winningTriple = [i, i + 1, i + 2];
        isUltimateGameOver = true;
        _playGameEndSound(); // Play appropriate sound
        showBigWinnerDialog();
        return;
      }
    }

    // Vertical
    for (int i = 0; i < 3; i++) {
      if (bigBoard[i] != '' &&
          bigBoard[i] != 'draw' &&
          bigBoard[i] == bigBoard[i + 3] &&
          bigBoard[i] == bigBoard[i + 6]) {
        bigWinner = bigBoard[i];
        winningTriple = [i, i + 3, i + 6];
        isUltimateGameOver = true;
        _playGameEndSound(); // Play appropriate sound
        showBigWinnerDialog();
        return;
      }
    }

    // Diagonals
    if (bigBoard[0] != '' &&
        bigBoard[0] != 'draw' &&
        bigBoard[0] == bigBoard[4] &&
        bigBoard[0] == bigBoard[8]) {
      bigWinner = bigBoard[0];
      winningTriple = [0, 4, 8];
      isUltimateGameOver = true;
      _playGameEndSound(); // Play appropriate sound
      showBigWinnerDialog();
      return;
    }

    if (bigBoard[2] != '' &&
        bigBoard[2] != 'draw' &&
        bigBoard[2] == bigBoard[4] &&
        bigBoard[2] == bigBoard[6]) {
      bigWinner = bigBoard[2];
      winningTriple = [2, 4, 6];
      isUltimateGameOver = true;
      _playGameEndSound(); // Play appropriate sound
      showBigWinnerDialog();
      return;
    }

    // if all small boards are completed and no big winner -> draw
    if (bigBoard.every((b) => b != '') && bigWinner == null) {
      bigWinner = 'draw';
      winningTriple = null;
      isUltimateGameOver = true;
      _soundService.play(SoundEffect.draw); // Play draw sound
      showBigWinnerDialog();
      return;
    }
  }

  void _playGameEndSound() {
    // Determine if player won or lost
    if (isOnlineMode && _currentPlayerSymbol != null) {
      if (bigWinner == _currentPlayerSymbol) {
        _soundService.play(SoundEffect.win);
      } else {
        _soundService.play(SoundEffect.loss);
      }
    } else {
      // In local mode, always play win sound
      _soundService.play(SoundEffect.win);
    }
  }

  void showBigWinnerDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Center(
          child: Text(
            tr('game_over_title'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        content: Text(
          bigWinner == 'draw'
              ? tr('game_over_draw')
              : trWithWinner('game_over_winner', bigWinner!.toUpperCase()),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              // play again
              _restartGame();
              Navigator.pop(context);
            },
            child: Text(
              tr('play_again'),
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              tr('close'),
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceAround,
      ),
    );
  }

  int resetCounter = 0;
  void _restartGame() {
    // In online mode, only send restart request to server
    // Don't reset local state until server broadcasts GAME_RESTARTED
    if (isOnlineMode) {
      if (!_hasRequestedRestart) {
        setState(() {
          _hasRequestedRestart = true;
        });
        widget.wsService?.send(RestartGameMessage());

        // Show waiting indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waiting for opponent to approve restart...'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Local mode: reset immediately
    setState(() {
      moveHistory.clear();
      currentTurn = 'x';
      bigWinner = null;
      winningTriple = null;
      isUltimateGameOver = false;
      bigBoard = List.filled(9, '');
      resetCounter++; // 🔥 triggers SmallBoards to rebuild/reset
      activeBoard = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: isOnlineMode
              ? null // Disable undo in online mode
              : undoLastMove,
          icon: const Icon(Icons.undo),
          tooltip: isOnlineMode ? null : tr('undo_tool'),
        ),
        title: Container(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOnlineMode) ...[
                // Show player indicator in online mode
                Text(
                  '${tr('you_are')}: ',
                  style: const TextStyle(fontSize: 14),
                ),
                Container(
                  width: 24,
                  child: _currentPlayerSymbol == 'x'
                      ? const Icon(Icons.close_rounded, size: 24)
                      : const Icon(Icons.circle_outlined, size: 20),
                ),
                const SizedBox(width: 16),
                const Text('|'),
                const SizedBox(width: 16),
              ],
              const Text('['),
              Container(
                width: 30,
                child: currentTurn == 'x'
                    ? const Icon(Icons.close_rounded, size: 29)
                    : const Icon(
                        Icons.circle_outlined,
                        fontWeight: FontWeight.bold,
                      ),
              ),
              const Text(']'),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          // Exit button
          IconButton(
            onPressed: _showExitDialog,
            icon: const Icon(Icons.exit_to_app),
            tooltip: tr('exit_game'),
          ),

          // Settings button (consolidated theme, language, color)
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: tr('settings'),
          ),

          // restart (with localized confirmation dialog)
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Center(
                    child: Text(
                      tr('restart_title'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  content: FittedBox(
                    child: Center(
                      child: Text(
                        tr('restart_message'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        tr('cancel'),
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _restartGame();
                        Navigator.pop(context);
                      },
                      child: Text(
                        tr('restart'),
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ],
                  actionsAlignment: MainAxisAlignment.spaceAround,
                ),
              );
            },
            icon: const Icon(Icons.restart_alt),
            tooltip: tr('restart_game_tool'),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: FittedBox(
                fit: BoxFit.contain, // ensures the grid fits perfectly
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SmallBoard(
                          key: smallBoardKeys[0],
                          currentTurn: currentTurn,
                          onMovePlayed: handleMoveFull,
                          onBoardWon: handleBoardWon,
                          index: 0,
                          isActive:
                              (activeBoard == -1 || activeBoard == 0) &&
                              isMyTurn && !_isGamePaused,
                          isUltimateGameOver: isUltimateGameOver,
                          resetSignal: resetCounter,
                          isOnlineMode: isOnlineMode,
                        ),
                        SmallBoard(
                          key: smallBoardKeys[1],
                          currentTurn: currentTurn,
                          onMovePlayed: handleMoveFull,
                          onBoardWon: handleBoardWon,
                          index: 1,
                          isActive:
                              (activeBoard == -1 || activeBoard == 1) &&
                              isMyTurn && !_isGamePaused,
                          isUltimateGameOver: isUltimateGameOver,
                          resetSignal: resetCounter,
                          isOnlineMode: isOnlineMode,
                        ),
                        SmallBoard(
                          key: smallBoardKeys[2],
                          currentTurn: currentTurn,
                          onMovePlayed: handleMoveFull,
                          onBoardWon: handleBoardWon,
                          index: 2,
                          isActive:
                              (activeBoard == -1 || activeBoard == 2) &&
                              isMyTurn && !_isGamePaused,
                          isUltimateGameOver: isUltimateGameOver,
                          resetSignal: resetCounter,
                          isOnlineMode: isOnlineMode,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SmallBoard(
                          key: smallBoardKeys[3],
                          currentTurn: currentTurn,
                          onMovePlayed: handleMoveFull,
                          onBoardWon: handleBoardWon,
                          index: 3,
                          isActive:
                              (activeBoard == -1 || activeBoard == 3) &&
                              isMyTurn && !_isGamePaused,
                          isUltimateGameOver: isUltimateGameOver,
                          resetSignal: resetCounter,
                          isOnlineMode: isOnlineMode,
                        ),
                        SmallBoard(
                          key: smallBoardKeys[4],
                          currentTurn: currentTurn,
                          onMovePlayed: handleMoveFull,
                          onBoardWon: handleBoardWon,
                          index: 4,
                          isActive:
                              (activeBoard == -1 || activeBoard == 4) &&
                              isMyTurn && !_isGamePaused,
                          isUltimateGameOver: isUltimateGameOver,
                          resetSignal: resetCounter,
                          isOnlineMode: isOnlineMode,
                        ),
                        SmallBoard(
                          key: smallBoardKeys[5],
                          currentTurn: currentTurn,
                          onMovePlayed: handleMoveFull,
                          onBoardWon: handleBoardWon,
                          index: 5,
                          isActive:
                              (activeBoard == -1 || activeBoard == 5) &&
                              isMyTurn && !_isGamePaused,
                          isUltimateGameOver: isUltimateGameOver,
                          resetSignal: resetCounter,
                          isOnlineMode: isOnlineMode,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SmallBoard(
                          key: smallBoardKeys[6],
                          currentTurn: currentTurn,
                          onMovePlayed: handleMoveFull,
                          onBoardWon: handleBoardWon,
                          index: 6,
                          isActive:
                              (activeBoard == -1 || activeBoard == 6) &&
                              isMyTurn && !_isGamePaused,
                          isUltimateGameOver: isUltimateGameOver,
                          resetSignal: resetCounter,
                          isOnlineMode: isOnlineMode,
                        ),
                        SmallBoard(
                          key: smallBoardKeys[7],
                          currentTurn: currentTurn,
                          onMovePlayed: handleMoveFull,
                          onBoardWon: handleBoardWon,
                          index: 7,
                          isActive:
                              (activeBoard == -1 || activeBoard == 7) &&
                              isMyTurn && !_isGamePaused,
                          isUltimateGameOver: isUltimateGameOver,
                          resetSignal: resetCounter,
                          isOnlineMode: isOnlineMode,
                        ),
                        SmallBoard(
                          key: smallBoardKeys[8],
                          currentTurn: currentTurn,
                          onMovePlayed: handleMoveFull,
                          onBoardWon: handleBoardWon,
                          index: 8,
                          isActive:
                              (activeBoard == -1 || activeBoard == 8) &&
                              isMyTurn && !_isGamePaused,
                          isUltimateGameOver: isUltimateGameOver,
                          resetSignal: resetCounter,
                          isOnlineMode: isOnlineMode,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Reconnection/Disconnection overlay
            if (_isReconnecting || _isOpponentDisconnected || _isGamePaused)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(32),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isReconnecting) ...[
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              tr('reconnecting'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ] else if (_isOpponentDisconnected) ...[
                            const Icon(
                              Icons.signal_wifi_off,
                              size: 48,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tr('player_disconnected'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tr('waiting_reconnect'),
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _leaveRoom,
                              child: const Text('Leave Room'),
                            ),
                          ] else if (_isGamePaused) ...[
                            const Icon(
                              Icons.pause_circle_filled,
                              size: 48,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Game Paused',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Waiting for opponent to reconnect...',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
