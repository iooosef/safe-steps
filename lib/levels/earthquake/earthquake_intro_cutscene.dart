import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';

class EarthquakeIntroCutscene {
  final FlameGame game;
  final double screenWidth;
  final double screenHeight;

  // Durations
  static const double _comicDuration = 2.0;
  static const double _hallwayDuration = 5.0;
  static const double _fadeInDuration = 1.0;
  static const double _walkToDoorDuration = 1.0;
  static const double _dialogFadeInDuration = 0.5;

  EarthquakeIntroCutscene({
    required this.game,
    required this.screenWidth,
    required this.screenHeight,
  });

  Future<void> play(World world, {VoidCallback? onComplete}) async {
    // ── Comic background ──────────────────────────────────────────
    final Sprite panningBackground = await game.loadSprite(
      'earthquake/comic/full_page_background.png',
    );

    const double comicAspectRatio = 1024 / 768;
    final double comicScaledHeight = screenWidth * comicAspectRatio;
    final double comicDistanceToPan = comicScaledHeight - screenHeight;

    final SpriteComponent comicBackground = SpriteComponent()
      ..sprite = panningBackground
      ..size = Vector2(screenWidth, comicScaledHeight)
      ..position = Vector2(0, 0)
      ..anchor = Anchor.topLeft;

    // ── Hallway background ────────────────────────────────────────
    final Sprite hallwaySprite = await game.loadSprite(
      'earthquake/backgrounds/hallway.png',
    );
    final Vector2 hallwaySize = hallwaySprite.srcSize;
    final double hallwayDistanceToPan = hallwaySize.x - screenWidth;

    final SpriteComponent hallwayBackground = SpriteComponent()
      ..sprite = hallwaySprite
      ..size = Vector2(hallwaySize.x, screenHeight)
      ..position = Vector2(0, 0)
      ..anchor = Anchor.topLeft
      ..opacity = 0.0;

    // ── Walking character ─────────────────────────────────────────
    final Sprite walkingSprite = await game.loadSprite(
      'earthquake/characters/walking.png',
    );
    final Vector2 walkingCharacterSize = walkingSprite.srcSize;

    final SpriteAnimationComponent walkingCharacter = SpriteAnimationComponent()
      ..animation = SpriteAnimation.fromFrameData(
        walkingSprite.image,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.15,
          textureSize: Vector2(
            walkingCharacterSize.x / 4,
            walkingCharacterSize.y,
          ),
        ),
      )
      ..anchor = Anchor.center
      ..opacity = 0.0;
    walkingCharacter
      ..size = walkingCharacter.size * 0.75
      ..position = Vector2(
        screenWidth / 2,
        walkingCharacter.size.y / 2 + (screenHeight - walkingCharacter.size.y),
      );

    // ── Dialog background ─────────────────────────────────────────
    final SpriteComponent tutorialDialogBackground = SpriteComponent()
      ..sprite = await game.loadSprite(
        'earthquake/backgrounds/normal_640x360.png',
      )
      ..position = Vector2(0, 0)
      ..anchor = Anchor.topLeft
      ..opacity = 0.0;

    final double dialogAspectRatio =
        tutorialDialogBackground.size.y / tutorialDialogBackground.size.x;
    tutorialDialogBackground.size = Vector2(
      screenWidth,
      screenWidth * dialogAspectRatio,
    );

    // ── Sequence ──────────────────────────────────────────────────

    // [01] Pan comic
    world.add(comicBackground);
    comicBackground.add(
      MoveEffect.to(
        Vector2(0, -comicDistanceToPan),
        EffectController(duration: _comicDuration, curve: Curves.linear),
      ),
    );

    // [02] Pre-load hallway and character (invisible)
    world.add(hallwayBackground);
    world.add(walkingCharacter);

    // [03] Pan hallway immediately
    hallwayBackground.add(
      MoveEffect.to(
        Vector2(-hallwayDistanceToPan, 0),
        EffectController(duration: _hallwayDuration, curve: Curves.linear),
      ),
    );

    // [04] Fade in hallway + character after comic
    Future.delayed(Duration(milliseconds: (_comicDuration * 1000).toInt()), () {
      hallwayBackground.add(
        OpacityEffect.to(
          1.0,
          EffectController(duration: _fadeInDuration, curve: Curves.linear),
        ),
      );
      walkingCharacter.add(
        OpacityEffect.to(
          1.0,
          EffectController(duration: _fadeInDuration, curve: Curves.linear),
        ),
      );

      // [05] Walk character to door
      Future.delayed(
        Duration(
          milliseconds: (_hallwayDuration * 1000 - _comicDuration * 1000)
              .toInt(),
        ),
        () {
          walkingCharacter.add(
            MoveEffect.to(
              Vector2(
                walkingCharacter.position.x + 300,
                walkingCharacter.position.y,
              ),
              EffectController(
                duration: _walkToDoorDuration,
                curve: Curves.linear,
              ),
            ),
          );

          // [06] Fade in dialog, then call onComplete
          Future.delayed(
            Duration(milliseconds: (_walkToDoorDuration * 1000).toInt()),
            () {
              world.add(tutorialDialogBackground);
              tutorialDialogBackground.add(
                OpacityEffect.to(
                  1.0,
                  EffectController(
                    duration: _dialogFadeInDuration,
                    curve: Curves.linear,
                  ),
                ),
              );

              Future.delayed(
                Duration(milliseconds: (_dialogFadeInDuration * 1000).toInt()),
                () => onComplete?.call(),
              );
            },
          );
        },
      );
    });
  }
}
