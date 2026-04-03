import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/earthquake.dart';
import 'package:safesteps/objects.dart';
import 'package:safesteps/ssgame.dart';
import 'package:safesteps/tutorial_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Minigame-specific state – extends TutorialState with custom player messages.
// ─────────────────────────────────────────────────────────────────────────────
class _MinigameState extends TutorialState {
  _MinigameState() {
    phase = TutorialPhase.puzzle;
  }

  @override
  String get mistakePlayerLine {
    if (mistakes == 1) return 'Ouch! I need to be careful!';
    return 'Uh oh… that hurt a little.';
  }

  @override
  void reset() {
    super.reset();
    phase = TutorialPhase.puzzle;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Level – Earthquake minigame world with drag-and-drop puzzle, three-strike
// mistake system, and character sprite swapping.
// ─────────────────────────────────────────────────────────────────────────────
class Level extends World
    with HasGameReference<SSGame>
    implements TutorialController {
  double trauma = 0;
  final math.Random _random = math.Random();

  @override
  final TutorialState state = _MinigameState();

  late final PositionComponent bgContainer;
  late final PositionComponent objectContainer;
  late final SpriteAnimationComponent background;
  late final Sprite destroyedBackground;
  late final GameItem clock;
  late final GameItem table;

  // Player character (controlled via sprite swapping).
  late final SpriteComponent _playerCharacter;
  late Sprite _normalSprite;
  late Sprite _injuredSprite;
  late Sprite _bandageSprite;

  // Puzzle components.
  final List<_LevelPuzzlePiece> _pieces = [];
  final List<Component> _puzzleComponents = [];

  /// When true, dragging and submit are disabled (overlay is showing).
  bool _inputLocked = false;

  /// Whether the puzzle has been built yet (built on activate, not onLoad).
  bool _puzzleBuilt = false;

  // Horizontal target slots (left → right): same layout as the tutorial.
  static final List<Vector2> _slotPositions = [
    Vector2(250, 180),
    Vector2(380, 180),
    Vector2(510, 180),
  ];

  // Pieces start in a scrambled row above the slots: same as tutorial.
  static final List<Vector2> _pieceStartPositions = [
    Vector2(510, 60),
    Vector2(250, 60),
    Vector2(380, 60),
  ];

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

  @override
  Future<void> onLoad() async {
    super.onLoad();

    bgContainer = PositionComponent();
    objectContainer = PositionComponent();
    add(bgContainer);
    add(objectContainer);

    // --- Animated earthquake background ---
    final frame1 =
        await game.loadSprite('assets/earthquake/Backgrounds/E1.jpg');
    final frame2 =
        await game.loadSprite('assets/earthquake/Backgrounds/E2.jpg');
    final frame3 =
        await game.loadSprite('assets/earthquake/Backgrounds/E3.jpg');
    destroyedBackground = await game.loadSprite(
      'assets/earthquake/Backgrounds/ClassroomDestroyed_640x360.png',
    );

    background = SpriteAnimationComponent(
      animation: SpriteAnimation.spriteList(
        [frame1, frame2, frame3],
        stepTime: 1,
      ),
      size: Vector2(kViewportW, kViewportH),
    );
    bgContainer.add(background);

    // --- Scene objects ---
    clock = GameItem.clock(position: Vector2(45, 45));
    table = GameItem.table(position: Vector2(350, 245));
    objectContainer.add(clock);
    objectContainer.add(table);

    // --- Player character ---
    _normalSprite =
        Sprite(game.images.fromCache('assets/characters/Normal.png'));
    _injuredSprite =
        Sprite(game.images.fromCache('assets/characters/Injured.png'));
    _bandageSprite =
        Sprite(game.images.fromCache('assets/characters/Bandage.png'));

    _playerCharacter = SpriteComponent(
      sprite: _normalSprite,
      size: Vector2(274, 365),
      anchor: Anchor.center,
      position: Vector2(128, 270),
    );
    objectContainer.add(_playerCharacter);
  }

  /// Called by Earthquake after setting cam.world = this.
  /// Matches the TutorialWorld.activate() pattern: register as active
  /// controller, build puzzle, and start the earthquake.
  void activate() {
    game.activeTutorial = this;

    if (!_puzzleBuilt) {
      _puzzleBuilt = true;
      _buildPuzzle();
    }

    startEarthquake(0.5);
  }

  // ── Puzzle setup ───────────────────────────────────────────────────────

  Sprite _cachedSprite(String path) => Sprite(game.images.fromCache(path));

  void _buildPuzzle() {
    // Slot outlines with numbered labels.
    for (int i = 0; i < 3; i++) {
      final slotOutline = RectangleComponent(
        position: _slotPositions[i].clone(),
        size: Vector2(70, 70),
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
        position: _slotPositions[i].clone() + Vector2(0, 55),
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
      final piece = _LevelPuzzlePiece(
        id: id,
        unselectedSprite: _cachedSprite(assets.$1),
        selectedSprite: _cachedSprite(assets.$2),
        slotPositions: _slotPositions.map((v) => v.clone()).toList(),
        startPosition: _pieceStartPositions[i].clone(),
        isInputLocked: () => _inputLocked,
      );
      _pieces.add(piece);
      _puzzleComponents.add(piece);
      add(piece);
    }

    // Submit button (same 'Cherry Bomb One' blue style as the tutorial).
    final submit = _LevelSubmitButton(
      position: Vector2(380, 290),
      onPressed: _onPuzzleSubmit,
      isInputLocked: () => _inputLocked,
    )..priority = 1;
    _puzzleComponents.add(submit);
    add(submit);
  }

  // ── Puzzle validation ──────────────────────────────────────────────────

  void _onPuzzleSubmit() {
    if (_inputLocked) return;

    // Require all 3 slots to be filled before validating.
    final snappedCount = _pieces.where((p) => p.isSnapped).length;
    if (snappedCount < 3) {
      // Show hint instead of counting as a mistake.
      _removeAllOverlays();
      game.overlays.add('tutorialHint');
      return;
    }

    final order = <String>[];
    for (final slotPos in _slotPositions) {
      _LevelPuzzlePiece? closest;
      double closestDist = double.infinity;
      for (final piece in _pieces) {
        final dist = piece.position.distanceTo(slotPos);
        if (dist < closestDist && dist < 60) {
          closestDist = dist;
          closest = piece;
        }
      }
      order.add(closest?.id ?? '');
    }

    final correct = state.checkAnswer(order);
    _inputLocked = true;
    if (correct) {
      _removeAllOverlays();
      // Transition to destroyed classroom.
      background.animation =
          SpriteAnimation.spriteList([destroyedBackground], stepTime: 1);
      clock.removeFromParent();
      table.removeFromParent();
      stopEarthquake();
      game.paused = true;
      game.overlays.add('gameSuccess');
    } else if (state.phase == TutorialPhase.gameOver) {
      _removeAllOverlays();
      stopEarthquake();
      game.paused = true;
      game.overlays.add('gameFailure');
    } else {
      _removeAllOverlays();
      _refreshSprite();
      game.overlays.add('tutorialMistake');
    }
  }

  // ── Sprite management ─────────────────────────────────────────────────

  void _refreshSprite() {
    _playerCharacter.sprite = switch (state.playerSpriteKey) {
      'injured' => _injuredSprite,
      'bandage' => _bandageSprite,
      _ => _normalSprite,
    };
  }

  // ── Overlay helpers ────────────────────────────────────────────────────

  void _removeAllOverlays() {
    game.overlays.remove('tutorialDialogue');
    game.overlays.remove('tutorialMistake');
    game.overlays.remove('tutorialSuccess');
    game.overlays.remove('tutorialGameOver');
    game.overlays.remove('tutorialHint');
    game.overlays.remove('gameSuccess');
    game.overlays.remove('gameFailure');
  }

  // ── TutorialController implementation ──────────────────────────────────

  @override
  void onDialogueTap() {
    // No narrative phase in the minigame.
  }

  @override
  void onMistakeDismiss() {
    _removeAllOverlays();
    _inputLocked = false;
    for (int i = 0; i < _pieces.length; i++) {
      _pieces[i].position = _pieceStartPositions[i].clone();
      _pieces[i].resetSprite();
    }
    if (state.showHint) {
      game.overlays.add('tutorialHint');
    }
  }

  @override
  void onSuccessTap() {
    _removeAllOverlays();
    game.paused = false;
    game.activeTutorial = null;
    game.router.pushNamed('levels');
  }

  @override
  void onGameOverRetry() {
    _removeAllOverlays();
    game.paused = false;
    state.reset();
    _refreshSprite();
    _inputLocked = false;
    for (int i = 0; i < _pieces.length; i++) {
      _pieces[i].position = _pieceStartPositions[i].clone();
      _pieces[i].resetSprite();
    }
    // Restart the earthquake.
    startEarthquake(0.5);
  }

  // ── Earthquake shake logic ─────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);

    if (trauma > 0) {
      final baseShake = trauma * trauma;
      bgContainer.position = Vector2(
        (_random.nextDouble() - 0.5) * (baseShake * 8.0),
        (_random.nextDouble() - 0.5) * (baseShake * 8.0),
      );
      objectContainer.position = Vector2(
        (_random.nextDouble() - 0.5) * (baseShake * 25.0),
        (_random.nextDouble() - 0.5) * (baseShake * 25.0),
      );
    } else {
      bgContainer.position = Vector2.zero();
      objectContainer.position = Vector2.zero();
    }
  }

  void startEarthquake(double intensity) => trauma = intensity;
  void stopEarthquake() => trauma = 0;

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
// _LevelPuzzlePiece – Draggable button sprite that can snap to any slot.
// Shows unselected sprite when free, selected sprite when snapped.
// ─────────────────────────────────────────────────────────────────────────────
class _LevelPuzzlePiece extends PositionComponent with DragCallbacks {
  final String id;
  final Sprite unselectedSprite;
  final Sprite selectedSprite;
  final List<Vector2> slotPositions;
  final Vector2 startPosition;
  final bool Function() isInputLocked;

  late final SpriteComponent _spriteComp;
  bool isSnapped = false;

  static const double snapThreshold = 50;

  _LevelPuzzlePiece({
    required this.id,
    required this.unselectedSprite,
    required this.selectedSprite,
    required this.slotPositions,
    required this.startPosition,
    required this.isInputLocked,
  }) : super(
          size: Vector2(70, 70),
          anchor: Anchor.center,
          position: startPosition.clone(),
          priority: 1,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _spriteComp = SpriteComponent(
      sprite: unselectedSprite,
      size: size,
    );
    add(_spriteComp);
  }

  void resetSprite() {
    _spriteComp.sprite = unselectedSprite;
    isSnapped = false;
    priority = 1;
  }

  @override
  void onDragStart(DragStartEvent event) {
    // Always call super to keep Flame's drag lifecycle consistent.
    super.onDragStart(event);
    if (isInputLocked()) return;
    isSnapped = false;
    priority = 100;
    _spriteComp.sprite = unselectedSprite;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (isInputLocked()) return;
    position += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (isInputLocked()) return;

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
// _LevelSubmitButton – Tappable "Check Order" button that triggers validation.
// ─────────────────────────────────────────────────────────────────────────────
class _LevelSubmitButton extends PositionComponent with TapCallbacks {
  final VoidCallback onPressed;
  final bool Function() isInputLocked;

  _LevelSubmitButton({
    required Vector2 position,
    required this.onPressed,
    required this.isInputLocked,
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
    if (isInputLocked()) return;
    onPressed();
  }
}
