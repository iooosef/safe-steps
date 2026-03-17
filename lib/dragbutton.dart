import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/ssgame.dart';

class DraggableButton extends SpriteComponent
    with DragCallbacks, TapCallbacks, HasGameReference<SSGame> {
  // 1. Specify the filename of your button asset
  final String imagePath;
  
  // Keep track if we are currently dragging
  bool isDragging = false;

  DraggableButton({
    required this.imagePath, // e.g., 'ui/button_drag.png'
    required Vector2 position,
    // Provide a default size if it's always the same, or let the constructor override it
    Vector2? size,
  }) : super(
         // 2. Set the position and set the anchor to center for easier dragging mathematics
         position: position,
         size: size ?? Vector2(200, 80), // Set default size here, or pass in constructor
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // 3. Load the sprite asset
    sprite = await game.loadSprite('assets/earthquake/Buttons/CoverB(Selected).png');
  }

  // NOTE: I removed the custom 'render' method.
  // SpriteComponent will automatically draw the loaded sprite at the 
  // current 'position', 'size', and respecting the 'anchor' we set.

  // --- DRAG LOGIC ---

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    isDragging = true;
    
    // Optional Feedback: Scale up slightly while dragging
    add(ScaleEffect.to(Vector2.all(1.05), EffectController(duration: 0.1)));
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // 4. This line updates the sprite's position based on movement
    position += event.localDelta; 
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    isDragging = false;
    
    // Optional Feedback: Return to normal size
    add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.1)));
  }

  // --- TAP LOGIC (Optional, if you still want it to act like a button) ---

  @override
  void onTapDown(TapDownEvent event) {
    if (!isDragging) {
      // Scale down slightly on press
      add(ScaleEffect.to(Vector2.all(0.95), EffectController(duration: 0.08)));
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!isDragging) {
      // Return to scale
      add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.08)));
      print('Draggable image button tapped!');
      // Execute tap action here
    }
  }
}