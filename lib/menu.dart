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
  late final World world;
  late final CameraComponent camera;

  @override
  Future<void> onLoad() async {
    world = World();
    camera = CameraComponent.withFixedResolution(
      width: 1280,
      height: 720,
      world: world,
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    // 1. Grab the guaranteed 1280x720 size
    final virtualSize = camera.viewport.virtualSize;

    // 2. Add background
    final bgSprite = await game.loadSprite('menu_bg.png');
    final bg = SpriteComponent()
      ..sprite = bgSprite
      ..size = virtualSize
      ..position = Vector2.zero();
    camera.viewport.add(bg);

    // 3. Base the logo math ONLY on virtualSize
    final logoSprite = await game.loadSprite('menu_logo.png');
    final logoWidth = virtualSize.x * 0.5;
    final logoHeight = logoWidth * logoSprite.srcSize.y / logoSprite.srcSize.x;

    final logo = SpriteComponent()
      ..sprite = logoSprite
      ..size = Vector2(logoWidth, logoHeight)
      ..anchor = Anchor.center
      ..x =
          virtualSize.x /
          2 // Dead center horizontally
      ..y = virtualSize.y / 3; // One-third down the screen

    // 4. Base the button math ONLY on virtualSize
    final playButton = PlayButton()
      ..anchor = Anchor.center
      ..x =
          virtualSize.x /
          2 // Dead center horizontally
      ..y = virtualSize.y / 2; // Dead center vertically

    // 5. Add to viewport
    camera.viewport.addAll([logo, playButton]);
    addAll([world, camera]);
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
