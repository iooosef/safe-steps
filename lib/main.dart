import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/earthquake.dart';
import 'package:safesteps/ssgame.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set the app to full screen and landscape mode
  Flame.device.fullScreen();
  Flame.device.setLandscape();

  final SSGame game = SSGame();
  runApp(GameWidget(game: kDebugMode ? SSGame() : game));
}
