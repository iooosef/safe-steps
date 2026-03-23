import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/levels/level.dart';
import 'package:safesteps/ssgame.dart';
import 'package:safesteps/dragbutton.dart';

class Earthquake extends Component with HasGameReference<SSGame> {
  @override
  Color backgroundColor() => const Color.fromARGB(255, 0, 0, 0);

  late Level currentLevel;
  late final CameraComponent cam;

  @override
  FutureOr<void> onLoad() async {
    // FIX: Tells Flame not to look for the "assets/images" folder automatically
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
