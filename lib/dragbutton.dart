import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:safesteps/ssgame.dart';

class DraggableButton extends SpriteComponent
    with DragCallbacks, HasGameReference<SSGame> {
  final String imagePath;
  final String selectedImagePath;
  final String buttonType;
  final Vector2 snapTarget;
  final double snapThreshold;
  final void Function(String buttonType)? onSnapped;

  bool isDragging = false;
  bool isSnapped = false;

  DraggableButton({
    required this.imagePath,
    required this.selectedImagePath,
    required this.buttonType,
    required this.snapTarget,
    this.snapThreshold = 50.0,
    this.onSnapped,
    required Vector2 position,
    Vector2? size,
  }) : super(
         position: position,
         size: size ?? Vector2(80, 80),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    sprite = await game.loadSprite(imagePath);
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (isSnapped) return;
    super.onDragStart(event);
    isDragging = true;
    add(ScaleEffect.to(Vector2.all(1.1), EffectController(duration: 0.1)));
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (isSnapped) return;
    position += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (isSnapped) return;
    super.onDragEnd(event);
    isDragging = false;

    if (position.distanceTo(snapTarget) < snapThreshold) {
      _snapToTarget();
    }

    add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.1)));
  }

  Future<void> _snapToTarget() async {
    isSnapped = true;
    position = snapTarget.clone();
    sprite = await game.loadSprite(selectedImagePath);
    add(ScaleEffect.to(
      Vector2.all(1.2),
      EffectController(duration: 0.1, reverseDuration: 0.1),
    ));
    onSnapped?.call(buttonType);
  }
}
