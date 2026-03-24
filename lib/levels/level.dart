import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/objects.dart';
import 'package:safesteps/actors/player.dart';
import 'package:safesteps/ssgame.dart';
import 'package:safesteps/dragbutton.dart';

class Level extends World with HasGameReference<SSGame> {
  double trauma = 0;
  final math.Random _random = math.Random();
  int _snappedCount = 0;

  late final PositionComponent bgContainer;
  late final PositionComponent objectContainer;
  late final SpriteAnimationComponent background;
  late final Sprite destroyedBackground;
  late final GameItem clock;
  late final GameItem table;

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
    destroyedBackground = await game.loadSprite(
      'assets/earthquake/Backgrounds/ClassroomDestroyed_640x360.png',
    );

    // Create the animation (set stepTime to how fast you want the frames to swap)
    final bgAnimation = SpriteAnimation.spriteList(
      [frame1, frame2, frame3],
      stepTime: 1, // 1 second per frame
    );

    // Use SpriteAnimationComponent instead of SpriteComponent
    background = SpriteAnimationComponent(
      animation: bgAnimation,
      size: Vector2(640, 360),
    );
    bgContainer.add(background);
    // -------------------------------------

    clock = GameItem.clock(position: Vector2(45, 45));
    table = GameItem.table(position: Vector2(350, 245));

    objectContainer.add(clock);
    objectContainer.add(table);

    final player = Player();
    objectContainer.add(player);

    // --- 3. SNAP SLOT PLACEHOLDERS ---
    for (final slotPos in [Vector2(250, 180), Vector2(380, 180), Vector2(510, 180)]) {
      add(
        RectangleComponent(
          position: slotPos,
          size: Vector2(70, 70),
          anchor: Anchor.center,
          paint: Paint()
            ..color = Colors.white24
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        ),
      );
    }

    // --- 4. DRAGGABLE BUTTONS (puzzle: arrange in Drop, Cover, Hold order) ---
    // Correct slot positions (left to right): Drop=250, Cover=380, Hold=510
    // Buttons start shuffled in the WRONG order so the player must rearrange them.
    add(
      DraggableButton(
        buttonType: 'cover',
        imagePath: 'assets/earthquake/Buttons/CoverB(Unselected).png',
        selectedImagePath: 'assets/earthquake/Buttons/CoverB(Selected).png',
        snapTarget: Vector2(380, 180),
        position: Vector2(510, 180),
        size: Vector2(70, 70),
        onSnapped: _onButtonSnapped,
      ),
    );
    add(
      DraggableButton(
        buttonType: 'drop',
        imagePath: 'assets/earthquake/Buttons/DuckB(Unselected).png',
        selectedImagePath: 'assets/earthquake/Buttons/DropB(Selected).png',
        snapTarget: Vector2(250, 180),
        position: Vector2(380, 180),
        size: Vector2(70, 70),
        onSnapped: _onButtonSnapped,
      ),
    );
    add(
      DraggableButton(
        buttonType: 'hold',
        imagePath: 'assets/earthquake/Buttons/HoldB(Unselected).png',
        selectedImagePath: 'assets/earthquake/Buttons/HoldB(Selected).png',
        snapTarget: Vector2(510, 180),
        position: Vector2(250, 180),
        size: Vector2(70, 70),
        onSnapped: _onButtonSnapped,
      ),
    );

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

  void _onButtonSnapped(String buttonType) {
    _snappedCount++;
    if (_snappedCount >= 3) {
      background.animation = SpriteAnimation.spriteList([
        destroyedBackground,
      ], stepTime: 1);
      clock.removeFromParent();
      table.removeFromParent();
      stopEarthquake();
    }
  }
}
