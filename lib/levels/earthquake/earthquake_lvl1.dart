import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:safesteps/components/speech_bubble.dart';
import 'package:safesteps/levels/characters_enum.dart';
import 'package:safesteps/levels/earthquake/earthquake_intro_cutscene.dart';
import 'package:safesteps/safetysteps_game.dart';

class EarthquakeLvl1 extends World
    with HasGameReference<SafetyStepsGame>, TapCallbacks {
  late double screenHeight;
  late double screenWidth;

  DateTime? _lastTapTime;
  static const Duration _tapCooldown = Duration(milliseconds: 400);

  late HintLabel _tapHint;

  final Map<(CharactersEnum, String), String> characters = {
    (CharactersEnum.teacher, "explaning"):
        "earthquake/characters/TeacherExplaining.png",
    (CharactersEnum.teacher, "done_explaining"):
        "earthquake/characters/TeacherDoneExplaining.png",
    (CharactersEnum.student, "normal"): "earthquake/characters/Normal.png",
    (CharactersEnum.student, "worried"): "earthquake/characters/Worried.png",
    (CharactersEnum.student, "bandage"): "earthquake/characters/Bandage.png",
    (CharactersEnum.student, "injured"): "earthquake/characters/Injured.png",
  };
  // [{(CharactersEnum, variant), dialog}, ...]
  final List<Map<(CharactersEnum, String), String>> levelFlow = [
    {
      (
        CharactersEnum.teacher,
        "explaning",
      ): "Hello class! We will be learning what to do if the ground starts shaking!",
    },
    {(CharactersEnum.student, "normal"): "Like an earthquake?"},
    {
      (CharactersEnum.teacher, "done_explaining"):
          "Yes! If an earthquake happens, remember: Duck, Cover, and Hold!",
    },
    {
      (CharactersEnum.student, "worried"):
          "Duck, Cover, and Hold. I'll remember that!",
    },
    {
      (CharactersEnum.teacher, "explaning"):
          "Now, let's try how to Duck, Cover, and Hold.",
    },
    {(CharactersEnum.controller, ""): "tutorial_earthquake_1"},
  ];

  @override
  Future<void> onLoad() async {
    debugPrint('Loading Earthquake Level 1 Tutorial...');
    game.setWorld(this);
    screenWidth = game.size.x;
    screenHeight = game.size.y;
    if (!game.skipIntroCutsceneEarthquake) {
      game.router.pushRoute(
        WorldRoute(
          () => EarthquakeIntroCutscene(
            onComplete: () {
              debugPrint(
                'Earthquake Intro Cutscene complete callback triggered.',
              );
              game.router.pop();
              _startTutorialDialog();
            },
          ),
          maintainState: false,
        ),
      );
    } else {
      game.skipIntroCutsceneEarthquake = false;
      _startTutorialDialog();
    }
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    onScreenTap();
  }

  Future<void> _startTutorialDialog() async {
    debugPrint('Starting Earthquake Level 1 Tutorial Dialog...');
    game.setWorld(this);
    // ── SETUP Sprites ─────────────────────────────────────────
    final SpriteComponent tutorialDialogBackground = SpriteComponent()
      ..sprite = await game.loadSprite(
        'earthquake/backgrounds/normal_640x360.png',
      )
      ..position = Vector2(0, 0)
      ..anchor = Anchor.topLeft;
    final double dialogAspectRatio =
        tutorialDialogBackground.size.y / tutorialDialogBackground.size.x;
    tutorialDialogBackground.size = Vector2(
      screenWidth,
      screenWidth * dialogAspectRatio,
    );
    add(tutorialDialogBackground);

    SpriteComponent teacherSprite = SpriteComponent()
      ..sprite = await game.loadSprite(
        'earthquake/characters/TeacherExplaining.png',
      )
      ..position = Vector2(0, screenHeight)
      ..anchor = Anchor.bottomLeft;
    teacherSprite.size = Vector2(
      screenHeight * (teacherSprite.size.x / teacherSprite.size.y),
      screenHeight,
    );
    SpriteComponent studentSprite = SpriteComponent()
      ..sprite = await game.loadSprite('earthquake/characters/Normal.png')
      ..anchor = Anchor.bottomRight;
    studentSprite
      ..position = Vector2(screenWidth, screenHeight * 1.25)
      ..size = Vector2(
        screenHeight * (studentSprite.size.x / studentSprite.size.y),
        screenHeight,
      );
    SpeechBubble speechBubble = SpeechBubble(
      text: '',
      tail: BubbleTail.left,
      tailDirection: BubbleTailDirection.left,
      padding: 16,
      radius: 24,
      tailSize: 30,
      maxBubbleWidth: screenWidth * 0.3,
    );
    await hintToContinue();

    for (final dialog in levelFlow) {
      final characterKey = dialog.keys.first;
      final dialogText = dialog.values.first;

      // speechBubble.debugMode = true;
      // ── Show current dialog ────────────────────────────────────
      if (characterKey.$1 == CharactersEnum.teacher) {
        teacherSprite.sprite = await game.loadSprite(characters[characterKey]!);
        if (!teacherSprite.isMounted) {
          add(teacherSprite);
        }
        await addSpeechBubble(dialog, characterKey, speechBubble);
        speechBubble
          ..tail = BubbleTail.left
          ..tailDirection = BubbleTailDirection.left
          ..anchor = Anchor.topLeft
          ..position = Vector2(
            teacherSprite.size.x * (3 / 5),
            screenHeight * 0.12,
          );
        debugPrint('[Dialog] TEACHER: $dialogText');
      } else if (characterKey.$1 == CharactersEnum.student) {
        studentSprite.sprite = await game.loadSprite(characters[characterKey]!);
        if (!studentSprite.isMounted) {
          add(studentSprite);
        }
        await addSpeechBubble(dialog, characterKey, speechBubble);
        speechBubble
          ..tail = BubbleTail.right
          ..tailDirection = BubbleTailDirection.right
          ..anchor = Anchor.topRight
          ..position = Vector2(
            screenWidth - (studentSprite.size.x * (3 / 4)),
            screenHeight * 0.12,
          );
        debugPrint('[Dialog] STUDENT: $dialogText');
      } else if (characterKey.$1 == CharactersEnum.controller) {
        // Handle controller logic
        if (speechBubble.isMounted) {
          remove(speechBubble);
          await speechBubble.removed;
        }
        if (_tapHint.isMounted) remove(_tapHint); // hide on controller

        if (dialogText == "tutorial_earthquake_1") {
          debugPrint('[Dialog] Starting tutorial level...');
          startTutorialGame(
            tutorialDialogBackground,
            teacherSprite,
            studentSprite,
          );
        }
        debugPrint('[Dialog] CONTROLLER: $dialogText');
      }

      // ── Wait for tap before moving to next dialog ──────────────
      debugPrint('[Dialog] Waiting for tap...');
      await _waitForTap();
      debugPrint('[Dialog] Tap received! Advancing...');
    }

    debugPrint('[Dialog] All dialogs complete.');
  }

  // Holds the current pending tap completer
  Completer<void>? _tapCompleter;

  Future<void> _waitForTap() {
    _tapCompleter = Completer<void>();
    return _tapCompleter!.future;
  }

  // Call this from your TapDetector / onTapDown override
  void onScreenTap() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) < _tapCooldown) {
      return; // Too soon — ignore the tap
    }
    _lastTapTime = now;

    if (_tapCompleter != null && !_tapCompleter!.isCompleted) {
      _tapCompleter!.complete();
    }
  }

  Future<void> addSpeechBubble(
    Map<(CharactersEnum, String), String> dialog,
    (CharactersEnum, String) characterKey,
    SpeechBubble speechBubble,
  ) async {
    if (characterKey.$1 == CharactersEnum.controller) {
      if (speechBubble.isMounted) {
        remove(speechBubble);
        await speechBubble.removed; // wait for full detach
      }
      return;
    }

    if (speechBubble.isMounted) {
      remove(speechBubble);
      await speechBubble.removed;
    }

    add(speechBubble);
    if (!_tapHint.isMounted) add(_tapHint);
    await speechBubble.loaded;
    speechBubble.updateText(dialog.values.first);
  }

  Future<void> hintToContinue() async {
    _tapHint = HintLabel()..position = Vector2(16, 8);
    // _tapHint.debugMode = true;
    // Do not add here — addSpeechBubble manages when to show the hint
  }

  void startTutorialGame(
    SpriteComponent tutorialDialogBackground,
    SpriteComponent teacherSprite,
    SpriteComponent studentSprite,
  ) {
    debugPrint('Starting Earthquake Level 1 Puzzle...');
    final RectangleComponent dim = RectangleComponent(
      size: tutorialDialogBackground.size,
      paint: Paint()..color = const Color(0x99000000), // 60% black
    );
    tutorialDialogBackground.add(dim);

    //remove teacher and student
    if (teacherSprite.isMounted) remove(teacherSprite);
    if (studentSprite.isMounted) remove(studentSprite);
    while (game.router.canPop()) {
      game.router.pop();
    }
    game.router.pushNamed('earthquake_level_1_puzzle');
  }
}

class HintLabel extends PositionComponent {
  static const double _padX = 12;
  static const double _padY = 6;
  static const _bgColor = Color(0xFFEEEEEE);
  static const _radius = Radius.circular(8);

  late final TextComponent _label;

  @override
  Future<void> onLoad() async {
    _label = TextComponent(
      text: 'Tap to continue ⏩',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF555555),
          fontSize: 16,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
          fontFamily: 'Comic Relief',
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(_padX, _padY),
    );
    await add(_label);

    // Size this component to wrap the text tightly
    size = _label.size + Vector2(_padX * 2, _padY * 2);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = _bgColor;
    canvas.drawRRect(RRect.fromRectAndRadius(size.toRect(), _radius), paint);
    super.render(canvas); // draws children (the TextComponent)
  }
}
