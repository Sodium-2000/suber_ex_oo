import 'dart:math';

import 'package:flutter/material.dart';
import 'package:super_xo/theme/app_theme.dart';
import 'package:super_xo/widgets/button.dart';
import 'package:super_xo/services/game_settings_service.dart';
import 'package:super_xo/services/sound_service.dart';

class SmallBoard extends StatefulWidget {
  final String currentTurn;
  final void Function(String playedBy, int boardIndex, int cellIndex)
  onMovePlayed;
  final Function(String winner, int index)? onBoardWon;
  final int index;
  final bool isActive;
  final bool isUltimateGameOver;
  final int resetSignal;
  final bool isOnlineMode;
  final bool isMyTurn;

  const SmallBoard({
    super.key,
    required this.currentTurn,
    required this.onMovePlayed,
    required this.index,
    required this.isActive,
    this.onBoardWon,
    required this.isUltimateGameOver,
    required this.resetSignal,
    this.isOnlineMode = false,
    this.isMyTurn = true,
  });

  @override
  SmallBoardState createState() => SmallBoardState();
}

class SmallBoardState extends State<SmallBoard> {
  List<String> board3x3 = ['', '', '', '', '', '', '', '', ''];
  bool isGameOver = false;
  String winner = ''; // '', 'x', 'o'
  String turn = 'x'; // 'x', 'o'
  int? lastMoveCellIndex; // Track last move for highlighting
  final _gameSettings = GameSettingsService();
  final _soundService = SoundService();

  @override
  void initState() {
    super.initState();
    _loadDimmingSetting();
    _soundService.initialize();
    // Listen to dimming setting changes
    _gameSettings.dimmingEnabled.addListener(_onDimmingChanged);
  }

  @override
  void dispose() {
    _gameSettings.dimmingEnabled.removeListener(_onDimmingChanged);
    super.dispose();
  }

  void _onDimmingChanged() {
    if (mounted) {
      setState(() {
        // Rebuild when dimming setting changes
      });
    }
  }

