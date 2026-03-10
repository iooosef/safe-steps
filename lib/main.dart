import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mygame/safetysteps.dart';
import 'package:mygame/menu.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set the app to full screen and landscape mode
  Flame.device.fullScreen();
  Flame.device.setLandscape();

  final Menu menu = Menu();
  runApp(GameWidget(game: kDebugMode ? Menu() : menu));
}
