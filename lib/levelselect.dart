import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/ssgame.dart';

class LevelSelect extends Component with HasGameReference<SSGame> {
  @override
  FutureOr<void> onLoad() async {
    final parallxComponent = await game.loadParallaxComponent([
      ParallaxImageData('menu_bg.png'),
    ]);
    add(parallxComponent);

    const double btnSize = 140;
    const double gap = 24;
    const double totalWidth = btnSize * 3 + gap * 2;

    final double startX = (game.size.x - totalWidth) / 2;
    final double centerY = game.size.y / 2;

    // Three level buttons, horizontally centered
    final levels = [
      (
        label: 'Earthquake',
        image: 'levels_earthquake.png',
        level: 'earthquake',
      ),
      (label: 'Level 2', image: '', level: ''),
      (label: 'Level 3', image: '', level: ''),
    ];

    for (int i = 0; i < levels.length; i++) {
      final btnCenterX = startX + btnSize * i + gap * i + btnSize / 2;
      add(
        LevelButton(
            label: levels[i].label,
            imagePath: levels[i].image,
            levelRoute: levels[i].level,
          )
          ..anchor = Anchor.center
          ..position = Vector2(btnCenterX, centerY),
      );
    }

    return super.onLoad();
  }
}

class LevelButton extends PositionComponent
    with TapCallbacks, HasGameReference<SSGame> {
  static const double btnSize = 140;
  static const double labelGap = 10;
  static const double borderRadius = 20;

  final String label;
  final String imagePath;
  final String levelRoute;

  Sprite? _bgSprite;
  late TextComponent _label;

  LevelButton({
    required this.label,
    required this.imagePath,
    required this.levelRoute,
  })
    // height = button square + gap + space for label
    : super(size: Vector2(btnSize, btnSize + labelGap + 32));

  @override
  Future<void> onLoad() async {
    // Load background sprite; falls back to solid color if asset is missing
    try {
      _bgSprite = await game.loadSprite(imagePath);
    } catch (_) {
      _bgSprite = null;
    }

    // Outline layer for text shadow effect
    final outline =
        TextComponent(
            text: label,
            textRenderer: TextPaint(
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cherry Bomb One',
                letterSpacing: 3.0,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 4
                  ..color = Colors.black,
              ),
            ),
          )
          ..anchor = Anchor.topCenter
          ..position = Vector2(btnSize / 2, btnSize + labelGap);

    _label =
        TextComponent(
            text: label,
            textRenderer: TextPaint(
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cherry Bomb One',
                letterSpacing: 3.0,
                color: Colors.white,
              ),
            ),
          )
          ..anchor = Anchor.topCenter
          ..position = Vector2(btnSize / 2, btnSize + labelGap);

    add(outline);
    add(_label);
  }

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, btnSize, btnSize),
      const Radius.circular(borderRadius),
    );

    if (_bgSprite != null) {
      // Clip canvas to rounded rect before drawing the sprite
      canvas.save();
      canvas.clipRRect(rrect);
      _bgSprite!.render(canvas, size: Vector2.all(btnSize));
      canvas.restore();
    } else {
      // Fallback solid color while images are not yet added
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFF00a5ff));
    }

    // Subtle dark overlay so text is legible over any image
    canvas.drawRRect(
      rrect,
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );

    super.render(canvas);
  }

  @override
  void onTapDown(TapDownEvent event) {
    add(
      ScaleEffect.by(
        Vector2.all(0.92),
        EffectController(
          duration: 0.08,
          reverseDuration: 0.08,
          curve: Curves.easeInOut,
        ),
      ),
    );
    game.router.pushNamed(levelRoute);
    print('$label pressed, routing to $levelRoute');
  }
}
