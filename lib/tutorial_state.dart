enum TutorialPhase { narrative, puzzle, success, gameOver }

enum NarrativeScene { scene1, transitionToDark, scene2 }

abstract class TutorialController {
  TutorialState get state;
  void onDialogueTap();
  void onMistakeDismiss();
  void onSuccessTap();
  void onGameOverRetry();
}

class DialogueLine {
  final String speaker;
  final String text;
  final bool isMonologue;
  final List<(int, int)> highlights;

  const DialogueLine({
    required this.speaker,
    required this.text,
    this.isMonologue = false,
    this.highlights = const [],
  });
}

class TutorialState {
  TutorialPhase phase = TutorialPhase.narrative;
  NarrativeScene narrativeScene = NarrativeScene.scene1;
  int dialogueIndex = 0;

  // "Drop, Cover, and Hold!" starts at index 41 and the string is 63 chars.
  static const String _teacherLine3 =
      'Yes! If an earthquake happens, remember: Drop, Cover, and Hold!';

  static const List<DialogueLine> scene1Lines = [
    DialogueLine(
      speaker: 'Teacher',
      text:
          'Okay class! Today we will learn what to do if the ground starts shaking!',
    ),
    DialogueLine(speaker: 'Classmate', text: 'Like an earthquake?'),
    DialogueLine(
      speaker: 'Teacher',
      text: _teacherLine3,
      highlights: [(41, 63)],
    ),
    DialogueLine(
      speaker: 'You',
      text: 'Hmm… I should remember that.',
      isMonologue: true,
    ),
  ];

  static const List<DialogueLine> scene2Lines = [
    DialogueLine(
      speaker: 'Teacher',
      text: 'Now, does anyone want to demonstrate? How about you try it?',
    ),
  ];

  List<DialogueLine> get currentLines {
    switch (narrativeScene) {
      case NarrativeScene.scene1:
        return scene1Lines;
      case NarrativeScene.scene2:
        return scene2Lines;
      default:
        return [];
    }
  }

  DialogueLine? get currentLine {
    final lines = currentLines;
    if (dialogueIndex < lines.length) return lines[dialogueIndex];
    return null;
  }

  bool advanceDialogue() {
    dialogueIndex++;
    if (dialogueIndex >= currentLines.length) {
      dialogueIndex = 0;
      if (narrativeScene == NarrativeScene.scene1) {
        narrativeScene = NarrativeScene.transitionToDark;
        return true;
      } else if (narrativeScene == NarrativeScene.scene2) {
        phase = TutorialPhase.puzzle;
        return true;
      }
    }
    return false;
  }

  void onTransitionComplete() {
    narrativeScene = NarrativeScene.scene2;
    dialogueIndex = 0;
  }

  static const List<String> correctOrder = ['duck', 'cover', 'hold'];

  int mistakes = 0;
  bool showHint = false;
  String playerSpriteKey = 'normal';

  bool checkAnswer(List<String> playerOrder) {
    for (int i = 0; i < correctOrder.length; i++) {
      if (i >= playerOrder.length || playerOrder[i] != correctOrder[i]) {
        _onMistake();
        return false;
      }
    }
    phase = TutorialPhase.success;
    return true;
  }

  void _onMistake() {
    mistakes++;
    if (mistakes >= 3) {
      phase = TutorialPhase.gameOver;
      return;
    }
    if (mistakes == 1) {
      playerSpriteKey = 'injured';
    } else {
      playerSpriteKey = 'bandage';
      showHint = true;
    }
  }

  void reset() {
    phase = TutorialPhase.narrative;
    narrativeScene = NarrativeScene.scene1;
    dialogueIndex = 0;
    mistakes = 0;
    showHint = false;
    playerSpriteKey = 'normal';
  }

  String get mistakeTeacherLine => 'Mistake, try again.';

  String get mistakePlayerLine {
    if (mistakes == 1) return 'Ouch!';
    return 'Uh oh...';
  }

  String get successLine => 'Great job! You remembered the safety steps!';
}
