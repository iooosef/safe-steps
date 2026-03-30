import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:safesteps/levels/level.dart';
import 'package:safesteps/ssgame.dart';
import 'package:safesteps/tutorial_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Layout constants shared across all worlds.
// ─────────────────────────────────────────────────────────────────────────────
const double kViewportW = 640;
const double kViewportH = 360;

// ─────────────────────────────────────────────────────────────────────────────
// Asset manifest — every image the minigame needs, loaded once up-front.
// ─────────────────────────────────────────────────────────────────────────────
const List<String> _earthquakeAssets = [
  // Characters
  'assets/characters/Normal.png',
  'assets/characters/Injured.png',
  'assets/characters/Bandage.png',
  'assets/characters/walkingwithbag.1.png',
  'assets/characters/walkingwithbag.2.png',
  'assets/characters/walkingwithbag.3.png',
  'assets/characters/walkingwithbag.4.png',
  // Backgrounds
  'assets/earthquake/Backgrounds/E1.jpg',
  'assets/earthquake/Backgrounds/E2.jpg',
  'assets/earthquake/Backgrounds/E3.jpg',
  'assets/earthquake/Backgrounds/ClassroomDestroyed_640x360.png',
  'assets/earthquake/Backgrounds/Hallway.png',
  'assets/earthquake/Backgrounds/normal_640x360.png',
  'assets/earthquake/Backgrounds/dark_bg.png',
  // Objects
  'assets/earthquake/Objects/Clock.png',
  'assets/earthquake/Objects/Table.png',
  // Buttons
  'assets/earthquake/Buttons/CoverB(Unselected).png',
  'assets/earthquake/Buttons/CoverB(Selected).png',
  'assets/earthquake/Buttons/DuckB(Unselected).png',
  'assets/earthquake/Buttons/DropB(Selected).png',
  'assets/earthquake/Buttons/HoldB(Unselected).png',
  'assets/earthquake/Buttons/HoldB(Selected).png',
  // Comics
  'assets/earthquake/comics/sun1.png',
  'assets/earthquake/comics/sun2.png',
  'assets/earthquake/comics/sun3.png',
];

// ─────────────────────────────────────────────────────────────────────────────
// Earthquake – Top-level Component that owns the camera and orchestrates
// the full minigame: Sun → Hallway → Tutorial → Level.
// ─────────────────────────────────────────────────────────────────────────────
class Earthquake extends Component with HasGameReference<SSGame> {
  late final Level _level;
  late final CameraComponent cam;

