import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/safetysteps_game.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum _Phase { walking, alerting, aftershock, falling, gameOver, victory }

enum _CharState { walking, ducking, falling }

// ─── EarthquakeLvl3Puzzle ─────────────────────────────────────────────────────

class EarthquakeLvl3Puzzle extends World
    with HasGameReference<SafetyStepsGame> {
  static const double _scrollSpeed = 160.0;
  static const int _totalAfterShocks = 5;
  static const double _shakeAmplitude = 10.0;
  // Grace period at the start of each aftershock before a fall is triggered
  static const double _afterShockGrace = 0.5;

  // Background
  late PositionComponent _bgContainer;
  late SpriteComponent _bg1;
  late SpriteComponent _bg2;
  late double _bgTileWidth;

  // Character slot and sprite variants
  late PositionComponent _characterSlot;
  late SpriteAnimationComponent _walkAnimComp;
  late SpriteComponent _duckSprite;
  late SpriteAnimationComponent _fallAnimComp;

  // Alert
  late SpriteComponent _alertSprite;

  // Game state
  _Phase _phase = _Phase.walking;
  int _aftershocksLeft = _totalAfterShocks;
  bool isDucking = false;
  bool _active = true;

  // Lives exposed as a ValueNotifier so the HUD rebuilds on change
  final livesNotifier = ValueNotifier<int>(3);
  int get _lives => livesNotifier.value;
  set _lives(int v) => livesNotifier.value = v;

  // Shake tracking
  double _shakeElapsed = 0;
  double _shakeDuration = 0;
  final _rng = Random();

  // Frozen until the instruction card is dismissed
  bool _gameStarted = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    game.setWorld(this);
    final sz = game.size;

    // ── Hallway tiles (infinite scroll) ──────────────────────────────────────
    final hallwaySprite = await game.loadSprite(
      'earthquake/backgrounds/hallway.png',
    );
    _bgTileWidth = sz.y * (hallwaySprite.srcSize.x / hallwaySprite.srcSize.y);
    if (_bgTileWidth < sz.x) {
      _bgTileWidth = sz.x;
    }

    _bgContainer = PositionComponent(position: Vector2.zero());
    _bg1 = SpriteComponent(
      sprite: hallwaySprite,
      size: Vector2(_bgTileWidth, sz.y),
      anchor: Anchor.topLeft,
    );
    _bg2 = SpriteComponent(
      sprite: hallwaySprite,
      size: Vector2(_bgTileWidth, sz.y),
      anchor: Anchor.topLeft,
      position: Vector2(_bgTileWidth, 0),
    );
    _bgContainer.add(_bg1);
    _bgContainer.add(_bg2);
    add(_bgContainer);

    // ── Alert sprite (centered, high priority) ────────────────────────────────
    final alertSpr = await game.loadSprite('earthquake/objects/alert.png');
    final alertW = sz.x * 0.22;
    final alertH = alertW * (alertSpr.srcSize.y / alertSpr.srcSize.x);
    _alertSprite = SpriteComponent(
      sprite: alertSpr,
      size: Vector2(alertW, alertH),
      anchor: Anchor.center,
      position: Vector2(sz.x / 2, sz.y * 0.2),
      priority: 20,
    );

    // ── Character height (all frames are 640×640 — square) ───────────────────
    final charH = sz.y * 0.7;

    // Walk animation — cover.png, 4 frames (2560×640)
    final walkImg = await game.images.load('earthquake/characters/cover.png');
    _walkAnimComp = SpriteAnimationComponent(
      animation: SpriteAnimation.fromFrameData(
        walkImg,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.18,
          textureSize: Vector2(walkImg.width / 4, walkImg.height.toDouble()),
        ),
      ),
      size: Vector2(charH, charH), // square frames
      anchor: Anchor.bottomLeft,
    );

    // Duck sprite — dropCover.png, single frame (640×640)
    final duckSpr = await game.loadSprite('earthquake/characters/dropCover.png');
    _duckSprite = SpriteComponent(
      sprite: duckSpr,
      size: Vector2(charH, charH),
      anchor: Anchor.bottomLeft,
    );

    // Fall animation — fall.png, 5 frames (3200×640), play once
    final fallImg = await game.images.load('earthquake/characters/fall.png');
    _fallAnimComp = SpriteAnimationComponent(
      animation: SpriteAnimation.fromFrameData(
        fallImg,
        SpriteAnimationData.sequenced(
          amount: 5,
          stepTime: 0.15,
          textureSize: Vector2(fallImg.width / 5, fallImg.height.toDouble()),
          loop: false,
        ),
      ),
      size: Vector2(charH, charH),
      anchor: Anchor.bottomLeft,
    );

    // ── Character slot ────────────────────────────────────────────────────────
    _characterSlot = PositionComponent(
      position: Vector2(sz.x * 0.15, sz.y),
    );
    _characterSlot.add(_walkAnimComp);
    add(_characterSlot);

    // ── Show instructions before the game begins ──────────────────────────────
    game.router.pushOverlay('earthquake_level_3_instructions');
  }

  /// Called by the instruction overlay when the player dismisses it.
  void startGame() {
    if (_gameStarted) return;
    _gameStarted = true;
    game.router.pop(); // pop instructions overlay
    game.router.pushOverlay('earthquake_level_3_hud');
    _scheduleNextAfterShock();
  }

  @override
  void onRemove() {
    _active = false;
    livesNotifier.dispose();
    super.onRemove();
  }

  // ── Aftershock sequence ───────────────────────────────────────────────────────

  void _scheduleNextAfterShock() {
    if (_aftershocksLeft <= 0 || !_active || !_gameStarted) return;
    final delayMs = 3000 + _rng.nextInt(2001); // 3–5 s
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!_active || _phase != _Phase.walking) return;
      _startAlert();
    });
  }

  Future<void> _startAlert() async {
    if (!_active) return;
    _phase = _Phase.alerting;
    // Flash alert image 3 times
    for (int i = 0; i < 3; i++) {
      if (!_active) return;
      add(_alertSprite);
      await Future.delayed(const Duration(milliseconds: 200));
      if (_alertSprite.isMounted) remove(_alertSprite);
      await Future.delayed(const Duration(milliseconds: 150));
    }
    if (!_active) return;
    _aftershocksLeft--;
    _phase = _Phase.aftershock;
    _shakeDuration = 3.0 + _rng.nextDouble() * 2.0; // 3–5 s
    _shakeElapsed = 0;
  }

  void _onAfterShockEnd() {
    _shakeDuration = 0;
    _shakeElapsed = 0;
    _bgContainer.position = Vector2.zero();
    _phase = _Phase.walking;
    _setCharacterState(_CharState.walking);
    if (_aftershocksLeft <= 0) {
      _triggerVictory();
    } else {
      _scheduleNextAfterShock();
    }
  }

  // ── Player input ──────────────────────────────────────────────────────────────

  void setDucking(bool value) {
    isDucking = value;
    // Ignore input in terminal / in-progress-fall states
    if (_phase == _Phase.gameOver ||
        _phase == _Phase.victory ||
        _phase == _Phase.falling) return;

    if (value) {
      _setCharacterState(_CharState.ducking);
    } else if (_phase == _Phase.aftershock &&
        _shakeElapsed > _afterShockGrace) {
      // Released during active aftershock (past grace period) → fall
      _triggerFall();
    } else {
      // Safe to stand up (idle / alerting / grace period)
      if (_phase == _Phase.walking) _setCharacterState(_CharState.walking);
    }
  }

  // ── Character state ───────────────────────────────────────────────────────────

  void _setCharacterState(_CharState state) {
    if (_walkAnimComp.isMounted) _characterSlot.remove(_walkAnimComp);
    if (_duckSprite.isMounted) _characterSlot.remove(_duckSprite);
    if (_fallAnimComp.isMounted) _characterSlot.remove(_fallAnimComp);
    switch (state) {
      case _CharState.walking:
        _characterSlot.add(_walkAnimComp);
      case _CharState.ducking:
        _characterSlot.add(_duckSprite);
      case _CharState.falling:
        _fallAnimComp.animationTicker?.reset();
        _characterSlot.add(_fallAnimComp);
    }
  }

  void _triggerFall() {
    if (_phase == _Phase.falling) return;
    _phase = _Phase.falling;
    _shakeDuration = 0;
    _shakeElapsed = 0;
    _bgContainer.position = Vector2.zero();
    _setCharacterState(_CharState.falling);
  }

  void _onFallComplete() {
    _lives--;
    if (_lives <= 0) {
      _triggerGameOver();
    } else {
      _phase = _Phase.walking;
      _setCharacterState(_CharState.walking);
      if (_aftershocksLeft <= 0) {
        _triggerVictory();
      } else {
        _scheduleNextAfterShock();
      }
    }
  }

  void _triggerGameOver() {
    _phase = _Phase.gameOver;
    game.router.pop(); // pop HUD
    game.router.pushOverlay('earthquake_level_3_game_over');
  }

  void _triggerVictory() {
    _phase = _Phase.victory;
    game.router.pop(); // pop HUD
    game.router.pushOverlay('earthquake_level_3_victory');
  }

  // ── Update ────────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);

    // Scroll only once the game has started, while walking/alerting and not ducking
    if (_gameStarted &&
        (_phase == _Phase.walking || _phase == _Phase.alerting) &&
        !isDucking) {
      _bg1.position.x -= _scrollSpeed * dt;
      _bg2.position.x -= _scrollSpeed * dt;
      if (_bg1.position.x + _bgTileWidth <= 0) {
        _bg1.position.x = _bg2.position.x + _bgTileWidth;
      }
      if (_bg2.position.x + _bgTileWidth <= 0) {
        _bg2.position.x = _bg1.position.x + _bgTileWidth;
      }
    }

    // Shake + fall-if-standing during aftershock
    if (_phase == _Phase.aftershock && _shakeDuration > 0) {
      _shakeElapsed += dt;
      final remaining = _shakeDuration - _shakeElapsed;
      if (remaining <= 0) {
        _onAfterShockEnd();
      } else {
        final intensity =
            (_shakeAmplitude * remaining / _shakeDuration).clamp(0.0, _shakeAmplitude);
        _bgContainer.position = Vector2(
          sin(_shakeElapsed * 25) * intensity,
          cos(_shakeElapsed * 20) * intensity * 0.5,
        );
        // After grace period: if not ducking, the character falls
        if (!isDucking && _shakeElapsed > _afterShockGrace) {
          _triggerFall();
        }
      }
    }

    // Detect fall animation finishing
    if (_phase == _Phase.falling &&
        _fallAnimComp.isMounted &&
        (_fallAnimComp.animationTicker?.done() ?? false)) {
      _onFallComplete();
    }
  }
}

