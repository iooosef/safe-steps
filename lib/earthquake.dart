import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:safesteps/levels/level.dart';
import 'package:safesteps/ssgame.dart';

class Earthquake extends Component with HasGameReference<SSGame> {
  late Level currentLevel;
  late final CameraComponent cam;

  @override
  FutureOr<void> onLoad() async {
    game.images.prefix = '';
    await game.images.loadAll([
      'assets/characters/Normal.png',
      'assets/characters/Injured.png',
      'assets/earthquake/Backgrounds/E1.jpg',
      'assets/earthquake/Backgrounds/E2.jpg',
      'assets/earthquake/Backgrounds/E3.jpg',
      'assets/earthquake/Backgrounds/ClassroomDestroyed_640x360.png',
      'assets/earthquake/Objects/Clock.png',
      'assets/earthquake/Objects/Table.png',
      'assets/earthquake/Buttons/CoverB(Unselected).png',
      'assets/earthquake/Buttons/CoverB(Selected).png',
      'assets/earthquake/Buttons/DuckB(Unselected).png',
      'assets/earthquake/Buttons/DropB(Selected).png',
      'assets/earthquake/Buttons/HoldB(Unselected).png',
      'assets/earthquake/Buttons/HoldB(Selected).png',
      'assets/earthquake/comics/sun1.png',
      'assets/earthquake/comics/sun2.png',
      'assets/earthquake/comics/sun3.png',
      'assets/earthquake/Backgrounds/Hallway.png',
      'assets/characters/walkingwithbag.1.png',
      'assets/characters/walkingwithbag.2.png',
      'assets/characters/walkingwithbag.3.png',
      'assets/characters/walkingwithbag.4.png',
    ]);

    currentLevel = Level();

    late final HallwayIntroWorld hallwayWorld;
    hallwayWorld = HallwayIntroWorld(onFinished: () {
      cam.world = currentLevel;
    });

    final sunWorld = SunIntroWorld(onFinished: () {
      cam.world = hallwayWorld;
    });

    cam = CameraComponent.withFixedResolution(
      world: sunWorld,
      width: 640,
      height: 360,
    );
    cam.viewfinder.anchor = Anchor.topLeft;

    await add(sunWorld);
    await add(hallwayWorld);
    await add(currentLevel);
    await add(cam);

    return super.onLoad();
  }
}

class SunIntroWorld extends World with HasGameReference<SSGame> {
  final void Function() onFinished;

  SunIntroWorld({required this.onFinished});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final sun1 = await game.loadSprite('assets/earthquake/comics/sun1.png');
    final sun2 = await game.loadSprite('assets/earthquake/comics/sun2.png');
    final sun3 = await game.loadSprite('assets/earthquake/comics/sun3.png');

    final sunSprite = SpriteComponent(
      sprite: sun1,
      size: Vector2(640, 360),
    );
    add(sunSprite);

    add(TimerComponent(
      period: 0.5,
      removeOnFinish: true,
      onTick: () => sunSprite.sprite = sun2,
    ));
    add(TimerComponent(
      period: 1.0,
      removeOnFinish: true,
      onTick: () => sunSprite.sprite = sun3,
    ));
    add(TimerComponent(
      period: 1.5,
      removeOnFinish: true,
      onTick: onFinished,
    ));
  }
}

class HallwayIntroWorld extends World with HasGameReference<SSGame> {
  final void Function() onFinished;

  HallwayIntroWorld({required this.onFinished});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Hallway is 2173x360; viewport is 640x360
    final hallwaySprite = await game.loadSprite(
      'assets/earthquake/Backgrounds/Hallway.png',
    );
    final hallway = SpriteComponent(
      sprite: hallwaySprite,
      size: Vector2(2173, 360),
      position: Vector2.zero(),
    );
    add(hallway);

    // Walking character animation (4 frames)
    final walk1 = await game.loadSprite('assets/characters/walkingwithbag.1.png');
    final walk2 = await game.loadSprite('assets/characters/walkingwithbag.2.png');
    final walk3 = await game.loadSprite('assets/characters/walkingwithbag.3.png');
    final walk4 = await game.loadSprite('assets/characters/walkingwithbag.4.png');

    final walkAnimation = SpriteAnimation.spriteList(
      [walk1, walk2, walk3, walk4],
      stepTime: 0.25,
    );

    // FIX 1: Position Y set to 360 (the bottom of your viewport) instead of 400.
    final character = SpriteAnimationComponent(
      animation: walkAnimation,
      size: Vector2(274, 365), // Note: This makes the character slightly taller than the screen!
      anchor: Anchor.bottomCenter,
      position: Vector2(320, 400), 
    );
    add(character);

    // Scroll the hallway to the left so the scene pans right
    const double scrollDistance = 2173 - 640;
    const double scrollDuration = 10.0;
    
    hallway.add(
      MoveEffect.by(
        Vector2(-scrollDistance, 0),
        EffectController(duration: scrollDuration, curve: Curves.linear),
      ),
    );

    // FIX 2: Removed the character's MoveEffect entirely. 
    // They will now walk in place while the world slides past them.

    // Transition to game after scroll completes
    add(TimerComponent(
      period: scrollDuration + 0.3,
      removeOnFinish: true,
      onTick: onFinished,
    ));
  }
}
