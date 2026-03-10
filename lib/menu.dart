import 'dart:async';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flame/text.dart';

class Menu extends FlameGame {
  @override
  FutureOr<void> onLoad() async {
    final parallxComponent = await loadParallaxComponent([
      ParallaxImageData('menu_bg.png'),
    ]);
    add(parallxComponent);

    final logo = await SpriteComponent()
      ..sprite = await loadSprite('menu_logo.png')
      ..anchor = Anchor.center
      ..x = size.x / 2
      ..y = size.y / 3;
    add(logo);

    add(
      PlayButton()
        ..anchor = Anchor.center
        ..x = size.x / 2
        ..y = size.y / 2,
    );

    return super.onLoad();
  }
}

// Play Button Component
class PlayButton extends PositionComponent with TapCallbacks {
  final double width = 250;
  final double height = 80;
  final double borderRadius = 20;

  late final TextComponent _label;

  PlayButton() : super(size: Vector2(250, 80)) {
    final center = Vector2(
      width / 2,
      height / 2 - 4,
    ); // adjusted vertical centering for text

    // black outline text layer
    final outline =
        TextComponent(
            text: 'Play',
            textRenderer: TextPaint(
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cherry Bomb One',
                letterSpacing: 3.0,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 6
                  ..color = Colors.black,
              ),
            ),
          )
          ..anchor = Anchor.center
          ..position = center;

    // white fill layer
    _label =
        TextComponent(
            text: 'Play',
            textRenderer: TextPaint(
              style: const TextStyle(
                fontSize: 42,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cherry Bomb One',
                letterSpacing: 3.0,
              ),
            ),
          )
          ..anchor = Anchor.center
          ..position = Vector2(
            width / 2,
            height / 2 - 4,
          ); // adjusted vertical centering

    add(outline);
    add(_label);
  }

  @override
  void render(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      Radius.circular(borderRadius),
    );
    final paint = Paint()..color = Color(0xFF00a5ff);
    canvas.drawRRect(rect, paint);

    super.render(canvas); // draws the label
  }

  @override
  void onTapDown(TapDownEvent event) {
    print('Play Game pressed');
    add(
      ScaleEffect.by(
        Vector2.all(0.9),
        EffectController(
          duration: 0.08,
          reverseDuration: 0.08,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }
}
