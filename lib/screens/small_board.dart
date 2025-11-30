import 'dart:math';

import 'package:flutter/material.dart';
import 'package:super_xo/theme/app_theme.dart';
import 'package:super_xo/widgets/button.dart';

class SmallBoard extends StatefulWidget {
  final String currentTurn;
  final void Function(String playedBy, int boardIndex, int cellIndex)
  onMovePlayed;
  final Function(String winner, int index)? onBoardWon;
  final int index;
  final bool isActive;
  final bool isUltimateGameOver;
  final int resetSignal;

  const SmallBoard({
    super.key,
    required this.currentTurn,
    required this.onMovePlayed,
    required this.index,
    required this.isActive,
    this.onBoardWon,
    required this.isUltimateGameOver,
    required this.resetSignal,
  });

  @override
  State<SmallBoard> createState() => _SmallBoard();
}

class _SmallBoard extends State<SmallBoard> {
  List<String> board3x3 = ['', '', '', '', '', '', '', '', ''];
  bool isGameOver = false;
  String winner = ''; // '', 'x', 'o'
  String turn = 'x'; // 'x', 'o'

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
    if (!isGameOver && board3x3[index] == '') {
      board3x3[index] = widget.currentTurn;
      checkGameOver();
      widget.onMovePlayed(
        widget.currentTurn,
        widget.index,
        index,
      ); // notify parent whose turn just played and which cell
      setState(() {});
    }
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
    // When the ultimate game is over, visually undim all boards.
    final bool isDimmed =
        !widget.isUltimateGameOver && (!widget.isActive || isGameOver);

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
                    child: Button(letter: board3x3[0]),
                    onTap: () {
                      play(0);
                    },
                  ),
                  GestureDetector(
                    child: Button(letter: board3x3[1]),
                    onTap: () {
                      play(1);
                    },
                  ),
                  GestureDetector(
                    child: Button(letter: board3x3[2]),
                    onTap: () {
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
                    child: Button(letter: board3x3[3]),
                    onTap: () {
                      play(3);
                    },
                  ),
                  GestureDetector(
                    child: Button(letter: board3x3[4]),
                    onTap: () {
                      play(4);
                    },
                  ),
                  GestureDetector(
                    child: Button(letter: board3x3[5]),
                    onTap: () {
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
                    child: Button(letter: board3x3[6]),
                    onTap: () {
                      play(6);
                    },
                  ),
                  GestureDetector(
                    child: Button(letter: board3x3[7]),
                    onTap: () {
                      play(7);
                    },
                  ),
                  GestureDetector(
                    child: Button(letter: board3x3[8]),
                    onTap: () {
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
      });
    }
  }
}
