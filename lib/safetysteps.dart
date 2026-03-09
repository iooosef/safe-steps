import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:mygame/levels/level.dart';

class Safetysteps extends FlameGame with HasKeyboardHandlerComponents{
  @override
  Color backgroundColor() => const Color.fromARGB(255, 0, 0, 0);
  
  late Level currentLevel;
  late final CameraComponent cam;

  @override
  FutureOr<void> onLoad() async {
    // FIX: Tells Flame not to look for the "assets/images" folder automatically
    images.prefix = ''; 
    await images.loadAll([
      'assets/characters/Normal.png',
      'assets/characters/Injured.png',
      'assets/earthquake/Backgrounds/E1.jpg', // Don't forget the background!
      'assets/earthquake/Objects/Clock.png',
      'assets/earthquake/Objects/Table.png',
    ]);
    currentLevel = Level();

    // Matching your new 640x360 image size
    cam = CameraComponent.withFixedResolution(
      world: currentLevel,
      width: 640,
      height: 360,
    );
    
    cam.viewfinder.anchor = Anchor.topLeft;

    await add(currentLevel);
    await add(cam);

    return super.onLoad();
  }
  


}