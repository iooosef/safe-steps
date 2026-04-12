import 'package:flutter/material.dart';
import 'package:flame/components.dart';

class HintLabel extends PositionComponent {
  static const double _padX = 12;
  static const double _padY = 6;
  static const _bgColor = Color(0xFFEEEEEE);
  static const _radius = Radius.circular(8);

  late final TextComponent _label;

  @override
  Future<void> onLoad() async {
    _label = TextComponent(
      text: 'Tap to continue ⏩',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Color(0xFF555555),
          fontSize: 16,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
          fontFamily: 'Comic Relief',
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(_padX, _padY),
    );
    await add(_label);

    // Size this component to wrap the text tightly
    size = _label.size + Vector2(_padX * 2, _padY * 2);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = _bgColor;
    canvas.drawRRect(RRect.fromRectAndRadius(size.toRect(), _radius), paint);
    super.render(canvas); // draws children (the TextComponent)
  }
}
