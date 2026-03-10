import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:mygame/objects.dart';
import 'package:mygame/earthquake.dart';
import 'package:mygame/actors/player.dart';

class Level extends World with HasGameReference<Earthquake> {
  double trauma = 0;
  final math.Random _random = math.Random();

  late final PositionComponent bgContainer;
  late final PositionComponent objectContainer;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    bgContainer = PositionComponent();
    objectContainer = PositionComponent();

    add(bgContainer);
    add(objectContainer);

    // --- 1. ANIMATED BACKGROUND LOGIC ---
    // Load your 3 frames (E1, E2, E3)
    final frame1 = await game.loadSprite(
      'assets/earthquake/Backgrounds/E1.jpg',
    );
    final frame2 = await game.loadSprite(
      'assets/earthquake/Backgrounds/E2.jpg',
    );
    final frame3 = await game.loadSprite(
      'assets/earthquake/Backgrounds/E3.jpg',
    );

    // Create the animation (set stepTime to how fast you want the frames to swap)
    final bgAnimation = SpriteAnimation.spriteList(
      [frame1, frame2, frame3],
      stepTime: 1, // 0.15 seconds per frame
    );

    // Use SpriteAnimationComponent instead of SpriteComponent
    bgContainer.add(
      SpriteAnimationComponent(animation: bgAnimation, size: Vector2(640, 360)),
    );
    // -------------------------------------

    objectContainer.add(GameItem.clock(position: Vector2(45, 45)));
    objectContainer.add(GameItem.table(position: Vector2(350, 245)));

    final player = Player();
    objectContainer.add(player);

    add(TimerComponent(period: 0.0, onTick: () => startEarthquake(0.5)));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (trauma > 0) {
      double baseShake = (trauma * trauma);

      bgContainer.position = Vector2(
        (_random.nextDouble() - 0.5) * (baseShake * 8.0),
        (_random.nextDouble() - 0.5) * (baseShake * 8.0),
      );

      objectContainer.position = Vector2(
        (_random.nextDouble() - 0.5) * (baseShake * 25.0),
        (_random.nextDouble() - 0.5) * (baseShake * 25.0),
      );
    } else {
      bgContainer.position = Vector2.zero();
      objectContainer.position = Vector2.zero();
    }
  }

  void startEarthquake(double intensity) => trauma = intensity;
  void stopEarthquake() => trauma = 0;
}
