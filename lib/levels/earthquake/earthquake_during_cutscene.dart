import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:safesteps/components/speech_bubble.dart';
import 'package:safesteps/safetysteps_game.dart';

class EarthquakeDuringCutscene extends World
    with HasGameReference<SafetyStepsGame> {
  @override
  Future<void> onLoad() async {
    game.setWorld(this);
    final Sprite earthquakeBackground = await game.loadSprite(
      'earthquake/backgrounds/Eall_downscaled.png',
    );
    final Vector2 bgSize = earthquakeBackground.srcSize;
    final SpriteAnimationComponent earthquakingBackground =
        SpriteAnimationComponent()
          ..animation = SpriteAnimation.fromFrameData(
            earthquakeBackground.image,
            SpriteAnimationData.sequenced(
              amount: 3,
              stepTime: 1,
              textureSize: Vector2(bgSize.x / 3, bgSize.y),
            ),
          )
          ..anchor = Anchor.topLeft;

    earthquakingBackground.size = Vector2(
      game.size.x,
      game.size.x * (bgSize.y / (bgSize.x / 3)),
    );

    // ease in
    earthquakingBackground!.add(
      MoveEffect.by(
        Vector2(6, 3),
        InfiniteEffectController(ZigzagEffectController(period: 0.2)),
      ),
    );
    add(earthquakingBackground);

    // student
    final levelSize = game.size;
    SpriteComponent studentSprite = SpriteComponent()
      ..sprite = await game.loadSprite('earthquake/characters/Worried.png')
      ..anchor = Anchor.bottomLeft;
    studentSprite
      ..position = Vector2(0, levelSize.y * 1.25)
      ..size = Vector2(
        levelSize.y * (studentSprite.size.x / studentSprite.size.y),
        levelSize.y,
      );
    studentSprite!.add(
      MoveEffect.by(
        Vector2(-6, -3),
        InfiniteEffectController(ZigzagEffectController(period: 0.4)),
      ),
    );
    add(studentSprite);

    SpeechBubble speechBubble = SpeechBubble(
      text: 'Oh No!',
      tail: BubbleTail.left,
      tailDirection: BubbleTailDirection.right,
      padding: 16,
      radius: 24,
      tailSize: 30,
      maxBubbleWidth: game.size.x * 0.3,
    );
    speechBubble
      ..anchor = Anchor.topLeft
      ..position = Vector2(25, 25);
    add(speechBubble);
    Future.delayed(const Duration(seconds: 2), () {
      remove(speechBubble);
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      speechBubble.updateText('The ground is shaking!');
      add(speechBubble);
    });

    Future.delayed(const Duration(milliseconds: 3500), () {
      while (game.router.canPop()) {
        game.router.pop();
      }
      game.tutorialModeEarthquake = false;
      game.router.pushNamed('earthquake_level_1_puzzle');
    });

    return super.onLoad();
  }
}
