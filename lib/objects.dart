import 'package:flame/components.dart';
import 'package:safesteps/ssgame.dart';

class GameItem extends SpriteComponent with HasGameReference<SSGame> {
  final String imageName;

  // FIX: Only use the filename here, not the full path
  GameItem.clock({required Vector2 position})
    : imageName = 'Clock.png',
      super(position: position, size: Vector2(83, 75), anchor: Anchor.center);

  GameItem.table({required Vector2 position})
    : imageName = 'Table.png',
      super(position: position, size: Vector2(225, 180), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // This line combines the folder path + the filename
    sprite = await game.loadSprite('assets/earthquake/Objects/$imageName');
  }
}
