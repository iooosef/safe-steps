import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/safetysteps_game.dart';

class FireLevel1Scene3 extends World with HasGameReference<SafetyStepsGame> {
  final VoidCallback? onComplete;
  FireLevel1Scene3({this.onComplete});

  late double screenWidth;
  late double screenHeight;

  SpriteComponent? _bg1;
  SpriteComponent? _bg2;
  double _bgWidth = 0;
  static const double _bgScrollSpeed = 120.0;
  bool _scrolling = true;

  SpriteAnimationComponent? _walkingCharacter;
  final List<_ScrollingObject> _objects = [];

  @override
  Future<void> onLoad() async {
    debugPrint('Loading Fire Level 1 Scene 3...');
    game.setWorld(this);
    screenWidth = game.size.x;
    screenHeight = game.size.y;
    await _initScene();
  }

  Future<void> _initScene() async {
    _scrolling = true;
    _objects.clear();

    // ── Scrolling background ──────────────────────────────────────
    final bgSprite = await game.loadSprite('fire/FireHall.png');
    final aspectRatio = bgSprite.srcSize.y / bgSprite.srcSize.x;
    _bgWidth = screenHeight / aspectRatio;

    _bg1 = SpriteComponent()
      ..sprite = bgSprite
      ..size = Vector2(_bgWidth, screenHeight)
      ..position = Vector2(0, 0)
      ..anchor = Anchor.topLeft;

    _bg2 = SpriteComponent()
      ..sprite = bgSprite
      ..size = Vector2(_bgWidth, screenHeight)
      ..position = Vector2(_bgWidth, 0)
      ..anchor = Anchor.topLeft;

    addAll([_bg1!, _bg2!]);

    // ── Walking character ─────────────────────────────────────────
    final walkSprite = await game.loadSprite(
      'earthquake/characters/walking.png',
    );
    _walkingCharacter = SpriteAnimationComponent()
      ..animation = SpriteAnimation.fromFrameData(
        walkSprite.image,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.15,
          textureSize: Vector2(walkSprite.srcSize.x / 4, walkSprite.srcSize.y),
        ),
      )
      ..anchor = Anchor.bottomCenter
      ..position = Vector2(screenWidth * 0.35, screenHeight);
    _walkingCharacter!.size = _walkingCharacter!.size * 0.75;
    add(_walkingCharacter!);

    // ── Scrolling objects (staggered off-screen to the right) ─────
    final gap = screenWidth * 1.2;

    final ballSprite = await game.loadSprite('fire/Ball(Hallway).png');
    final ballH = screenHeight * 0.12;
    final ball = _ScrollingObject(
      sprite: ballSprite,
      scrollSpeed: _bgScrollSpeed,
      size: ballSprite.srcSize * 0.35,
      position: Vector2(screenWidth + 60, screenHeight * 0.95),
      anchor: Anchor.bottomLeft,
      onTapped: () => _onWrongTapped(
        'Do not stop to play during an emergency.\nKeep moving to safety.',
      ),
    );

    final alexSprite = await game.loadSprite('fire/AlexHall.png');
    final alexH = screenHeight * 0.65;
    final alex = _ScrollingObject(
      sprite: alexSprite,
      scrollSpeed: _bgScrollSpeed,
      size: alexSprite.srcSize * (alexH / alexSprite.srcSize.y),
      position: Vector2(screenWidth + 60 + gap, screenHeight),
      anchor: Anchor.bottomLeft,
      onTapped: () =>
          _onWrongTapped('Do not stop to chat.\nStay focused and exit safely.'),
    );

    final miraSprite = await game.loadSprite('fire/MiraHall.png');
    final miraH = screenHeight * 0.75;
    final mira = _ScrollingObject(
      sprite: miraSprite,
      scrollSpeed: _bgScrollSpeed,
      size: miraSprite.srcSize * (miraH / miraSprite.srcSize.y),
      position: Vector2(screenWidth + 60 + gap * 2, screenHeight),
      anchor: Anchor.bottomLeft,
      onTapped: () => _onMiraTapped(),
      onExit: () => _onWrongTapped('Follow adults for evacuation.'),
    );

