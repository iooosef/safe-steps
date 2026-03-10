import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:mygame/levels/level.dart';
import 'package:mygame/levelselect.dart';
import 'package:mygame/menu.dart';
import 'package:flutter/material.dart' hide Route;

class SSGame extends FlameGame {
  late final RouterComponent router;

  @override
  Future<void> onLoad() async {
    router = RouterComponent(
      initialRoute: 'menu',
      routes: {'menu': Route(Menu.new), 'levels': Route(LevelSelect.new)},
    );

    add(router);
  }
}
