import 'dart:async';

import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:safesteps/earthquake.dart';
import 'package:safesteps/level_selection.dart';
import 'package:safesteps/levels/earthquake/earthquake_lvl.dart';
import 'package:safesteps/levelselect.dart';
import 'package:safesteps/main_menu.dart';
import 'package:safesteps/menu.dart';

class SafetyStepsGame extends FlameGame {
  late final CameraComponent cam;
  late final RouterComponent router;

  @override
  FutureOr<void> onLoad() async {
    cam = CameraComponent.withFixedResolution(width: 1280, height: 720)
      ..viewfinder.anchor = Anchor.topLeft;
    cam = CameraComponent(viewport: MaxViewport())
      ..viewfinder.anchor = Anchor.topLeft;

    router = RouterComponent(
      initialRoute: 'main_menu',
      routes: {
        'main_menu': Route(MainMenu.new),
        'level_select': Route(LevelSelection.new),
        'earthquake_level': Route(EarthquakeLvl.new),
      },
    );

    addAll([cam, router]);
    return super.onLoad();
  }

  void setWorld(World world) {
    cam.world = world;
  }
}
