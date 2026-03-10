import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:safesteps/earthquake.dart';
import 'package:safesteps/ssgame.dart';

class Player extends SpriteComponent
    with HasGameReference<Earthquake>, KeyboardHandler {
  // We set the size of the player (e.g., 64x64 pixels)
  late Sprite normal;
  late Sprite hurt;
  // Swapped the numbers: 256 is Width, 341 is Height
  Player()
    : super(
        size: Vector2(274, 365), // Try 128x170 for a better fit
        anchor: Anchor.center,
      );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    normal = await game.loadSprite('assets/characters/Normal.png');
    hurt = await game.loadSprite('assets/characters/Injured.png');

    sprite = normal; // Start with the normal sprite
    position = Vector2(128, 270);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Swap character when the Spacebar is pressed down
    if (event is KeyDownEvent &&
        keysPressed.contains(LogicalKeyboardKey.space)) {
      if (sprite == normal) {
        sprite = hurt;
      } else {
        sprite = normal;
      }
    }
    return super.onKeyEvent(event, keysPressed);
  }
}
