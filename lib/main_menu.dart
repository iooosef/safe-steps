import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/experimental.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/safetysteps_game.dart';

class MainMenu extends World with HasGameReference<SafetyStepsGame> {
  @override
  Future<void> onLoad() async {
    game.setWorld(this);

    SpriteComponent background = SpriteComponent()
      ..sprite = await game.loadSprite('menu_bg.png')
      ..size = Vector2(1280, 720)
      ..position = Vector2(0, 0)
      ..anchor = Anchor.topLeft;
    add(background);

    SpriteComponent logo = SpriteComponent()
      ..sprite = await game.loadSprite('menu_logo.png');
    logo.size = Vector2(
      logo.sprite!.srcSize.x * .8,
      logo.sprite!.srcSize.y * .8,
    );

    Sprite playButtonSprite = await game.loadSprite(
      'earthquake/buttons/PlayButton.png',
    );

    SpriteButtonComponent playButton = SpriteButtonComponent()
      ..button = playButtonSprite;
    playButton
      ..size = Vector2(
        playButton.button!.srcSize.x * 0.75,
        playButton.button!.srcSize.y * 0.75,
      )
      ..onPressed = () {
        debugPrint('Play button pressed');
        final targetSize = playButton.button!.srcSize;

        playButton.add(
          SizeEffect.to(
            Vector2(targetSize.x, targetSize.y),
            EffectController(
              duration: 0.1,
              reverseDuration: 0.1,
              repeatCount: 1,
            ),
          ),
        );
        Future.delayed(const Duration(milliseconds: 200), () {
          game.router.pushNamed('level_select');
        });
      };

    ColumnComponent menuItems =
        ColumnComponent(
            gap: 20,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [logo, playButton],
          )
          ..anchor = Anchor.center
          ..position = Vector2(game.size.x / 2, game.size.y / 2);
    add(menuItems);
    // menuItems.debugMode = true;

    return super.onLoad();
  }
}
