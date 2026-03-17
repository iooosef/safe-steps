import 'dart:async';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:safesteps/objects.dart';
import 'package:safesteps/actors/player.dart';
import 'package:safesteps/ssgame.dart';
import 'package:safesteps/dragbutton.dart';

class Level extends World with HasGameReference<SSGame> {
  double trauma = 0;
  final math.Random _random = math.Random();

  // We use these containers to separate the shaky "world" from the static "UI"
  late final PositionComponent bgContainer;
  late final PositionComponent objectContainer;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    bgContainer = PositionComponent();
    objectContainer = PositionComponent();

    // Adding these first so they are at the bottom of the stack
    add(bgContainer);
    add(objectContainer);

    // --- 1. ANIMATED BACKGROUND LOGIC ---
    final frame1 = await game.loadSprite('assets/earthquake/Backgrounds/E1.jpg');
    final frame2 = await game.loadSprite('assets/earthquake/Backgrounds/E2.jpg');
    final frame3 = await game.loadSprite('assets/earthquake/Backgrounds/E3.jpg');

    final bgAnimation = SpriteAnimation.spriteList(
      [frame1, frame2, frame3],
      stepTime: 1, 
    );
    
    bgContainer.add(
      SpriteAnimationComponent(
        animation: bgAnimation, 
        size: Vector2(640, 360),
      ),
    );

    // --- 2. GAME OBJECTS ---
    objectContainer.add(GameItem.clock(position: Vector2(45, 45)));
    objectContainer.add(GameItem.table(position: Vector2(350, 245)));

    final player = Player();
    objectContainer.add(player);

    // --- 3. DRAGGABLE IMAGE BUTTONS ---
    // We add these directly to the World (NOT the containers) 
    // so they don't shake during the earthquake.
    
    final clockDragBtn = DraggableButton(
      imagePath: 'assets/earthquake/Objects/Clock.png', // Using the same asset or a UI specific one
      position: Vector2(100, 300),
      size: Vector2(60, 60),
    );

    final tableDragBtn = DraggableButton(
      imagePath: 'assets/earthquake/Objects/Table.png',
      position: Vector2(200, 300),
      size: Vector2(100, 80),
    );

    add(clockDragBtn);
    add(tableDragBtn);

    // Start the shaking effect
    add(TimerComponent(period: 0.0, onTick: () => startEarthquake(0.5)));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (trauma > 0) {
      double baseShake = (trauma * trauma);

      // Background shakes less for depth effect
      bgContainer.position = Vector2(
        (_random.nextDouble() - 0.5) * (baseShake * 8.0),
        (_random.nextDouble() - 0.5) * (baseShake * 8.0),
      );

      // Objects (and player) shake more violently
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