import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/ssgame.dart';
import 'package:safesteps/tutorial_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set the app to full screen and landscape mode
  Flame.device.fullScreen();
  Flame.device.setLandscape();

  final SSGame game = kDebugMode ? SSGame() : SSGame();
  runApp(
    GameWidget(
      game: game,
      overlayBuilderMap: _buildTutorialOverlays(game),
    ),
  );
}

Map<String, Widget Function(BuildContext, SSGame)> _buildTutorialOverlays(
    SSGame game) {
  return {
    'tutorialDialogue': (context, game) {
      final tutorial = game.activeTutorial;
      final line = tutorial?.state.currentLine;
      if (tutorial == null || line == null) {
        return const SizedBox.shrink();
      }
      return Stack(
        children: [
          DialogueOverlay(
            line: line,
            onTap: () => tutorial.onDialogueTap(),
          ),
        ],
      );
    },
    'tutorialMistake': (context, game) {
      final tutorial = game.activeTutorial;
      if (tutorial == null) return const SizedBox.shrink();
      return Stack(
        children: [
          MistakeFeedbackOverlay(
            teacherLine: tutorial.state.mistakeTeacherLine,
            playerLine: tutorial.state.mistakePlayerLine,
            onTap: () => tutorial.onMistakeDismiss(),
          ),
        ],
      );
    },
    'tutorialSuccess': (context, game) {
      final tutorial = game.activeTutorial;
      if (tutorial == null) return const SizedBox.shrink();
      return Stack(
        children: [
          SuccessOverlay(
            message: tutorial.state.successLine,
            onTap: () => tutorial.onSuccessTap(),
          ),
        ],
      );
    },
    'tutorialGameOver': (context, game) {
      final tutorial = game.activeTutorial;
      if (tutorial == null) return const SizedBox.shrink();
      return GameOverOverlay(
        onRetry: () => tutorial.onGameOverRetry(),
      );
    },
    'tutorialHint': (context, game) {
      return const Stack(
        children: [HintOverlay()],
      );
    },
  };
}
