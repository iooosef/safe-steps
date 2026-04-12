import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/levels/earthquake/earthquake_lv1_puzzle.dart';
import 'package:safesteps/safetysteps_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set the app to full screen and landscape mode
  Flame.device.fullScreen();
  Flame.device.setLandscape();

  var game = SafetyStepsGame();
  runApp(GameWidget<SafetyStepsGame>(game: game));
}
