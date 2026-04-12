import 'dart:async';

import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:safesteps/earthquake.dart';
import 'package:safesteps/level_selection.dart';
import 'package:safesteps/levels/earthquake/earthquake_during_cutscene.dart';
import 'package:safesteps/levels/earthquake/earthquake_intro_cutscene.dart';
import 'package:safesteps/levels/earthquake/earthquake_lv1_puzzle.dart';
import 'package:safesteps/levels/earthquake/earthquake_lvl1.dart';
import 'package:safesteps/levelselect.dart';
import 'package:safesteps/main_menu.dart';
import 'package:safesteps/menu.dart';

class SafetyStepsGame extends FlameGame {
  late final CameraComponent cam;
  late final RouterComponent router;

  bool skipIntroCutsceneEarthquake = false;
  bool tutorialModeEarthquake = true;

  @override
  FutureOr<void> onLoad() async {
    // cam = CameraComponent.withFixedResolution(width: 1280, height: 720)
    //   ..viewfinder.anchor = Anchor.topLeft;
    cam = CameraComponent(viewport: MaxViewport())
      ..viewfinder.anchor = Anchor.topLeft;

    router = RouterComponent(
      initialRoute: 'main_menu',
      routes: {
        'main_menu': Route(MainMenu.new),
        'level_select': Route(LevelSelection.new),
        'earthquake_intro_cutscene': Route(
          EarthquakeIntroCutscene.new,
          maintainState: false,
        ),
        'earthquake_level_1': Route(EarthquakeLvl1.new, maintainState: false),
        'earthquake_level_1_puzzle': Route(
          EarthquakeLvl1Puzzle.new,
          maintainState: false,
        ),
        'earthquake_during_cutscene': Route(
          EarthquakeDuringCutscene.new,
          maintainState: false,
        ),
        'earthquake_level_1_puzzle_check': OverlayRoute(
          (context, game) =>
              checkButtonOverlayBuilder(context, game as SafetyStepsGame),
        ),
        'earthquake_level_1_puzzle_result': OverlayRoute(
          (context, game) =>
              resultOverlayBuilder(context, game as SafetyStepsGame),
        ),
      },
    );

    addAll([cam, router]);
    return super.onLoad();
  }

  void setWorld(World world) {
    cam.world = world;
  }
}
