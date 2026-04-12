import 'dart:async';

import 'package:flame/components.dart' hide Timer;
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/components/hintlabel.dart';
import 'package:safesteps/components/speech_bubble.dart';
import 'package:safesteps/levels/characters_enum.dart';
import 'package:safesteps/safetysteps_game.dart';

class FireLevel1Scene1 extends World
    with HasGameReference<SafetyStepsGame>, TapCallbacks {
  final VoidCallback? onComplete;
  FireLevel1Scene1({this.onComplete});

  late double screenHeight;
  late double screenWidth;

  DateTime? _lastTapTime;
  static const Duration _tapCooldown = Duration(milliseconds: 400);

  SpriteComponent? _bg;
  SpriteComponent? _teacher;
  SpriteComponent? _alex;
  SpriteComponent? _alarm;
  SpeechBubble? _speechBubble;
  late HintLabel _tapHint;
  Completer<void>? _tapCompleter;
  Completer<void>? _alarmTapCompleter;
  Timer? _teeterTimer;

  final Map<(CharactersEnum, String), String> characters = {
    (CharactersEnum.teacher, "explaning"):
        "earthquake/characters/TeacherExplaining.png",
    (CharactersEnum.teacher, "done_explaining"):
        "earthquake/characters/TeacherDoneExplaining.png",
    (CharactersEnum.student, "normal"): "earthquake/characters/Normal.png",
    (CharactersEnum.alex, "normal"): "fire/FAlexNormal.png",
    (CharactersEnum.alex, "confused"): "fire/FAlexConfused_2.png",
  };
  final List<Map<(CharactersEnum, String), String>> levelFlow = [
    {
      (
        CharactersEnum.teacher,
        "explaning",
      ): "Hello class! Today is a special day, we’re going to have a fire drill.",
    },
    {(CharactersEnum.alex, "confused"): "Fire drill? What’s that?"},
    {
      (CharactersEnum.teacher, "done_explaining"):
          "Fire Drill helps us know what to do when there is a fire.",
    },
    {
      (CharactersEnum.alex, "confused"):
          "Teacher. What's that new thing on the wall?",
    },
    {(CharactersEnum.controller, ""): "emphasize_alarm"},
    {(CharactersEnum.teacher, "explaning"): "That's a fire alarm."},
    {
      (CharactersEnum.teacher, "explaning"):
          "When you hear it ring, we must leave the building immediately.",
    },
    {
      (
        CharactersEnum.alex,
        "normal",
      ): "When you hear the alarm, remember: stay calm, don’t panic, and follow instructions.",
    },
    {
      (CharactersEnum.alex, "normal"):
          "Let's try it. Can you tap the fire alarm?",
    },
    {(CharactersEnum.controller, ""): "tap_alarm_tutorial"},
    {
      (CharactersEnum.alex, "normal"):
          "Let's try it. Can you tap the fire alarm?",
    },
  ];

  @override
  Future<void> onLoad() async {
    debugPrint('Loading Fire Level 1 Scene 1');
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
    // ── Background ─────────────────────────────────────────
    _bg = SpriteComponent()
      ..sprite = await game.loadSprite(
        'earthquake/backgrounds/normal_640x360.png',
      )
      ..position = Vector2(0, 0)
      ..anchor = Anchor.topLeft;
    final double dialogAspectRatio = _bg!.size.y / _bg!.size.x;
    _bg?.size = Vector2(screenWidth, screenWidth * dialogAspectRatio);
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
      ..position = Vector2(screenWidth * (0.75), screenHeight * 1.2);
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

    // ── alarm ─────────────────────────────────────────
    _alarm = SpriteComponent()
      ..sprite = await game.loadSprite('fire/AlarmButton.png')
      ..anchor = Anchor.center;
    _alarm!
      ..size = _alarm!.size * 0.16
      ..position = Vector2(screenWidth * 0.75, screenHeight * 0.32);
  }

  Future<void> play() async {
    add(_bg!);
    add(_alarm!);
    debugPrint('Background loaded and added to the world.');

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
              screenWidth - (_alex!.size.x * 1.5),
              screenHeight * 0.12,
            );
          debugPrint('[Dialog] ALEX: $dialogText');

        case CharactersEnum.controller:
          // Keep bubble and hint for steps that need them on screen
          if (dialogText != "emphasize_alarm" &&
              dialogText != "tap_alarm_tutorial") {
            if (_speechBubble!.isMounted) {
              remove(_speechBubble!);
              await _speechBubble!.removed;
            }
            if (_tapHint.isMounted) remove(_tapHint);
          }
          debugPrint('[Dialog] CONTROLLER: $dialogText');
          if (dialogText == "emphasize_alarm") {
            _emphasizeAlarm();
          }
          if (dialogText == "tap_alarm_tutorial") {
            await _tapAlarmTutorial();
            debugPrint('End of this level');
            onComplete?.call();
            return;
          }
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
    // Do not add here — addSpeechBubble manages when to show the hint
  }

  @override
  void onTapDown(TapDownEvent event) {
    final alarmHit =
        _alarm != null &&
        _alarm!.isMounted &&
        _alarm!.toRect().contains(event.localPosition.toOffset());

    if (alarmHit) debugPrint('[Tap] Fire alarm tapped!');

    if (_alarmTapCompleter != null && !_alarmTapCompleter!.isCompleted) {
      if (alarmHit) _alarmTapCompleter!.complete();
    } else {
      onScreenTap();
    }
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

  void _emphasizeAlarm() {
    // Grow and shrink back
    _alarm!.add(
      SizeEffect.to(
        _alarm!.size * 1.35,
        EffectController(duration: 0.25, reverseDuration: 0.25),
      ),
    );
    // Teeter left then right then back
    _alarm!.add(
      SequenceEffect([
        RotateEffect.by(0.18, LinearEffectController(0.1)),
        RotateEffect.by(-0.36, LinearEffectController(0.2)),
        RotateEffect.by(0.36, LinearEffectController(0.2)),
        RotateEffect.by(-0.18, LinearEffectController(0.1)),
      ]),
    );
    // White glow flash — repeats twice for a pulse
    _alarm!.add(
      ColorEffect(
        Colors.white,
        EffectController(duration: 0.2, reverseDuration: 0.2, repeatCount: 2),
        opacityTo: 0.75,
      ),
    );
  }

  Future<void> _tapAlarmTutorial() async {
    if (_tapHint.isMounted) remove(_tapHint);

    // Gentle breathing loop while waiting for the player to tap
    final breathingEffect = SizeEffect.to(
      _alarm!.size * 1.12,
      EffectController(duration: 0.9, reverseDuration: 0.9, infinite: true),
    );
    _alarm!.add(breathingEffect);

    // Periodic teeter hint every 3.5 s — nudges the player if idle
    _teeterTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      _alarm!.add(
        SequenceEffect([
          RotateEffect.by(0.15, LinearEffectController(0.09)),
          RotateEffect.by(-0.30, LinearEffectController(0.18)),
          RotateEffect.by(0.15, LinearEffectController(0.09)),
        ]),
      );
    });

    debugPrint('[Dialog] Waiting for player to tap the alarm...');
    _alarmTapCompleter = Completer<void>();
    await _alarmTapCompleter!.future;
    _alarmTapCompleter = null;
    debugPrint('[Dialog] Alarm tapped!');

    _teeterTimer?.cancel();
    _teeterTimer = null;
    breathingEffect.removeFromParent();

    if (_speechBubble!.isMounted) {
      _speechBubble!.updateText('Good job!');
    }

    // Continuous vibration after the tap
    _alarm!.add(
      SequenceEffect([
        RotateEffect.by(0.07, LinearEffectController(0.07)),
        RotateEffect.by(-0.14, LinearEffectController(0.14)),
        RotateEffect.by(0.07, LinearEffectController(0.07)),
      ], infinite: true),
    );
  }
}
