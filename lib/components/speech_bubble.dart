import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/components/hintlabel.dart';
import 'package:safesteps/levels/characters_enum.dart';

enum BubbleTail { left, middle, right }

enum BubbleTailDirection { left, right }

class SpeechBubble extends PositionComponent {
  String _text;
  BubbleTail tail;
  BubbleTailDirection tailDirection;
  final double padding;
  final double radius;
  final double tailSize;
  final double maxBubbleWidth;

  static const _style = TextStyle(
    fontSize: 24,
    color: Colors.black,
    fontFamily: 'Comic Relief',
    fontWeight: FontWeight.bold,
  );

  final Paint _bgPaint = Paint()..color = Colors.white;
  final Paint _borderPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  TextPainter? _painter;

  SpeechBubble({
    required String text,
    this.tail = BubbleTail.left,
    this.tailDirection = BubbleTailDirection.left,
    this.padding = 16,
    this.radius = 16,
    this.tailSize = 28,
    this.maxBubbleWidth = 200,
  }) : _text = text;

  @override
  Future<void> onLoad() async {
    _layout(_text);
  }

  void _layout(String text) {
    final maxTextWidth = maxBubbleWidth - padding * 2;

    final painter = TextPainter(
      text: TextSpan(text: text, style: _style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxTextWidth);

    _painter = painter;

    size = Vector2(
      painter.width + padding * 2,
      painter.height + padding * 2 + tailSize,
    );
  }

  void updateText(String newText) {
    _text = newText;
    _layout(newText);
  }

  static Future<void> addTo(
    Component parent,
    Map<(CharactersEnum, String), String> dialog,
    (CharactersEnum, String) characterKey,
    SpeechBubble speechBubble,
    HintLabel tapHint,
  ) async {
    if (characterKey.$1 == CharactersEnum.controller) {
      if (speechBubble.isMounted) {
        parent.remove(speechBubble);
        await speechBubble.removed;
      }
      return;
    }

    if (speechBubble.isMounted) {
      parent.remove(speechBubble);
      await speechBubble.removed;
    }

    parent.add(speechBubble);
    if (!tapHint.isMounted) parent.add(tapHint);
    await speechBubble.loaded;
    speechBubble.updateText(dialog.values.first);
  }

  @override
  void render(Canvas canvas) {
    if (_painter == null) return;

    final path = _buildBubblePath();
    canvas.drawPath(path, _bgPaint);
    canvas.drawPath(path, _borderPaint);

    _painter!.paint(canvas, Offset(padding, padding));
  }

  Path _buildBubblePath() {
    final w = size.x;
    final h = size.y - tailSize;
    final r = radius.clamp(0.0, h / 2);

    // Tail base center X based on position enum
    final double tailCenterX = switch (tail) {
      BubbleTail.left => padding + tailSize / 2,
      BubbleTail.middle => w / 2,
      BubbleTail.right => w - padding - tailSize / 2,
    };

    final double tailBaseLeft = (tailCenterX - tailSize / 2).clamp(
      r,
      w - r - tailSize,
    );
    final double tailBaseRight = tailBaseLeft + tailSize;

    // Tail tip X based on direction
    final double tailTipX = switch (tailDirection) {
      BubbleTailDirection.left => tailBaseLeft,
      BubbleTailDirection.right => tailBaseRight,
    };

    final path = Path();
    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));

    path.lineTo(tailBaseRight, h);
    path.lineTo(tailTipX, size.y); // tail tip points in direction
    path.lineTo(tailBaseLeft, h);

    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    path.close();

    return path;
  }
}
