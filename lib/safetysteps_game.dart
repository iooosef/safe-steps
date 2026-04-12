import 'dart:async';

import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:safesteps/level_selection.dart';
import 'package:safesteps/levels/earthquake/earthquake_during_cutscene.dart';
import 'package:safesteps/levels/earthquake/earthquake_intro_cutscene.dart';
import 'package:safesteps/levels/earthquake/earthquake_lv1_puzzle.dart';
import 'package:safesteps/levels/earthquake/earthquake_lvl2_puzzle.dart';
import 'package:safesteps/levels/earthquake/earthquake_lvl3_puzzle.dart';
import 'package:safesteps/levels/earthquake/earthquake_lvl1.dart';
import 'package:safesteps/levels/fire/fire_lv1_sc1.dart';
import 'package:safesteps/levels/fire/fire_lv1_sc2.dart';
import 'package:safesteps/levels/fire/fire_lv1_sc3.dart';
import 'package:safesteps/levels/fire/fire_lvl1.dart';
import 'package:safesteps/main_menu.dart';

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
      // initialRoute: 'main_menu',
      initialRoute: 'main_menu',
      routes: {
        'main_menu': Route(MainMenu.new),
        'level_select': Route(LevelSelection.new, maintainState: false),
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
        'earthquake_level_2_puzzle': Route(
          EarthquakeLvl2Puzzle.new,
          maintainState: false,
        ),
        'earthquake_level_2_choice': OverlayRoute(
          (context, game) =>
              choiceLvl2OverlayBuilder(context, game as SafetyStepsGame),
        ),
        'earthquake_level_2_wrong_feedback': OverlayRoute(
          (context, game) =>
              wrongFeedbackLvl2OverlayBuilder(context, game as SafetyStepsGame),
        ),
        'earthquake_level_2_correct_feedback': OverlayRoute(
          (context, game) => correctFeedbackLvl2OverlayBuilder(
            context,
            game as SafetyStepsGame,
          ),
        ),
        'earthquake_level_3_puzzle': Route(
          EarthquakeLvl3Puzzle.new,
          maintainState: false,
        ),
        'earthquake_level_3_instructions': OverlayRoute(
          (context, game) =>
              instructionsLvl3OverlayBuilder(context, game as SafetyStepsGame),
        ),
        'earthquake_level_3_hud': OverlayRoute(
          (context, game) =>
              hudLvl3OverlayBuilder(context, game as SafetyStepsGame),
        ),
        'earthquake_level_3_game_over': OverlayRoute(
          (context, game) =>
              gameOverLvl3OverlayBuilder(context, game as SafetyStepsGame),
        ),
        'earthquake_level_3_victory': OverlayRoute(
          (context, game) =>
              victoryLvl3OverlayBuilder(context, game as SafetyStepsGame),
        ),
        'earthquake_level_1_puzzle_check': OverlayRoute(
          (context, game) =>
              checkButtonOverlayBuilder(context, game as SafetyStepsGame),
        ),
        'earthquake_level_1_puzzle_result': OverlayRoute(
          (context, game) =>
              resultOverlayBuilder(context, game as SafetyStepsGame),
        ),
        'fire_level_1': Route(FireLevel1.new, maintainState: false),
        'fire_level_1_scene_1': Route(
          FireLevel1Scene1.new,
          maintainState: false,
        ),
        'fire_level_1_scene_2': Route(
          FireLevel1Scene2.new,
          maintainState: false,
        ),
        'fire_level_1_scene_3': Route(
          FireLevel1Scene3.new,
          maintainState: false,
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