  @override
  FutureOr<void> onLoad() async {
    game.images.prefix = '';
    await game.images.loadAll(_earthquakeAssets);

    _level = Level();

    final tutorialWorld = TutorialWorld(onFinished: () {
      cam.world = _level;
    });

    final hallwayWorld = HallwayIntroWorld(onFinished: () {
      cam.world = tutorialWorld;
      tutorialWorld.activate();
    });

    final sunWorld = SunIntroWorld(onFinished: () {
      cam.world = hallwayWorld;
    });

    cam = CameraComponent.withFixedResolution(
      world: sunWorld,
      width: kViewportW,
      height: kViewportH,
    );
    cam.viewfinder.anchor = Anchor.topLeft;

    await add(sunWorld);
    await add(hallwayWorld);
    await add(tutorialWorld);
    await add(_level);
    await add(cam);

    return super.onLoad();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SunIntroWorld – Three-frame comic splash (sun1 → sun2 → sun3).
// ─────────────────────────────────────────────────────────────────────────────
class SunIntroWorld extends World with HasGameReference<SSGame> {
  final VoidCallback onFinished;
  SunIntroWorld({required this.onFinished});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final sun1 = await game.loadSprite('assets/earthquake/comics/sun1.png');
    final sun2 = await game.loadSprite('assets/earthquake/comics/sun2.png');
    final sun3 = await game.loadSprite('assets/earthquake/comics/sun3.png');

    final sprite = SpriteComponent(sprite: sun1, size: Vector2(kViewportW, kViewportH));
    add(sprite);

    add(TimerComponent(period: 0.5, removeOnFinish: true, onTick: () => sprite.sprite = sun2));
    add(TimerComponent(period: 1.0, removeOnFinish: true, onTick: () => sprite.sprite = sun3));
    add(TimerComponent(period: 1.5, removeOnFinish: true, onTick: onFinished));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HallwayIntroWorld – Scrolling hallway with walking character animation.
// ─────────────────────────────────────────────────────────────────────────────
class HallwayIntroWorld extends World with HasGameReference<SSGame> {
  final VoidCallback onFinished;
  HallwayIntroWorld({required this.onFinished});

  static const double _hallwayW = 2173;
  static const double _scrollDistance = _hallwayW - kViewportW;
  static const double _scrollDuration = 10.0;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final hallway = SpriteComponent(
      sprite: await game.loadSprite('assets/earthquake/Backgrounds/Hallway.png'),
      size: Vector2(_hallwayW, kViewportH),
      position: Vector2.zero(),
    );
    add(hallway);

    final walk1 = await game.loadSprite('assets/characters/walkingwithbag.1.png');
    final walk2 = await game.loadSprite('assets/characters/walkingwithbag.2.png');
    final walk3 = await game.loadSprite('assets/characters/walkingwithbag.3.png');
    final walk4 = await game.loadSprite('assets/characters/walkingwithbag.4.png');

    final walkAnim = SpriteAnimation.spriteList([walk1, walk2, walk3, walk4], stepTime: 0.25);

    final character = SpriteAnimationComponent(
      animation: walkAnim,
      size: Vector2(274, 365),
      anchor: Anchor.bottomCenter,
      position: Vector2(320, 400),
    );
    add(character);

    hallway.add(MoveEffect.by(
      Vector2(-_scrollDistance, 0),
      EffectController(duration: _scrollDuration, curve: Curves.linear),
    ));

    add(TimerComponent(
      period: _scrollDuration + 0.3,
      removeOnFinish: true,
      onTick: onFinished,
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TutorialWorld – Narrative dialogue → background transition → drag-and-drop
// puzzle. Implements TutorialController so Flutter overlays can call back.
// ─────────────────────────────────────────────────────────────────────────────
class TutorialWorld extends World
    with HasGameReference<SSGame>
    implements TutorialController {
  final VoidCallback onFinished;

  @override
  final TutorialState state = TutorialState();

  late final SpriteComponent _normalBg;
  late final SpriteComponent _darkBg;
  late final SpriteComponent _playerCharacter;

  final List<_PuzzlePiece> _pieces = [];
  final List<Component> _puzzleComponents = [];

  static final List<Vector2> _slotPositions = [
    Vector2(420, 80),
    Vector2(420, 170),
    Vector2(420, 260),
  ];

  static final List<Vector2> _pieceStartPositions = [
    Vector2(160, 260),
    Vector2(160, 80),
    Vector2(160, 170),
  ];

  TutorialWorld({required this.onFinished});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _normalBg = SpriteComponent(
      sprite: await game.loadSprite('assets/earthquake/Backgrounds/normal_640x360.png'),
      size: Vector2(kViewportW, kViewportH),
    );
    add(_normalBg);

    _darkBg = SpriteComponent(
      sprite: await game.loadSprite('assets/earthquake/Backgrounds/dark_bg.png'),
      size: Vector2(kViewportW, kViewportH),
    )..opacity = 0;
    add(_darkBg);

    _playerCharacter = SpriteComponent(
      sprite: await game.loadSprite('assets/characters/Normal.png'),
      size: Vector2(137, 182),
      anchor: Anchor.bottomLeft,
      position: Vector2(16, 350),
    );
    add(_playerCharacter);
  }

  void activate() {
    game.activeTutorial = this;
    _showDialogueOverlay();
  }

  // ── Overlay helpers ────────────────────────────────────────────────────

  void _showDialogueOverlay() {
    _removeAllOverlays();
    game.overlays.add('tutorialDialogue');
  }

  void _removeAllOverlays() {
    game.overlays.remove('tutorialDialogue');
    game.overlays.remove('tutorialMistake');
    game.overlays.remove('tutorialSuccess');
    game.overlays.remove('tutorialGameOver');
    game.overlays.remove('tutorialHint');
  }

  // ── TutorialController ─────────────────────────────────────────────────

  @override
  void onDialogueTap() {
    final changed = state.advanceDialogue();
    if (changed) {
      if (state.narrativeScene == NarrativeScene.transitionToDark) {
        _removeAllOverlays();
        _transitionToDark();
      } else if (state.phase == TutorialPhase.puzzle) {
        _removeAllOverlays();
        _startPuzzlePhase();
      }
    } else {
      _showDialogueOverlay();
    }
  }

  @override
  void onMistakeDismiss() {
    _removeAllOverlays();
    for (int i = 0; i < _pieces.length; i++) {
      _pieces[i].position = _pieceStartPositions[i].toVector2();
    }
    if (state.showHint) {
      game.overlays.add('tutorialHint');
    }
  }

  @override
  void onSuccessTap() {
    _removeAllOverlays();
    game.activeTutorial = null;
    onFinished();
  }

  @override
  void onGameOverRetry() {
    _removeAllOverlays();
    state.reset();
    for (final comp in _puzzleComponents) {
      comp.removeFromParent();
    }
    _puzzleComponents.clear();
    _pieces.clear();
    _darkBg.opacity = 0;
    _updatePlayerSprite('normal');
    _showDialogueOverlay();
  }

  // ── Background transition ──────────────────────────────────────────────

  void _transitionToDark() {
    _darkBg.add(OpacityEffect.to(
      1.0,
      EffectController(duration: 2.0, curve: Curves.easeInOut),
      onComplete: () {
        state.onTransitionComplete();
        _showDialogueOverlay();
      },
    ));
  }

  // ── Puzzle Phase ───────────────────────────────────────────────────────

  void _startPuzzlePhase() {
    for (int i = 0; i < 3; i++) {
      final slotOutline = RectangleComponent(
        position: _slotPositions[i].toVector2(),
        size: Vector2(180, 70),
        anchor: Anchor.center,
        paint: Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _puzzleComponents.add(slotOutline);
      add(slotOutline);

      final slotLabel = TextComponent(
        text: '${i + 1}',
        position: _slotPositions[i].toVector2() - Vector2(110, 0),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'Cherry Bomb One',
            fontSize: 24,
            color: Colors.white54,
          ),
        ),
      );
      _puzzleComponents.add(slotLabel);
      add(slotLabel);
    }

    const pieceData = [
      ('cover', 'Cover under desk'),
      ('hold', 'Hold the table'),
      ('drop', 'Drop'),
    ];

    _pieces.clear();
    for (int i = 0; i < pieceData.length; i++) {
      final piece = _PuzzlePiece(
        id: pieceData[i].$1,
        label: pieceData[i].$2,
        slotPositions: _slotPositions.map((v) => v.toVector2()).toList(),
        startPosition: _pieceStartPositions[i].toVector2(),
      );
      _pieces.add(piece);
      _puzzleComponents.add(piece);
      add(piece);
    }

    final submit = _SubmitButton(
      position: Vector2(420, 335),
      onPressed: _onPuzzleSubmit,
    );
    _puzzleComponents.add(submit);
    add(submit);

    if (state.showHint) {
      game.overlays.add('tutorialHint');
    }
  }

  void _onPuzzleSubmit() {
    final order = <String>[];
    for (final slotPos in _slotPositions) {
      _PuzzlePiece? closest;
      double closestDist = double.infinity;
      for (final piece in _pieces) {
        final dist = piece.position.distanceTo(slotPos.toVector2());
        if (dist < closestDist && dist < 60) {
          closestDist = dist;
          closest = piece;
        }
      }
      order.add(closest?.id ?? '');
    }

    final correct = state.checkAnswer(order);
    if (correct) {
      _removeAllOverlays();
      game.overlays.add('tutorialSuccess');
    } else if (state.phase == TutorialPhase.gameOver) {
      _removeAllOverlays();
      game.overlays.add('tutorialGameOver');
    } else {
      _removeAllOverlays();
      _updatePlayerSprite(state.playerSpriteKey);
      game.overlays.add('tutorialMistake');
    }
  }

  void _updatePlayerSprite(String key) {
    final path = switch (key) {
      'injured' => 'assets/characters/Injured.png',
      'bandage' => 'assets/characters/Bandage.png',
      _ => 'assets/characters/Normal.png',
    };
    game.loadSprite(path).then((spr) => _playerCharacter.sprite = spr);
  }

  @override
  void onRemove() {
    _removeAllOverlays();
    if (game.activeTutorial == this) {
      game.activeTutorial = null;
    }
    super.onRemove();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PuzzlePiece – Draggable card for one earthquake safety step.
// ─────────────────────────────────────────────────────────────────────────────
class _PuzzlePiece extends PositionComponent with DragCallbacks {
  final String id;
  final String label;
  final List<Vector2> slotPositions;
  final Vector2 startPosition;

  static const double snapThreshold = 50;

  _PuzzlePiece({
    required this.id,
    required this.label,
    required this.slotPositions,
    required this.startPosition,
  }) : super(
          size: Vector2(180, 60),
          anchor: Anchor.center,
          position: startPosition.clone(),
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF2A3A5C),
    ));
    add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    ));
    add(TextComponent(
      text: label,
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Cherry Bomb One',
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    ));
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    for (final slot in slotPositions) {
      if (position.distanceTo(slot) < snapThreshold) {
        position = slot.clone();
        return;
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SubmitButton – Tappable button that triggers puzzle validation.
// ─────────────────────────────────────────────────────────────────────────────
class _SubmitButton extends PositionComponent with TapCallbacks {
  final VoidCallback onPressed;

  _SubmitButton({
    required Vector2 position,
    required this.onPressed,
  }) : super(
          position: position,
          size: Vector2(140, 44),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF00A5FF),
    ));
    add(TextComponent(
      text: 'Check Order',
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Cherry Bomb One',
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    ));
  }

  @override
  void onTapUp(TapUpEvent event) {
    onPressed();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vector2 extension for const lists (Vector2 is not const-constructible).
// ─────────────────────────────────────────────────────────────────────────────
extension on Vector2 {
  Vector2 toVector2() => clone();
}
