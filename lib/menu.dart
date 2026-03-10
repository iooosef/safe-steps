import 'dart:async';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flame/text.dart';
import 'package:safesteps/ssgame.dart';

class Menu extends Component with HasGameReference<SSGame> {
  @override
  Future<void> onLoad() async {
    final parallxComponent = await game.loadParallaxComponent([
      ParallaxImageData('menu_bg.png'),
    ]);
    add(parallxComponent);

    final logoSprite = await game.loadSprite('menu_logo.png');
    final logoWidth = game.size.x * 0.5;
    final logoHeight = logoWidth * logoSprite.srcSize.y / logoSprite.srcSize.x;
    final logo = SpriteComponent()
      ..sprite = logoSprite
      ..size = Vector2(logoWidth, logoHeight)
      ..anchor = Anchor.center
      ..x = game.size.x / 2
      ..y = game.size.y / 3;

    add(logo);

    add(
      PlayButton()
        ..anchor = Anchor.center
        ..x = game.size.x / 2
        ..y = game.size.y / 2,
    );
  }
}

// Play Button Component
class PlayButton extends PositionComponent
    with TapCallbacks, HasGameReference<SSGame> {
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

  @override
  void onTapUp(TapUpEvent event) {
    // Optional: Add a slight delay before navigating to allow the tap effect to complete
    Future.delayed(const Duration(milliseconds: 100), () {
      game.router.pushNamed('levels');
    });
  }
}