// ─── Instructions overlay ─────────────────────────────────────────────────────

Widget instructionsLvl3OverlayBuilder(
  BuildContext context,
  SafetyStepsGame game,
) {
  return _InstructionsOverlay(game: game);
}

class _InstructionsOverlay extends StatefulWidget {
  final SafetyStepsGame game;
  const _InstructionsOverlay({required this.game});

  @override
  State<_InstructionsOverlay> createState() => _InstructionsOverlayState();
}

class _InstructionsOverlayState extends State<_InstructionsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    final world = widget.game.cam.world as EarthquakeLvl3Puzzle?;
    world?.startGame();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2A3A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFA500),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Orange accent bar
                      Container(height: 6, color: const Color(0xFFFFA500)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '⚠️ Warning',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFA500),
                                fontFamily: 'Comic Relief',
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Be careful of aftershocks!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Comic Relief',
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Stop and cover while the ground is shaking.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFFCCCCCC),
                                fontFamily: 'Comic Relief',
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Tap to begin',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── HUD overlay (lives + duck button) ───────────────────────────────────────

Widget hudLvl3OverlayBuilder(BuildContext context, SafetyStepsGame game) {
  final world = game.cam.world as EarthquakeLvl3Puzzle?;
  if (world == null) return const SizedBox.shrink();
  return _HudOverlay(world: world);
}

