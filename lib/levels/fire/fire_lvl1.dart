import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/levels/fire/fire_lv1_sc1.dart';
import 'package:safesteps/safetysteps_game.dart';

class FireLevel1 extends World with HasGameReference<SafetyStepsGame> {
  @override
  Future<void> onLoad() async {
    debugPrint('Loading Fire Level 1 Only!');
    game.router.pushRoute(
      WorldRoute(
        () => FireLevel1Scene1(
          onComplete: () {
            debugPrint('Fire Level 1 Completed!');
            Future.microtask(() {
              while (game.router.canPop()) {
                game.router.pop();
              }
              game.router.pushNamed('level_select');
            });
          },
        ),
      ),
    );
  }
}
