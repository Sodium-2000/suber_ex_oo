import 'dart:math';
import 'package:flutter/material.dart';
import 'package:super_xo/theme/theme_controller.dart';

/// Decorative background of X/O pieces (styled like the marks used in the
/// actual game) that spawn at random times and slide slowly down the
/// screen, in random colors drawn from the app's color palette
/// (ThemeController.colorPresets, kept in sync with the Settings screen).
///
/// Generalized so any screen can drop it in behind its real content, e.g.
/// `Scaffold(body: FloatingPiecesBackground(child: ...))`.
class FloatingPiecesBackground extends StatelessWidget {
  final Widget child;
  final int pieceCount;
  final double opacity;

  /// true: each piece picks a random color from ThemeController.colorPresets.
  /// false: every piece uses the app's current primary color instead.
  final bool randomizeColors;

  const FloatingPiecesBackground({
    super.key,
    required this.child,
    this.pieceCount = 20,
    this.opacity = 0.4,
    this.randomizeColors = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: List.generate(
                  pieceCount,
                  (i) => _FallingPiece(
                    key: ValueKey(i),
                    opacity: opacity,
                    canvasSize: constraints.biggest,
                    randomizeColors: randomizeColors,
                  ),
                ),
              );
            },
          ),
        ),
        child,
      ],
    );
  }
}

class _FallingPiece extends StatefulWidget {
  final double opacity;
  final Size canvasSize;
  final bool randomizeColors;

  const _FallingPiece({
    super.key,
    required this.opacity,
    required this.canvasSize,
    required this.randomizeColors,
  });

  @override
  State<_FallingPiece> createState() => _FallingPieceState();
}

class _FallingPieceState extends State<_FallingPiece>
    with TickerProviderStateMixin {
  final Random _random = Random();
  late final AnimationController _controller;
  late final AnimationController _popController;
  late final Animation<double> _popScale;
  late final Animation<double> _popOpacity;
  late final Listenable _tickers;

  bool _isX = true;
  Color _color = Colors.grey;
  double _leftFraction = 0;
  double _size = 32;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _respawn();
      });

    _popController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 450),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _isPopping = false;
            _popController.value = 0;
            _respawn();
          }
        });
    _popScale = Tween<double>(
      begin: 1.0,
      end: 1.8,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_popController);
    _popOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: widget.opacity, end: 1.0),
        weight: 35,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 65),
    ]).animate(_popController);
    _tickers = Listenable.merge([_controller, _popController]);

    _randomizeAppearance();
    // Stagger first appearances so pieces don't all start at once.
    Future.delayed(Duration(milliseconds: _random.nextInt(8000)), () {
      if (mounted) _respawn();
    });
  }

  void _pop() {
    if (_isPopping) return;
    _isPopping = true;
    _controller.stop();
    _popController.forward(from: 0);
  }

  void _randomizeAppearance() {
    _isX = _random.nextBool();
    if (widget.randomizeColors) {
      final presets = ThemeController.colorPresets;
      _color = presets[_random.nextInt(presets.length)].primary;
    } else {
      _color = ThemeController.primaryColor.value;
    }
    _leftFraction = _random.nextDouble();
    _size = 24 + _random.nextDouble() * 28;
  }

  void _respawn() {
    if (!mounted) return;
    setState(_randomizeAppearance);
    _controller
      ..duration = Duration(milliseconds: 9000 + _random.nextInt(9000))
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tickers,
      builder: (context, _) {
        final travel = widget.canvasSize.height + _size * 2;
        final top = -_size + _controller.value * travel;
        final maxLeft = (widget.canvasSize.width - _size).clamp(
          0.0,
          double.infinity,
        );
        final scale = _isPopping ? _popScale.value : 1.0;
        final currentOpacity = _isPopping ? _popOpacity.value : widget.opacity;
        return Positioned(
          left: _leftFraction * maxLeft,
          top: top,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _pop,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: currentOpacity,
                child: Icon(
                  _isX ? Icons.close_rounded : Icons.circle_outlined,
                  size: _size,
                  color: _color,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
