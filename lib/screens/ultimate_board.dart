import 'package:flutter/material.dart';
import 'package:super_xo/screens/small_board.dart';
import 'package:super_xo/theme/theme_controller.dart';
import 'package:super_xo/controllers/language_controller.dart';
import 'package:super_xo/localization/app_localizations.dart';

class UltimateBoard extends StatefulWidget {
  const UltimateBoard({super.key});

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

  void handleMove(String playedBy, int cellIndex) {
    setState(() {
      currentTurn = (playedBy == 'x') ? 'o' : 'x';
    });
  }

  // more explicit handler used by SmallBoard: (playedBy, boardIndex, cellIndex)
  void handleMoveFull(String playedBy, int boardIndex, int cellIndex) {
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
      showBigWinnerDialog();
      return;
    }

    // if all small boards are completed and no big winner -> draw
    if (bigBoard.every((b) => b != '') && bigWinner == null) {
      bigWinner = 'draw';
      winningTriple = null;
      isUltimateGameOver = true;
      showBigWinnerDialog();
      return;
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
        // leading: currentTurn == 'x' ? Icon(Icons.cancel_outlined) : Icon(Icons.circle_outlined),
        leading: IconButton(
          onPressed: undoLastMove,
          icon: const Icon(Icons.undo),
          tooltip: tr('undo_tool'),
        ),
        // title: Container(child: Text("{  ${currentTurn.toUpperCase()}  }")),
        title: Container(
          child: Row(
            children: [
              Text('['),
              Container(
                width: 30,
                child: currentTurn == 'x'
                    ? Icon(Icons.close_rounded, size: 29)
                    : Icon(Icons.circle_outlined, fontWeight: FontWeight.bold),
              ),
              Text(']'),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          // theme toggle (light/dark)
          ValueListenableBuilder<bool>(
            valueListenable: ThemeController.isDark,
            builder: (context, isDark, _) => IconButton(
              onPressed: ThemeController.toggle,
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode_rounded),
              tooltip: tr('change_theme_tool'),
            ),
          ),

          // language toggle: flips language and shows a 500ms SnackBar with the language name
          IconButton(
            onPressed: () {
              LanguageController.toggleAndSave();
              final label = tr(
                LanguageController.lang.value == 'en'
                    ? 'language_english'
                    : 'language_arabic',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  duration: const Duration(milliseconds: 700),
                  behavior: SnackBarBehavior.floating,

                  backgroundColor: Theme.of(context).primaryColor,
                ),
              );
            },
            icon: const Icon(Icons.language),
            tooltip: tr('toggle_language_tool'),
          ),

          // color cycle
          IconButton(
            onPressed: ThemeController.cyclePreset,
            icon: Icon(Icons.color_lens),
            tooltip: tr('change_color_tool'),
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
      body: Center(
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
                    isActive: (activeBoard == -1 || activeBoard == 0),
                    isUltimateGameOver: isUltimateGameOver,
                    resetSignal: resetCounter,
                  ),
                  SmallBoard(
                    key: smallBoardKeys[1],
                    currentTurn: currentTurn,
                    onMovePlayed: handleMoveFull,
                    onBoardWon: handleBoardWon,
                    index: 1,
                    isActive: (activeBoard == -1 || activeBoard == 1),
                    isUltimateGameOver: isUltimateGameOver,
                    resetSignal: resetCounter,
                  ),
                  SmallBoard(
                    key: smallBoardKeys[2],
                    currentTurn: currentTurn,
                    onMovePlayed: handleMoveFull,
                    onBoardWon: handleBoardWon,
                    index: 2,
                    isActive: (activeBoard == -1 || activeBoard == 2),
                    isUltimateGameOver: isUltimateGameOver,
                    resetSignal: resetCounter,
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
                    isActive: (activeBoard == -1 || activeBoard == 3),
                    isUltimateGameOver: isUltimateGameOver,
                    resetSignal: resetCounter,
                  ),
                  SmallBoard(
                    key: smallBoardKeys[4],
                    currentTurn: currentTurn,
                    onMovePlayed: handleMoveFull,
                    onBoardWon: handleBoardWon,
                    index: 4,
                    isActive: (activeBoard == -1 || activeBoard == 4),
                    isUltimateGameOver: isUltimateGameOver,
                    resetSignal: resetCounter,
                  ),
                  SmallBoard(
                    key: smallBoardKeys[5],
                    currentTurn: currentTurn,
                    onMovePlayed: handleMoveFull,
                    onBoardWon: handleBoardWon,
                    index: 5,
                    isActive: (activeBoard == -1 || activeBoard == 5),
                    isUltimateGameOver: isUltimateGameOver,
                    resetSignal: resetCounter,
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
                    isActive: (activeBoard == -1 || activeBoard == 6),
                    isUltimateGameOver: isUltimateGameOver,
                    resetSignal: resetCounter,
                  ),
                  SmallBoard(
                    key: smallBoardKeys[7],
                    currentTurn: currentTurn,
                    onMovePlayed: handleMoveFull,
                    onBoardWon: handleBoardWon,
                    index: 7,
                    isActive: (activeBoard == -1 || activeBoard == 7),
                    isUltimateGameOver: isUltimateGameOver,
                    resetSignal: resetCounter,
                  ),
                  SmallBoard(
                    key: smallBoardKeys[8],
                    currentTurn: currentTurn,
                    onMovePlayed: handleMoveFull,
                    onBoardWon: handleBoardWon,
                    index: 8,
                    isActive: (activeBoard == -1 || activeBoard == 8),
                    isUltimateGameOver: isUltimateGameOver,
                    resetSignal: resetCounter,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
