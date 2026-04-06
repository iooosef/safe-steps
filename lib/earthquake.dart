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
  'assets/characters/TeacherExplaining.png',
  'assets/characters/TeacherDoneExplaining.png',
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
  'assets/earthquake/Buttons/CoverB_Unselected.png',
  'assets/earthquake/Buttons/CoverB_Selected.png',
  'assets/earthquake/Buttons/DuckB_Unselected.png',
  'assets/earthquake/Buttons/DropB_Selected.png',
  'assets/earthquake/Buttons/HoldB_Unselected.png',
  'assets/earthquake/Buttons/HoldB_Selected.png',
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
  late final CameraComponent camera;

  @override
  FutureOr<void> onLoad() async {
    game.images.prefix = '';
    await game.images.loadAll(_earthquakeAssets);

    _level = Level();

    final tutorialWorld = TutorialWorld(
      onFinished: () {
        camera.world = _level;
        _level.activate();
      },
    );

    final hallwayWorld = HallwayIntroWorld(
      onFinished: () {
        camera.world = tutorialWorld;
        tutorialWorld.activate();
      },
    );

    final sunWorld = SunIntroWorld(
      onFinished: () {
        camera.world = hallwayWorld;
      },
    );

    camera = CameraComponent.withFixedResolution(
      world: sunWorld,
      width: kViewportW,
      height: kViewportH,
    );
    camera.viewfinder.anchor = Anchor.topLeft;

    await add(sunWorld);
    await add(hallwayWorld);
    await add(tutorialWorld);
    await add(_level);
    await add(camera);

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

    final sprite = SpriteComponent(
      sprite: sun1,
      size: Vector2(kViewportW, kViewportH),
    );
    add(sprite);

    add(
      TimerComponent(
        period: 0.5,
        removeOnFinish: true,
        onTick: () => sprite.sprite = sun2,
      ),
    );
    add(
      TimerComponent(
        period: 1.0,
        removeOnFinish: true,
        onTick: () => sprite.sprite = sun3,
      ),
    );
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
      sprite: await game.loadSprite(
        'assets/earthquake/Backgrounds/Hallway.png',
      ),
      size: Vector2(_hallwayW, kViewportH),
      position: Vector2.zero(),
    );
    add(hallway);

    final walk1 = await game.loadSprite(
      'assets/characters/walkingwithbag.1.png',
    );
    final walk2 = await game.loadSprite(
      'assets/characters/walkingwithbag.2.png',
    );
    final walk3 = await game.loadSprite(
      'assets/characters/walkingwithbag.3.png',
    );
    final walk4 = await game.loadSprite(
      'assets/characters/walkingwithbag.4.png',
    );

    final walkAnim = SpriteAnimation.spriteList([
      walk1,
      walk2,
      walk3,
      walk4,
    ], stepTime: 0.25);

    final character = SpriteAnimationComponent(
      animation: walkAnim,
      size: Vector2(274, 365),
      anchor: Anchor.bottomCenter,
      position: Vector2(320, 400),
    );
    add(character);

    hallway.add(
      MoveEffect.by(
        Vector2(-_scrollDistance, 0),
        EffectController(duration: _scrollDuration, curve: Curves.linear),
      ),
    );

    add(
      TimerComponent(
        period: _scrollDuration + 0.3,
        removeOnFinish: true,
        onTick: onFinished,
      ),
    );
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

  // Two characters: teacher on the left, player/classmate on the right.
  late final SpriteComponent _teacherCharacter;
  late final SpriteComponent _playerCharacter;

  late Sprite _teacherExplainingSprite;
  late Sprite _teacherDoneSprite;
  late Sprite _normalSprite;
  late Sprite _injuredSprite;
  late Sprite _bandageSprite;

  String _activeSpeaker = 'Teacher';

  final List<_PuzzlePiece> _pieces = [];
  final List<Component> _puzzleComponents = [];

  // Horizontal slots matching the minigame layout (left → right).
  static final List<Vector2> _slotPositions = [
    Vector2(250, 180),
    Vector2(380, 180),
    Vector2(510, 180),
  ];

  // Pieces start in scrambled order along a row above the slots.
  static final List<Vector2> _pieceStartPositions = [
    Vector2(510, 60),
    Vector2(250, 60),
    Vector2(380, 60),
  ];

  TutorialWorld({required this.onFinished});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Cache character sprites.
    _teacherExplainingSprite = Sprite(
      game.images.fromCache('assets/characters/TeacherExplaining.png'),
    );
    _teacherDoneSprite = Sprite(
      game.images.fromCache('assets/characters/TeacherDoneExplaining.png'),
    );
    _normalSprite = Sprite(
      game.images.fromCache('assets/characters/Normal.png'),
    );
    _injuredSprite = Sprite(
      game.images.fromCache('assets/characters/Injured.png'),
    );
    _bandageSprite = Sprite(
      game.images.fromCache('assets/characters/Bandage.png'),
    );

    _normalBg = SpriteComponent(
      sprite: await game.loadSprite(
        'assets/earthquake/Backgrounds/normal_640x360.png',
      ),
      size: Vector2(kViewportW, kViewportH),
    );
    add(_normalBg);

    _darkBg = SpriteComponent(
      sprite: await game.loadSprite(
        'assets/earthquake/Backgrounds/dark_bg.png',
      ),
      size: Vector2(kViewportW, kViewportH),
    )..opacity = 0;
    add(_darkBg);

    // Teacher – left side.
    _teacherCharacter = SpriteComponent(
      sprite: _teacherExplainingSprite,
      size: Vector2(274, 365),
      anchor: Anchor.bottomCenter,
      position: Vector2(128, 360),
    );
    add(_teacherCharacter);

    // Player / Classmate – right side, starts hidden.
    _playerCharacter = SpriteComponent(
      sprite: _normalSprite,
      size: Vector2(274, 365),
      anchor: Anchor.bottomCenter,
      position: Vector2(512, 500),
    )..opacity = 0;
    add(_playerCharacter);
  }

  void activate() {
    game.activeTutorial = this;
    _swapToSpeaker(state.currentLine?.speaker ?? 'Teacher');
    _showDialogueOverlay();
  }

  // ── Overlay helpers ────────────────────────────────────────────────────

  void _showDialogueOverlay() {
    _removeAllOverlays();
    final speaker = state.currentLine?.speaker ?? 'Teacher';
    _swapToSpeaker(speaker);
    game.overlays.add('tutorialDialogue');
  }

  // ── Speaker-based character swapping ───────────────────────────────────

  static const double _fadeInDuration = 0.25;
  static const double _fadeOutDuration = 0.15;

  void _swapToSpeaker(String speaker) {
    if (speaker == _activeSpeaker) return;
    _activeSpeaker = speaker;

    if (speaker == 'Teacher') {
      // Fade teacher in, fade player out.
      _teacherCharacter
        ..removeAll(_teacherCharacter.children.whereType<OpacityEffect>())
        ..add(
          OpacityEffect.to(1.0, EffectController(duration: _fadeInDuration)),
        );
      _playerCharacter
        ..removeAll(_playerCharacter.children.whereType<OpacityEffect>())
        ..add(
          OpacityEffect.to(0.0, EffectController(duration: _fadeOutDuration)),
        );
    } else {
      // 'You' or 'Classmate' — fade player in, dim teacher.
      _playerCharacter
        ..sprite = _normalSprite
        ..removeAll(_playerCharacter.children.whereType<OpacityEffect>())
        ..add(
          OpacityEffect.to(1.0, EffectController(duration: _fadeInDuration)),
        );
      _teacherCharacter
        ..removeAll(_teacherCharacter.children.whereType<OpacityEffect>())
        ..add(
          OpacityEffect.to(0.3, EffectController(duration: _fadeOutDuration)),
        );
    }
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
      _pieces[i].resetSprite();
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
    // Reset both characters to initial narrative state.
    _activeSpeaker = 'Teacher';
    _teacherCharacter
      ..sprite = _teacherExplainingSprite
      ..opacity = 1;
    _playerCharacter
      ..sprite = _normalSprite
      ..opacity = 0;
    _showDialogueOverlay();
  }

  // ── Background transition ──────────────────────────────────────────────

  void _transitionToDark() {
    // Teacher finishes explaining before the earthquake hits.
    _teacherCharacter.sprite = _teacherDoneSprite;

    _darkBg.add(
      OpacityEffect.to(
        1.0,
        EffectController(duration: 2.0, curve: Curves.easeInOut),
        onComplete: () {
          state.onTransitionComplete();
          _showDialogueOverlay();
        },
      ),
    );
  }

  // ── Puzzle Phase ───────────────────────────────────────────────────────

  Sprite _cachedSprite(String path) => Sprite(game.images.fromCache(path));

  static const Map<String, (String, String)> _pieceAssets = {
    'drop': (
      'assets/earthquake/Buttons/DuckB_Unselected.png',
      'assets/earthquake/Buttons/DropB_Selected.png',
    ),
    'cover': (
      'assets/earthquake/Buttons/CoverB_Unselected.png',
      'assets/earthquake/Buttons/CoverB_Selected.png',
    ),
    'hold': (
      'assets/earthquake/Buttons/HoldB_Unselected.png',
      'assets/earthquake/Buttons/HoldB_Selected.png',
    ),
  };

  void _startPuzzlePhase() {
    // Hide characters to make room for the horizontal puzzle.
    _teacherCharacter.opacity = 0;
    _playerCharacter.opacity = 0;

    for (int i = 0; i < 3; i++) {
      // Slot outline – same 70×70 as the minigame.
      final slotOutline = RectangleComponent(
        position: _slotPositions[i].toVector2(),
        size: Vector2(70, 70),
        anchor: Anchor.center,
        paint: Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _puzzleComponents.add(slotOutline);
      add(slotOutline);

      // Numbered label below each slot.
      final slotLabel = TextComponent(
        text: '${i + 1}',
        position: _slotPositions[i].toVector2() + Vector2(0, 55),
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

    // Scrambled order: cover, hold, drop (must be rearranged to drop, cover, hold).
    const pieceOrder = ['cover', 'hold', 'drop'];

    _pieces.clear();
    for (int i = 0; i < pieceOrder.length; i++) {
      final id = pieceOrder[i];
      final assets = _pieceAssets[id]!;
      final piece = _PuzzlePiece(
        id: id,
        unselectedSprite: _cachedSprite(assets.$1),
        selectedSprite: _cachedSprite(assets.$2),
        slotPositions: _slotPositions.map((v) => v.toVector2()).toList(),
        startPosition: _pieceStartPositions[i].toVector2(),
      );
      _pieces.add(piece);
      _puzzleComponents.add(piece);
      add(piece);
    }

    final submit = _SubmitButton(
      position: Vector2(380, 290),
      onPressed: _onPuzzleSubmit,
    )..priority = 1;
    _puzzleComponents.add(submit);
    add(submit);

    if (state.showHint) {
      game.overlays.add('tutorialHint');
    }
  }

  void _onPuzzleSubmit() {
    // Require all 3 slots to be filled before validating.
    final snappedCount = _pieces.where((p) => p.isSnapped).length;
    if (snappedCount < 3) {
      _removeAllOverlays();
      game.overlays.add('tutorialHint');
      return;
    }

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
    _playerCharacter.sprite = switch (key) {
      'injured' => _injuredSprite,
      'bandage' => _bandageSprite,
      _ => _normalSprite,
    };
    // During puzzle phase the player should be visible.
    _playerCharacter.opacity = 1;
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
// _PuzzlePiece – Draggable button sprite for one earthquake safety step.
// Shows unselected sprite when free, selected sprite when snapped to a slot.
// ─────────────────────────────────────────────────────────────────────────────
class _PuzzlePiece extends PositionComponent with DragCallbacks {
  final String id;
  final Sprite unselectedSprite;
  final Sprite selectedSprite;
  final List<Vector2> slotPositions;
  final Vector2 startPosition;

  late final SpriteComponent _spriteComp;
  bool isSnapped = false;

  static const double snapThreshold = 50;

  _PuzzlePiece({
    required this.id,
    required this.unselectedSprite,
    required this.selectedSprite,
    required this.slotPositions,
    required this.startPosition,
  }) : super(
         size: Vector2(70, 70),
         anchor: Anchor.center,
         position: startPosition.clone(),
         priority: 1,
       );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _spriteComp = SpriteComponent(sprite: unselectedSprite, size: size);
    add(_spriteComp);
  }

  void resetSprite() {
    _spriteComp.sprite = unselectedSprite;
    isSnapped = false;
    priority = 1;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    isSnapped = false;
    priority = 100;
    _spriteComp.sprite = unselectedSprite;
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
        _spriteComp.sprite = selectedSprite;
        isSnapped = true;
        priority = 0;
        return;
      }
    }
    priority = 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SubmitButton – Tappable button that triggers puzzle validation.
// ─────────────────────────────────────────────────────────────────────────────
class _SubmitButton extends PositionComponent with TapCallbacks {
  final VoidCallback onPressed;

  _SubmitButton({required Vector2 position, required this.onPressed})
    : super(position: position, size: Vector2(140, 44), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    add(
      RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0xFF00A5FF),
      ),
    );
    add(
      TextComponent(
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
      ),
    );
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
