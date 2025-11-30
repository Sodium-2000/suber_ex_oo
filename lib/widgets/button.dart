import 'dart:math';

import 'package:flutter/material.dart';
// theme_controller not needed here

class Button extends StatefulWidget {
  final String letter;
  const Button({super.key, required this.letter});

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
      // color: Colors.pink,
      color: Theme.of(context).primaryColor,
      width: boxWidth,
      height: boxWidth,
      child: Center(
        // child: Text(widget.letter, style: TextStyle(fontSize: boxWidth)),
        child: boxIcon,
      ),
    );
  }
}
