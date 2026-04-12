import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:safesteps/safetysteps_game.dart';

class EarthquakeIntroCutscene extends World
    with HasGameReference<SafetyStepsGame> {
  final VoidCallback? onComplete;

  EarthquakeIntroCutscene({this.onComplete});

  // Durations
  static const double _comicDuration = 2.0;
  static const double _hallwayDuration = 5.0;
  static const double _fadeInDuration = 1.0;
  static const double _walkToDoorDuration = 1.0;
  static const double _dialogFadeInDuration = 0.5;
  double _screenWidth = 0.0;
  double _screenHeight = 0.0;

  Sprite? _comicBackgroundSprite;
  SpriteComponent? _comicBackground;
  double? _comicDistanceToPan;
  Sprite? _hallwayBackgroundSprite;
  SpriteComponent? _hallwayBackground;
  double? _hallwayDistanceToPan;
  Sprite? _walkingCharacterSprite;
  SpriteAnimationComponent? _walkingCharacter;
  SpriteComponent? _tutorialDialogBackground;

  @override
  Future<void> onLoad() async {
    debugPrint('Loading Earthquake Intro Cutscene');
    game.setWorld(this);
    await initObjects();
    await play(this);
  }

  double getTotalDuration() {
    return _comicDuration +
        _hallwayDuration -
        _comicDuration +
        _walkToDoorDuration +
        _dialogFadeInDuration;
  }

  Future<void> initObjects() async {
    _screenWidth = game.size.x;
    _screenHeight = game.size.y;
    // ── Comic background ──────────────────────────────────────────
    _comicBackgroundSprite = await game.loadSprite(
      'earthquake/comic/full_page_background.png',
    );
    final double comicAspectRatio =
        _comicBackgroundSprite!.srcSize.y / _comicBackgroundSprite!.srcSize.x;
    final double comicScaledHeight = _screenWidth * comicAspectRatio;
    _comicDistanceToPan = comicScaledHeight - _screenHeight;
    _comicBackground = SpriteComponent()
      ..sprite = _comicBackgroundSprite
      ..size = Vector2(_screenWidth, comicScaledHeight)
      ..position = Vector2(0, 0)
      ..anchor = Anchor.topLeft;

    // ── Hallway background ────────────────────────────────────────
    _hallwayBackgroundSprite = await game.loadSprite(
      'earthquake/backgrounds/hallway.png',
    );
    _hallwayDistanceToPan = _hallwayBackgroundSprite!.srcSize.x - _screenWidth;
    _hallwayBackground = SpriteComponent()
      ..sprite = _hallwayBackgroundSprite
      ..size = Vector2(_hallwayBackgroundSprite!.srcSize.x, _screenHeight)
      ..position = Vector2(0, 0)
      ..anchor = Anchor.topLeft
      ..opacity = 0.0;

    // ── Walking character ─────────────────────────────────────────
    _walkingCharacterSprite = await game.loadSprite(
      'earthquake/characters/walking.png',
    );
    _walkingCharacter = SpriteAnimationComponent()
      ..animation = SpriteAnimation.fromFrameData(
        (await game.loadSprite('earthquake/characters/walking.png')).image,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.15,
          textureSize: Vector2(
            _walkingCharacterSprite!.srcSize.x / 4,
            _walkingCharacterSprite!.srcSize.y,
          ),
        ),
      )
      ..anchor = Anchor.bottomLeft
      ..opacity = 0.0;
    _walkingCharacter!
      ..size = _walkingCharacter!.size * 0.75
      ..position = Vector2(
        _screenWidth * 0.25,
        _screenHeight - 10,
        //  _walkingCharacter!.size.y / 2 +
        //      (_screenHeight - _walkingCharacter!.size.y),
      );

    // ── Dialog background ─────────────────────────────────────────
    _tutorialDialogBackground = SpriteComponent()
      ..sprite = await game.loadSprite(
        'earthquake/backgrounds/normal_640x360.png',
      )
      ..position = Vector2(0, 0)
      ..anchor = Anchor.topLeft
      ..opacity = 0.0;
    final double dialogAspectRatio =
        _tutorialDialogBackground!.size.y / _tutorialDialogBackground!.size.x;
    _tutorialDialogBackground!.size = Vector2(
      _screenWidth,
      _screenWidth * dialogAspectRatio,
    );
  }

  Future<void> play(World world) async {
    // ── Sequence ──────────────────────────────────────────────────

    // [01] Pan comic
    world.add(_comicBackground!);
    _comicBackground!.add(
      MoveEffect.to(
        Vector2(0, -_comicDistanceToPan!),
        EffectController(duration: _comicDuration, curve: Curves.linear),
      ),
    );

    // [02] Pre-load hallway and character (invisible)
    world.add(_hallwayBackground!);
    world.add(_walkingCharacter!);

    // [03] Pan hallway immediately
    _hallwayBackground!.add(
      MoveEffect.to(
        Vector2(-_hallwayDistanceToPan!, 0),
        EffectController(duration: _hallwayDuration, curve: Curves.linear),
      ),
    );

    // [04] Fade in hallway + character after comic
    Future.delayed(Duration(milliseconds: (_comicDuration * 1000).toInt()), () {
      _hallwayBackground!.add(
        OpacityEffect.to(
          1.0,
          EffectController(duration: _fadeInDuration, curve: Curves.linear),
        ),
      );
      _walkingCharacter!.add(
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
          _walkingCharacter!.add(
            MoveEffect.to(
              Vector2(
                _walkingCharacter!.position.x + 300,
                _walkingCharacter!.position.y,
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
              world.add(_tutorialDialogBackground!);
              _tutorialDialogBackground!.add(
                OpacityEffect.to(
                  1.0,
                  EffectController(
                    duration: _dialogFadeInDuration,
                    curve: Curves.linear,
                  ),
                ),
              );
            },
          );

          // end pop this route
          Future.delayed(
            Duration(
              milliseconds:
                  (_walkToDoorDuration * 1000 + _dialogFadeInDuration * 1000)
                      .toInt(),
            ),
            () {
              onComplete?.call();
            },
          );
        },
      );
    });
  }
}
