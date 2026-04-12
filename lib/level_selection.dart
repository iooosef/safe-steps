import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/experimental.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:safesteps/safetysteps_game.dart';

class LevelSelection extends World with HasGameReference<SafetyStepsGame> {
  final Map<String, LevelData> levelButtons = {
    "Earthquake": LevelData(
      path: "earthquake/buttons/ModeSelectionButton.png",
      route: "earthquake_level_1",
    ),
    "Fire": LevelData(
      path: "fire/FireOption (Beginning).png",
      route: "fire_level_1",
    ),
  };

  @override
  Future<void> onLoad() async {
    game.setWorld(this);

    SpriteComponent background = SpriteComponent()
      ..sprite = await game.loadSprite('menu_bg.png')
      ..size = Vector2(1280, 720)
      ..position = Vector2(0, 0)
      ..anchor = Anchor.topLeft;
    add(background);

    for (var entry in levelButtons.entries) {
      final levelName = entry.key;
      final levelData = entry.value;
      Sprite sprite = await game.loadSprite(levelData.path);
      entry.value.spriteButton!
        ..button = sprite
        ..size = sprite.srcSize * 0.15
        ..onPressed = () {
          debugPrint('$levelName button pressed');
          entry.value.spriteButton!.add(
            SizeEffect.to(
              sprite.srcSize * 0.175,
              EffectController(
                duration: 0.1,
                reverseDuration: 0.1,
                repeatCount: 1,
              ),
            ),
          );

          Future.delayed(const Duration(milliseconds: 200), () {
            game.router.pushNamed(levelData.route);
          });
        };
    }

    RowComponent levelSelectionItems =
        RowComponent(
            gap: 20,
            mainAxisAlignment: MainAxisAlignment.center,
            // Note: RowComponent usually handles children placement via its own logic
            children: levelButtons.entries.map((entry) {
              final levelName = entry.key;
              final data = entry.value;

              // Create a TextComponent for the label
              // Use a TextPaint to style it (size, color, etc.)
              final textLabel = TextComponent(
                text: levelName,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: 'Cherry Bomb One',
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
              );

              // Create the Column to stack Button and Text
              return ColumnComponent(
                gap: 2,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  data.spriteButton!, // Your SpriteButtonComponent
                  textLabel, // Your TextComponent
                ],
              );
            }).toList(),
          )
          ..anchor = Anchor.center
          ..position = Vector2(game.size.x / 2, game.size.y / 2);
    add(levelSelectionItems);
    // levelSelectionItems.debugMode = true;
    return super.onLoad();
  }
}

class LevelData {
  final String path;
  final String route;
  SpriteButtonComponent? spriteButton;
  LevelData({required this.path, required this.route}) {
    spriteButton = SpriteButtonComponent();
  }
}
