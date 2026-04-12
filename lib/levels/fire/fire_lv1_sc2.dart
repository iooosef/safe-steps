import 'dart:async';

import 'package:flame/components.dart' hide Timer;
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/components/hintlabel.dart';
import 'package:safesteps/components/speech_bubble.dart';
import 'package:safesteps/levels/characters_enum.dart';
import 'package:safesteps/levels/fire/fire_lv1_sc1.dart';
import 'package:safesteps/safetysteps_game.dart';

class FireLevel1Scene2 extends World
    with HasGameReference<SafetyStepsGame>, TapCallbacks {
  final VoidCallback? onComplete;
  FireLevel1Scene2({this.onComplete});

  late double screenHeight;
  late double screenWidth;

  DateTime? _lastTapTime;
  static const Duration _tapCooldown = Duration(milliseconds: 400);

  final Map<(CharactersEnum, String), String> characters = {
    (CharactersEnum.teacher, "explaning"):
        "earthquake/characters/TeacherExplaining.png",
    (CharactersEnum.teacher, "done_explaining"):
        "earthquake/characters/TeacherDoneExplaining.png",
    (CharactersEnum.alex, "normal"): "fire/FAlexNormal.png",
    (CharactersEnum.alex, "confused"): "fire/FAlexConfused_2.png",
    (CharactersEnum.alex, "ohno1"): "fire/MCOhNo1.png",
    (CharactersEnum.alex, "ohno2"): "fire/MCOhNo2.png",
  };
  final List<Map<(CharactersEnum, String), String>> levelFlow = [
    {(CharactersEnum.alex, "confused"): "Whoah! It's so loud."},
    {
      (CharactersEnum.teacher, "explaning"):
          "It may sound scary but don't panic.",
    },
    {
      (CharactersEnum.teacher, "explaning"):
          "We just need to carefully think what to do next.",
    },
    {(CharactersEnum.controller, ""): "quiz_1"},
  ];
  final List<(String, bool)> quizFlow = [
    ('fire/TBPanic.png', false),
    ('fire/TBBag.png', false),
    ('fire/TBTalk.png', false),
    ('fire/Wait1.png', false),
    ('fire/TBGoOut.png', true),
  ];

  int quizHitPoints = 3;
  Sprite? _bgSprite;
  SpriteAnimationComponent? _bg;
  SpriteComponent? _alarm;
  SpriteComponent? _teacher;
  SpriteComponent? _alex;
  SpeechBubble? _speechBubble;
  late HintLabel _tapHint;
  Completer<void>? _tapCompleter;
  Completer<bool>? _quizAnswerCompleter;

  @override
  Future<void> onLoad() async {
    debugPrint('Loading Fire Level 1 Scene 2...');
    game.setWorld(this);
    screenHeight = game.size.y;
    screenWidth = game.size.x;
    await initObjects();
  }

  @override
  void onMount() {
    super.onMount();
    hintToContinue();
    play();
  }

  Future<void> initObjects() async {
    _bgSprite = await game.loadSprite('fire/FireClass1_FireClass2_joined.jpg');
    final frameWidth = _bgSprite!.image.width / 2;
    final frameHeight = _bgSprite!.image.height.toDouble();
    final frameAspectRatio = frameHeight / frameWidth;
    _bg = SpriteAnimationComponent()
      ..animation = SpriteAnimation.fromFrameData(
        _bgSprite!.image,
        SpriteAnimationData.sequenced(
          amount: 2,
          stepTime: 0.15,
          textureSize: Vector2(frameWidth, frameHeight),
        ),
      )
      ..size = Vector2(screenWidth, screenWidth * frameAspectRatio)
      ..position = Vector2(0, 0)
      ..anchor = Anchor.topLeft;

    // ── alarm ─────────────────────────────────────────
    _alarm = AlarmSprite(await game.loadSprite('fire/AlarmButton.png'));
    _alarm!
      ..size = _alarm!.size * 0.16
      ..position = Vector2(screenWidth * 0.75, screenHeight * 0.30)
      ..anchor = Anchor.center;
    _alarm!.add(
      SequenceEffect([
        RotateEffect.by(0.07, LinearEffectController(0.02)),
        RotateEffect.by(-0.14, LinearEffectController(0.04)),
        RotateEffect.by(0.07, LinearEffectController(0.02)),
      ], infinite: true),
    );

    // ── teacher ─────────────────────────────────────────
    _teacher = SpriteComponent()
      ..sprite = await game.loadSprite(
        characters[(CharactersEnum.teacher, "explaning")]!,
      )
      ..position = Vector2(0, screenHeight)
      ..anchor = Anchor.bottomLeft;
    _teacher?.size = Vector2(
      screenHeight * (_teacher!.size.x / _teacher!.size.y),
      screenHeight,
    );

    // ── Alex ─────────────────────────────────────────
    _alex = SpriteComponent()
      ..sprite = await game.loadSprite(
        characters[(CharactersEnum.alex, "normal")]!,
      )
      ..anchor = Anchor.bottomRight
      ..position = Vector2(screenWidth * .95, screenHeight * 1.2);
    _alex!.size = Vector2(
      screenHeight * (_alex!.size.x / _alex!.size.y) * 0.9,
      screenHeight * 0.9,
    );

    // ── speech bubble ─────────────────────────────────────────
    _speechBubble = SpeechBubble(
      text: '',
      tail: BubbleTail.left,
      tailDirection: BubbleTailDirection.left,
      padding: 16,
      radius: 24,
      tailSize: 30,
      maxBubbleWidth: screenWidth * 0.3,
    );
  }

  Future<void> play() async {
    add(_bg!);
    add(_alarm!);

    for (final dialog in levelFlow) {
      final characterKey = dialog.keys.first;
      final dialogText = dialog.values.first;

      bool skipOuterWait = false;

      // ── Show current dialog ────────────────────────────────────
      switch (characterKey.$1) {
        case CharactersEnum.teacher:
          _teacher!.sprite = await game.loadSprite(characters[characterKey]!);
          if (!_teacher!.isMounted) {
            add(_teacher!);
          }
          await SpeechBubble.addTo(
            this,
            dialog,
            characterKey,
            _speechBubble!,
            _tapHint,
          );
          _speechBubble
            ?..tail = BubbleTail.left
            ..tailDirection = BubbleTailDirection.left
            ..anchor = Anchor.topLeft
            ..position = Vector2(
              _teacher!.size.x * (3 / 5),
              screenHeight * 0.12,
            );
          debugPrint('[Dialog] TEACHER: $dialogText');
        case CharactersEnum.student:
          break;
        case CharactersEnum.alex:
          _alex!.sprite = await game.loadSprite(characters[characterKey]!);
          if (!_alex!.isMounted) {
            add(_alex!);
          }
          await SpeechBubble.addTo(
            this,
            dialog,
            characterKey,
            _speechBubble!,
            _tapHint,
          );
          _speechBubble
            ?..tail = BubbleTail.right
            ..tailDirection = BubbleTailDirection.right
            ..anchor = Anchor.topRight
            ..position = Vector2(
              screenWidth - (_alex!.size.x * 0.85),
              screenHeight * 0.12,
            );
          debugPrint('[Dialog] ALEX: $dialogText');

        case CharactersEnum.controller:
          if (dialogText == "quiz_1") {
            quizHitPoints = 3;
            skipOuterWait = true; // quiz manages its own flow
            await _quizStart();
          } else {
            if (_speechBubble!.isMounted) {
              remove(_speechBubble!);
              await _speechBubble!.removed;
            }
            if (_tapHint.isMounted) remove(_tapHint);
          }
          debugPrint('[Dialog] CONTROLLER: $dialogText');
      }

      if (!skipOuterWait) {
        debugPrint('[Dialog] Waiting for tap...');
        await _waitForTap();
        debugPrint('[Dialog] Tap received! Advancing...');
      }
    }
  }

  Future<void> hintToContinue() async {
    _tapHint = HintLabel()..position = Vector2(16, 8);
  }

  @override
  void onTapDown(TapDownEvent event) {
    onScreenTap();
  }

  void onScreenTap() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) < _tapCooldown) {
      return;
    }
    _lastTapTime = now;

    if (_tapCompleter != null && !_tapCompleter!.isCompleted) {
      _tapCompleter!.complete();
    }
  }

  Future<void> _waitForTap() {
    _tapCompleter = Completer<void>();
    return _tapCompleter!.future;
  }

  Future<void> _quizStart() async {
    if (_speechBubble!.isMounted) {
      remove(_speechBubble!);
      await _speechBubble!.removed;
    }
    if (_tapHint.isMounted) remove(_tapHint);

    final btnSize = Vector2(screenWidth * 0.18, screenHeight * 0.1);

    for (final question in quizFlow) {
      final correctAnswer = question.$2;
      debugPrint('Quiz question: ${question.$1}, correct: $correctAnswer');

      // ── Question image ─────────────────────────────────────────
      final questionSprite = await game.loadSprite(question.$1);
      final questionImage = SpriteComponent()
        ..sprite = questionSprite
        ..size = questionSprite.srcSize * 0.5
        ..anchor = Anchor.topCenter
        ..position = Vector2(screenWidth / 2, screenHeight * 0.1);

      // ── Yes / No buttons ───────────────────────────────────────
      final yesButton = _QuizButton(
        label: 'Yes',
        color: const Color(0xFF4CAF50),
        onPressed: () => _answerQuiz(true),
        size: btnSize.clone(),
        anchor: Anchor.center,
        position: Vector2(
          screenWidth / 2 - btnSize.x * 0.75,
          screenHeight * 0.8,
        ),
      );

      final noButton = _QuizButton(
        label: 'No',
        color: const Color(0xFFE53935),
        onPressed: () => _answerQuiz(false),
        size: btnSize.clone(),
        anchor: Anchor.center,
        position: Vector2(
          screenWidth / 2 + btnSize.x * 0.75,
          screenHeight * 0.8,
        ),
      );

      addAll([questionImage, yesButton, noButton]);

      final userAnswer = await _waitForQuizAnswer();

      removeAll([questionImage, yesButton, noButton]);

      final isGoOut = question.$1 == 'fire/TBGoOut.png';
      if (userAnswer != correctAnswer) {
        // TBGoOut answered No → instant fail regardless of HP
        if (isGoOut) {
          await _showGameOver();
          return;
        }

        quizHitPoints--;
        debugPrint('Wrong! HP remaining: $quizHitPoints');
        if (quizHitPoints == 2) {
          _alex!.sprite = await game.loadSprite(
            characters[(CharactersEnum.alex, "ohno1")]!,
          );
        } else if (quizHitPoints == 1) {
          _alex!.sprite = await game.loadSprite(
            characters[(CharactersEnum.alex, "ohno2")]!,
          );
        }
        if (quizHitPoints <= 0) {
          await _showGameOver();
          return;
        }
      }
    }

    game.router.pushNamed('fire_level_1_scene_3');
  }

  void _answerQuiz(bool answer) {
    if (_quizAnswerCompleter != null && !_quizAnswerCompleter!.isCompleted) {
      _quizAnswerCompleter!.complete(answer);
    }
  }

  Future<bool> _waitForQuizAnswer() {
    _quizAnswerCompleter = Completer<bool>();
    return _quizAnswerCompleter!.future;
  }

  Future<void> _showGameOver() async {
    final retryCompleter = Completer<void>();

    final dim = RectangleComponent(
      size: Vector2(screenWidth, screenHeight),
      paint: Paint()..color = const Color(0xCC000000),
      position: Vector2.zero(),
    );

    final gameOverSprite = await game.loadSprite('GameOver.png');
    final gameOverImg = SpriteComponent()
      ..sprite = gameOverSprite
      ..size =
          gameOverSprite.srcSize *
          (screenWidth * 0.7 / gameOverSprite.srcSize.x)
      ..anchor = Anchor.center
      ..position = Vector2(screenWidth / 2, screenHeight * 0.38);

    final retryBtn = _QuizButton(
      label: 'Retry',
      color: const Color(0xFFE53935),
      onPressed: retryCompleter.complete,
      size: Vector2(screenWidth * 0.22, screenHeight * 0.1),
      anchor: Anchor.center,
      position: Vector2(screenWidth / 2, screenHeight * 0.72),
    );

    addAll([dim, gameOverImg, retryBtn]);
    await retryCompleter.future;
    removeAll(children.toList());
    quizHitPoints = 3;
    await initObjects();
    hintToContinue();
    play();
  }
}

// ─── Quiz button ─────────────────────────────────────────────────────────────

class _QuizButton extends PositionComponent with TapCallbacks {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  _QuizButton({
    required this.label,
    required this.color,
    required this.onPressed,
    required Vector2 size,
    super.anchor,
    super.position,
  }) : super(size: size);

  @override
  void onTapDown(TapDownEvent event) {
    onPressed();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(12)),
      Paint()..color = color,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Comic Relief',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));
  }
}