    _objects.addAll([ball, alex, mira]);
    addAll(_objects);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_scrolling) return;

    _bg1?.position.x -= _bgScrollSpeed * dt;
    _bg2?.position.x -= _bgScrollSpeed * dt;

    if (_bg1 != null && _bg1!.position.x + _bgWidth <= 0) {
      _bg1!.position.x = _bg2!.position.x + _bgWidth;
    }
    if (_bg2 != null && _bg2!.position.x + _bgWidth <= 0) {
      _bg2!.position.x = _bg1!.position.x + _bgWidth;
    }
  }

  // ── Tap handlers ──────────────────────────────────────────────────────────

  Future<void> _onWrongTapped(String message) async {
    if (!_scrolling) return;
    _scrolling = false;
    for (final obj in _objects) {
      obj.disable();
    }

    await _showFail(message);

    // Restart scene
    removeAll(children.toList());
    _bg1 = _bg2 = _walkingCharacter = null;
    await _initScene();
  }

  Future<void> _onMiraTapped() async {
    if (!_scrolling) return;
    _scrolling = false;
    for (final obj in _objects) {
      obj.disable();
    }

    await _showComplete();
    Future.microtask(() {
      while (game.router.canPop()) {
        game.router.pop();
      }
      game.router.pushNamed('level_select');
    });
  }

  // ── Overlays ──────────────────────────────────────────────────────────────

  Future<void> _showFail(String message) async {
    final completer = Completer<void>();

    final dim = RectangleComponent(
      size: Vector2(screenWidth, screenHeight),
      paint: Paint()..color = const Color(0xCC000000),
    );

    // Split message on \n so each line is a separate TextComponent
    final lines = message.split('\n');
    final lineComponents = List.generate(lines.length, (i) {
      return TextComponent(
        text: lines[i],
        anchor: Anchor.topCenter,
        position: Vector2(screenWidth / 2, screenHeight * 0.32 + i * 28),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Comic Relief',
          ),
        ),
      );
    });

    final retryBtn = _SceneButton(
      label: 'Try Again',
      color: const Color(0xFFE53935),
      onPressed: completer.complete,
      size: Vector2(screenWidth * 0.28, screenHeight * 0.1),
      anchor: Anchor.center,
      position: Vector2(screenWidth / 2, screenHeight * 0.62),
    );

    addAll([dim, ...lineComponents, retryBtn]);
    await completer.future;
    removeAll([dim, ...lineComponents, retryBtn]);
  }

  Future<void> _showComplete() async {
    final completer = Completer<void>();

    final dim = RectangleComponent(
      size: Vector2(screenWidth, screenHeight),
      paint: Paint()..color = const Color(0xCC000000),
    );

    final congratsSprite = await game.loadSprite('Congratulations.png');
    final congratsImg = SpriteComponent()
      ..sprite = congratsSprite
      ..size =
          congratsSprite.srcSize *
          (screenWidth * 0.65 / congratsSprite.srcSize.x)
      ..anchor = Anchor.topCenter
      ..position = Vector2(screenWidth / 2, screenHeight * 0.04);

    final checks = [];
    final checkComponents = List.generate(checks.length, (i) {
      return TextComponent(
        text: checks[i],
        anchor: Anchor.topCenter,
        position: Vector2(screenWidth / 2, screenHeight * 0.44 + i * 30),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Comic Relief',
          ),
        ),
      );
    });

    final greatJob = TextComponent(
      text: 'Great job! You completed the fire drill safely!',
      anchor: Anchor.topCenter,
      position: Vector2(screenWidth / 2, screenHeight * 0.68),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Comic Relief',
        ),
      ),
    );

    final doneBtn = _SceneButton(
      label: 'Done!',
      color: const Color(0xFF4CAF50),
      onPressed: completer.complete,
      size: Vector2(screenWidth * 0.22, screenHeight * 0.1),
      anchor: Anchor.center,
      position: Vector2(screenWidth / 2, screenHeight * 0.84),
    );

    addAll([dim, congratsImg, ...checkComponents, greatJob, doneBtn]);
    await completer.future;
  }
}

// ─── Scrolling tappable object ────────────────────────────────────────────────

class _ScrollingObject extends SpriteComponent with TapCallbacks {
  final VoidCallback onTapped;
  final VoidCallback? onExit;
  final double scrollSpeed;
  bool _active = true;
  bool _exited = false;

  _ScrollingObject({
    required Sprite sprite,
    required this.onTapped,
    required this.scrollSpeed,
    required Vector2 size,
    required Vector2 position,
    Anchor anchor = Anchor.topLeft,
    this.onExit,
  }) : super(sprite: sprite, size: size, position: position, anchor: anchor);

  void disable() => _active = false;

  @override
  void update(double dt) {
    if (!_active) return;
    super.update(dt);
    position.x -= scrollSpeed * dt;

    if (!_exited && position.x + size.x < 0) {
      _exited = true;
      _active = false;
      onExit?.call();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_active) onTapped();
  }
}

// ─── Button ───────────────────────────────────────────────────────────────────

class _SceneButton extends PositionComponent with TapCallbacks {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  _SceneButton({
    required this.label,
    required this.color,
    required this.onPressed,
    required Vector2 size,
    super.anchor,
    super.position,
  }) : super(size: size);

  @override
  void onTapDown(TapDownEvent event) => onPressed();

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