  Future<void> _loadDimmingSetting() async {
    await _gameSettings.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  bool checkGameOver() {
    if (isGameOver) {
      return true;
    }

    if (board3x3[0] == board3x3[1] &&
        board3x3[0] == board3x3[2] &&
        board3x3[0] != '') {
      winner = board3x3[0];
      isGameOver = true;
      widget.onBoardWon?.call(winner, widget.index);
      setState(() {});
      return true;
    }
    if (board3x3[3] == board3x3[4] &&
        board3x3[3] == board3x3[5] &&
        board3x3[3] != '') {
      winner = board3x3[3];
      isGameOver = true;
      widget.onBoardWon?.call(winner, widget.index);
      setState(() {});
      return true;
    }
    if (board3x3[6] == board3x3[7] &&
        board3x3[6] == board3x3[8] &&
        board3x3[6] != '') {
      winner = board3x3[6];
      isGameOver = true;
      widget.onBoardWon?.call(winner, widget.index);
      setState(() {});
      return true;
    }
    if (board3x3[0] == board3x3[3] &&
        board3x3[0] == board3x3[6] &&
        board3x3[0] != '') {
      winner = board3x3[0];
      isGameOver = true;
      widget.onBoardWon?.call(winner, widget.index);
      setState(() {});
      return true;
    }
    if (board3x3[1] == board3x3[4] &&
        board3x3[1] == board3x3[7] &&
        board3x3[1] != '') {
      winner = board3x3[1];
      isGameOver = true;
      widget.onBoardWon?.call(winner, widget.index);
      setState(() {});
      return true;
    }
    if (board3x3[2] == board3x3[5] &&
        board3x3[2] == board3x3[8] &&
        board3x3[2] != '') {
      winner = board3x3[2];
      isGameOver = true;
      widget.onBoardWon?.call(winner, widget.index);
      setState(() {});
      return true;
    }
    if (board3x3[0] == board3x3[4] &&
        board3x3[0] == board3x3[8] &&
        board3x3[0] != '') {
      winner = board3x3[0];
      isGameOver = true;
      widget.onBoardWon?.call(winner, widget.index);
      setState(() {});
      return true;
    }
    if (board3x3[2] == board3x3[4] &&
        board3x3[2] == board3x3[6] &&
        board3x3[2] != '') {
      winner = board3x3[2];
      isGameOver = true;
      widget.onBoardWon?.call(winner, widget.index);
      setState(() {});
      return true;
    }

    // draw detection: full board and no winner
    if (board3x3.every((c) => c != '')) {
      winner = 'draw';
      isGameOver = true;
      widget.onBoardWon?.call(winner, widget.index);
      setState(() {});
      return true;
    }

    return false;
  }

  void play(int index) {
    if (widget.isUltimateGameOver) return; // 🚫 block all moves
    if (!widget.isActive) return; // not the active small board
    if (isGameOver) return; // board is finished
    if (board3x3[index] != '') return; // cell already occupied

    // In online mode, just send move to server - don't play locally
    // Server will broadcast back and we'll update via playCell
    if (widget.isOnlineMode) {
      widget.onMovePlayed(widget.currentTurn, widget.index, index);
      return;
    }

    // Local mode: Make the move immediately
    setState(() {
      board3x3[index] = widget.currentTurn;
      lastMoveCellIndex = index; // Track last move
    });

    checkGameOver();
    widget.onMovePlayed(
      widget.currentTurn,
      widget.index,
      index,
    ); // notify parent whose turn just played and which cell
  }

  // Public method for parent to update cell (used in online mode)
  void playCell(int cellIndex, String symbol) {
    setState(() {
      board3x3[cellIndex] = symbol;
      lastMoveCellIndex = cellIndex; // Track last move
    });
    checkGameOver();
  }

  // Public method to update highlight (used for undo)
  void setLastMove(int? cellIndex) {
    setState(() {
      lastMoveCellIndex = cellIndex;
    });
  }

  // Public method to clear highlight
  void clearHighlight() {
    setState(() {
      lastMoveCellIndex = null;
    });
  }

  // Public method to force game over state (used for reconnection)
  void forceGameOver(String winnerSymbol) {
    setState(() {
      winner = winnerSymbol;
      isGameOver = true;
    });
  }

  // Public method to restore full board state (used for reconnection)
  void restoreState(
    List<String> cells,
    String boardWinner,
    bool boardIsGameOver,
  ) {
    print('🔄 SmallBoard ${widget.index}: restoreState called');
    print('   Cells: $cells');
    print('   Winner: $boardWinner');
    print('   IsGameOver: $boardIsGameOver');
    setState(() {
      board3x3 = List<String>.from(cells);
      winner = boardWinner;
      isGameOver = boardIsGameOver;
      lastMoveCellIndex = null; // Clear highlight on restore
    });
    print('✅ SmallBoard ${widget.index}: State restored');
  }

  // compute winner without mutating or notifying parent
  String computeWinner() {
    List<List<int>> lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (var line in lines) {
      String a = board3x3[line[0]];
      String b = board3x3[line[1]];
      String c = board3x3[line[2]];
      if (a != '' && a == b && a == c) return a;
    }
    if (board3x3.every((c) => c != '')) return 'draw';
    return '';
  }

  // Undo a move at cellIndex and return the new board status: '', 'x', 'o', or 'draw'
  String undoMoveAt(int cellIndex) {
    if (cellIndex < 0 || cellIndex > 8) return winner;
    if (board3x3[cellIndex] == '') return winner;
    board3x3[cellIndex] = '';

    // Clear highlight if undoing the last move
    if (lastMoveCellIndex == cellIndex) {
      lastMoveCellIndex = null;
    }

    // recompute winner/draw
    String newWinner = computeWinner();
    if (newWinner == '') {
      winner = '';
      isGameOver = false;
    } else {
      winner = newWinner;
      isGameOver = true;
    }
    setState(() {});
    return winner;
  }

  Widget getWinnerWidget(double size) {
    if (!isGameOver) {
      return Text('');
    }
    if (winner == 'o') {
      return Icon(
        Icons.circle_outlined,
        size: size * 0.85,
        // color: Theme.of(context).primaryColor,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(1),
            blurRadius: 10.0,
            offset: Offset(5.0, 5.0),
          ),
          Shadow(
            color: Colors.black.withOpacity(1),
            blurRadius: 10.0,
            offset: Offset(-3.0, -3.0),
          ),
        ],
      );
    } else if (winner == 'x') {
      // return Icon(Icons.cancel_outlined, size: size);
      // return Container(
      //   child: Center(
      //     child: Text('x', style: TextStyle(fontSize: size / 1)),
      //   ),
      // );
      return Icon(
        Icons.close_rounded,
        size: size,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(1),
            blurRadius: 10.0,
            offset: Offset(5.0, 5.0),
          ),
          Shadow(
            color: Colors.black.withOpacity(1),
            blurRadius: 10.0,
            offset: Offset(-3.0, -3.0),
          ),
        ],
      );
    } else {
      return Icon(
        Icons.dnd_forwardslash_rounded,
        size: size * 0.85,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(1),
            blurRadius: 10.0,
            offset: Offset(5.0, 5.0),
          ),
          Shadow(
            color: Colors.black.withOpacity(1),
            blurRadius: 10.0,
            offset: Offset(-3.0, -3.0),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = (MediaQuery.of(context).size.width) / 3;
    double screenHeight = (MediaQuery.of(context).size.height) / 3;
    double minScreenSize = min(screenHeight, screenWidth);
    // Dimming logic:
    // - In local mode: dim if not active (wrong board to play on)
    // - In online mode: ONLY dim inactive boards when it IS your turn
    // - When ultimate game is over: undim everything (show final board state)
    // - When small board is won: still dim it
    // - Respect user's dimming preference from settings
    final bool shouldDim = widget.isUltimateGameOver
        ? false
        : (isGameOver ||
              (widget.isOnlineMode
                  ? (widget.isMyTurn && !widget.isActive)
                  : !widget.isActive));

    final bool isDimmed = _gameSettings.isDimmingEnabled && shouldDim;

    return Container(
      height: minScreenSize,
      width: minScreenSize,
      decoration: BoxDecoration(
        // border: Border.all(color: Colors.grey, width: 2),
        border: Border.all(
          color:
              Theme.of(context).extension<AppColors>()?.border ??
              Colors.pinkAccent.shade100,
          width: 2,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // board grid
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    child: Button(
                      letter: board3x3[0],
                      isHighlighted: lastMoveCellIndex == 0,
                    ),
                    onTap: () {
                      _soundService.play(SoundEffect.move);
                      play(0);
                    },
                  ),
                  GestureDetector(
                    child: Button(
                      letter: board3x3[1],
                      isHighlighted: lastMoveCellIndex == 1,
                    ),
                    onTap: () {
                      _soundService.play(SoundEffect.move);
                      play(1);
                    },
                  ),
                  GestureDetector(
                    child: Button(
                      letter: board3x3[2],
                      isHighlighted: lastMoveCellIndex == 2,
                    ),
                    onTap: () {
                      _soundService.play(SoundEffect.move);
                      play(2);
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    child: Button(
                      letter: board3x3[3],
                      isHighlighted: lastMoveCellIndex == 3,
                    ),
                    onTap: () {
                      _soundService.play(SoundEffect.move);
                      play(3);
                    },
                  ),
                  GestureDetector(
                    child: Button(
                      letter: board3x3[4],
                      isHighlighted: lastMoveCellIndex == 4,
                    ),
                    onTap: () {
                      _soundService.play(SoundEffect.move);
                      play(4);
                    },
                  ),
                  GestureDetector(
                    child: Button(
                      letter: board3x3[5],
                      isHighlighted: lastMoveCellIndex == 5,
                    ),
                    onTap: () {
                      _soundService.play(SoundEffect.move);
                      play(5);
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    child: Button(
                      letter: board3x3[6],
                      isHighlighted: lastMoveCellIndex == 6,
                    ),
                    onTap: () {
                      _soundService.play(SoundEffect.move);
                      play(6);
                    },
                  ),
                  GestureDetector(
                    child: Button(
                      letter: board3x3[7],
                      isHighlighted: lastMoveCellIndex == 7,
                    ),
                    onTap: () {
                      _soundService.play(SoundEffect.move);
                      play(7);
                    },
                  ),
                  GestureDetector(
                    child: Button(
                      letter: board3x3[8],
                      isHighlighted: lastMoveCellIndex == 8,
                    ),
                    onTap: () {
                      _soundService.play(SoundEffect.move);
                      play(8);
                    },
                  ),
                ],
              ),
            ],
          ),

          // winner icon
          Center(child: getWinnerWidget(minScreenSize)),

          // dim overlay for inactive or solved boards (blocks interaction)
          Positioned.fill(
            child: IgnorePointer(
              // when not dimmed, ignore the overlay so taps pass through
              // when dimmed, overlay participates and blocks interaction
              ignoring: !isDimmed,
              child: AnimatedOpacity(
                opacity: isDimmed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(color: Colors.black.withOpacity(0.6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant SmallBoard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // if resetCounter changed, reset the board
    if (widget.resetSignal != oldWidget.resetSignal) {
      setState(() {
        board3x3 = List.filled(9, '');
        winner = '';
        isGameOver = false;
        lastMoveCellIndex = null; // Clear highlight on reset
      });
    }
  }
}