class _HudOverlay extends StatelessWidget {
  final EarthquakeLvl3Puzzle world;
  const _HudOverlay({required this.world});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        // ── Lives (top-left) ─────────────────────────────────────────────────
        Positioned(
          top: 16,
          left: 16,
          child: ValueListenableBuilder<int>(
            valueListenable: world.livesNotifier,
            builder: (_, lives, _) {
              return Row(
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      i < lives ? Icons.favorite : Icons.favorite_border,
                      color: i < lives ? Colors.red : Colors.grey.shade400,
                      size: 40,
                      shadows: const [
                        Shadow(color: Colors.black38, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Duck button (bottom-center) ───────────────────────────────────────
        Align(
          alignment: const Alignment(0, 0.88),
          child: Listener(
            onPointerDown: (_) => world.setDucking(true),
            onPointerUp: (_) => world.setDucking(false),
            onPointerCancel: (_) => world.setDucking(false),
            child: Image.asset(
              'assets/images/earthquake/buttons/dropCoverBtn.png',
              height: screenH * 0.18,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Game Over overlay ────────────────────────────────────────────────────────

Widget gameOverLvl3OverlayBuilder(BuildContext context, SafetyStepsGame game) {
  return _GameOverOverlay(game: game);
}

class _GameOverOverlay extends StatelessWidget {
  final SafetyStepsGame game;
  const _GameOverOverlay({required this.game});

  void _onTap() {
    game.router.pop(); // pop game over overlay
    game.router.pushReplacementNamed('level_select');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/earthquake/backgrounds/GameOver.png',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Align(
          alignment: const Alignment(0, 0.88),
          child: Text(
            'Tap to return to main menu',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Comic Relief',
              color: Colors.white.withValues(alpha: 0.85),
              shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Victory overlay ──────────────────────────────────────────────────────────

Widget victoryLvl3OverlayBuilder(BuildContext context, SafetyStepsGame game) {
  return _VictoryOverlay(game: game);
}

class _VictoryOverlay extends StatelessWidget {
  final SafetyStepsGame game;
  const _VictoryOverlay({required this.game});

  void _onTap() {
    game.router.pop(); // pop victory overlay
    game.router.pushReplacementNamed('level_select');
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/earthquake/backgrounds/Congratulations.png',
                  width: screenW * 0.5,
                  height: screenH * 0.55,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tap to return to level selection',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Comic Relief',
                  color: Colors.white.withValues(alpha: 0.85),
                  shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
