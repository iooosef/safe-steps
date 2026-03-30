import 'dart:async';

import 'package:flame/game.dart';
import 'package:safesteps/earthquake.dart';
import 'package:safesteps/levelselect.dart';
import 'package:safesteps/menu.dart';
import 'package:safesteps/tutorial_state.dart';

class SSGame extends FlameGame {
  late final RouterComponent router;
  TutorialController? activeTutorial;

  @override
  Future<void> onLoad() async {
    router = RouterComponent(
      initialRoute: 'menu',
      routes: {
        'menu': Route(Menu.new),
        'levels': Route(LevelSelect.new),
        'earthquake': Route(Earthquake.new),
      },
    );

    add(router);
  }
}
