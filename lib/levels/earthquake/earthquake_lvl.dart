import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:safesteps/safetysteps_game.dart';

class EarthquakeLvl extends World with HasGameReference<SafetyStepsGame> {
  @override
  Future<void> onLoad() async {
    game.setWorld(this);
    double screenWidth = game.size.x;
    double screenHeight = game.size.y;

    // DURATIONS
    final double comicDuration = 2.0;
    final double hallwayDuration = 5.0;

    // PAN comic background
    Sprite panningBackground = await game.loadSprite(
      'earthquake/comic/full_page_background.png',
    );
    // Calculate scaled dimensions to fit screen width
    double comicAspectRatio = 1024 / 768; // Height / Width of image
    double comicScaledHeight = screenWidth * comicAspectRatio;

    SpriteComponent comicBackground = SpriteComponent()
      ..sprite = panningBackground
      ..size = Vector2(screenWidth, comicScaledHeight)
      ..position =
          Vector2(0, 0) // Start at the very top
      ..anchor = Anchor.topLeft;

    // 2. Add the Panning Effect
    // We move the background UP (negative Y) to reveal the bottom
    double comicDistanceToPan =
        comicScaledHeight - screenHeight; // Total height minus screen height

    // WALKING ============================================
    Sprite hallwaySprite = await game.loadSprite(
      'earthquake/backgrounds/hallway.png',
    );
    Sprite walkingSprite = await game.loadSprite(
      'earthquake/characters/walking.png',
    );
    // hallway background setup
    Vector2 hallwaySize = hallwaySprite.srcSize;
    SpriteComponent hallwayBackground = SpriteComponent()
      ..sprite = hallwaySprite
      ..size = Vector2(hallwaySize.x, screenHeight)
      ..position = Vector2(0, 0)
      ..anchor = Anchor.topLeft
      ..opacity = 0.0; // Start invisible for fade-in effect

    double hallwayDistanceToPan =
        hallwaySize.x - screenWidth; // Total width minus screen width

    // walking character setup
    Vector2 walkingCharacterSize = walkingSprite.srcSize;
    // Inside walking character setup section
    SpriteAnimationComponent walkingCharacter = SpriteAnimationComponent()
      ..animation = SpriteAnimation.fromFrameData(
        walkingSprite.image,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.15, // Time per frame
          textureSize: Vector2(
            walkingCharacterSize.x / 4,
            walkingCharacterSize.y,
          ), // Size of each frame in the sprite sheet
        ),
      )
      ..anchor = Anchor.center
      ..opacity = 0.0; // Start invisible for fade-in effect
    walkingCharacter
      ..size = walkingCharacter.size * 0.75
      ..position = Vector2(
        screenWidth / 2,
        walkingCharacter.size.y / 2 + (screenHeight - walkingCharacter.size.y),
      );

    // ALL ANIMATIONS CHRONOLOGY GO HERE
    add(comicBackground);
    comicBackground.add(
      MoveEffect.to(
        Vector2(0, -comicDistanceToPan),
        EffectController(duration: comicDuration, curve: Curves.linear),
      ),
    );

    // Future.delayed(Duration(seconds: 0), () {
    Future.delayed(Duration(seconds: 0), () {
      //fade in hallway and character
      add(hallwayBackground);
      add(walkingCharacter);

      // fade in after comic finishes
      Future.delayed(Duration(seconds: comicDuration.toInt()), () {
        hallwayBackground.add(
          OpacityEffect.to(
            1.0,
            EffectController(duration: 1.0, curve: Curves.linear),
          ),
        );
        walkingCharacter.add(
          OpacityEffect.to(
            1.0,
            EffectController(duration: 1.0, curve: Curves.linear),
          ),
        );
      });

      walkingCharacter.debugMode = true;
      hallwayBackground.add(
        MoveEffect.to(
          Vector2(-hallwayDistanceToPan, 0),
          EffectController(duration: hallwayDuration, curve: Curves.linear),
        ),
      );
      Future.delayed(Duration(seconds: hallwayDuration.toInt()), () {
        walkingCharacter.add(
          MoveEffect.to(
            Vector2(
              walkingCharacter.position.x + 300,
              walkingCharacter.position.y,
            ),
            EffectController(duration: 1.0, curve: Curves.linear),
          ),
        );
      });
    });

    return super.onLoad();
  }
}
