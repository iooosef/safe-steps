import 'dart:async';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:safesteps/Earthquake.dart';
import 'package:safesteps/levels/level.dart';
import 'package:safesteps/levelselect.dart';
import 'package:safesteps/menu.dart';
import 'package:flutter/material.dart' hide Route;

class SSGame extends FlameGame {
  late final RouterComponent router;

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
