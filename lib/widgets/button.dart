import 'dart:math';

import 'package:flutter/material.dart';
// theme_controller not needed here

class Button extends StatefulWidget {
  final String letter;
  final bool isHighlighted;
  const Button({super.key, required this.letter, this.isHighlighted = false});

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = (MediaQuery.of(context).size.width) / 3;
    double screenHeight = (MediaQuery.of(context).size.height) / 3;
    double boxWidth = min(screenWidth, screenHeight) * (1 / 3.8);
    Widget boxIcon = Text(
      widget.letter,
      style: TextStyle(fontSize: 40, color: Colors.white),
    );
    if (widget.letter.toLowerCase() == 'o') {
      boxIcon = Icon(
        Icons.circle_outlined,
        color: Colors.white,
        size: boxWidth * 0.9,
      );
    } else if (widget.letter.toLowerCase() == 'x') {
      boxIcon = Icon(Icons.close_rounded, color: Colors.white, size: boxWidth);
    }
    return Container(
      margin: EdgeInsets.all(boxWidth / 10),
      width: boxWidth,
      height: boxWidth,
      child: Stack(
        children: [
          // Main button background
          Container(
            color: Theme.of(context).primaryColor,
            // child: Center(child: boxIcon),
          ),
          // Highlight overlay (doesn't affect layout)
          if (widget.isHighlighted)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Explicitly transparent
                    border: Border.all(color: Colors.yellow, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(92, 255, 235, 59),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.amber,
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Container(
            // color: Theme.of(context).primaryColor,
            child: Center(child: boxIcon),
          ),
        ],
      ),
    );
  }
}
