import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/components/speech_bubble.dart';
import 'package:safesteps/safetysteps_game.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const double kBoxSize = 100.0;
const double kContainerSize = 105.0;
const double kSnapRadius = 60.0;
const double kAnimDuration = 0.25;

final List<Color> kBoxColors = [
  const Color(0xFFE05C5C),
  const Color(0xFF5C9BE0),
  const Color(0xFF5CCB7A),
];
const List<Map<String, String>> kBoxData = [
  {'label': 'Cover', 'sprite': 'earthquake/buttons/Cover(Unselected).png'},
  {'label': 'Duck', 'sprite': 'earthquake/buttons/Duck(Unselected).png'},
  {'label': 'Hold', 'sprite': 'earthquake/buttons/Hold(Unselected).png'},
];
final List<String> kCorrectOrder = ['Duck', 'Cover', 'Hold'];

// ─── EarthquakeLvl1Puzzle ─────────────────────────────────────────────

class EarthquakeLvl1Puzzle extends World
    with HasGameReference<SafetyStepsGame> {
  late Vector2 levelSize;

  late List<BoxSprite> boxes;
  late List<ContainerSlot> slots;

  bool lastResultCorrect = false;
  List<String?> lastResult = [null, null, null];

  SpriteComponent studentSprite = SpriteComponent();
  int lives = 3;

  @override
  Future<void> onLoad() async {
    game.setWorld(this);
    levelSize = game.size;

    if (game.tutorialModeEarthquake) {
      // background
      SpriteComponent background = SpriteComponent()
        ..sprite = await game.loadSprite(
          'earthquake/backgrounds/NormalDark.png',
        )
        ..size = levelSize
        ..position = Vector2(0, 0)
        ..anchor = Anchor.topLeft;
      add(background);

      // student
      studentSprite = SpriteComponent()
        ..sprite = await game.loadSprite('earthquake/characters/Normal.png')
        ..anchor = Anchor.bottomRight;
      studentSprite
        ..position = Vector2(levelSize.x, levelSize.y * 1.25)
        ..size = Vector2(
          levelSize.y * (studentSprite.size.x / studentSprite.size.y),
          levelSize.y,
        );
      add(studentSprite);
    } else {
      final Sprite earthquakeBackground = await game.loadSprite(
        'earthquake/backgrounds/Eall_downscaled.png',
      );
      final Vector2 bgSize = earthquakeBackground.srcSize;
      final SpriteAnimationComponent earthquakingBackground =
          SpriteAnimationComponent()
            ..animation = SpriteAnimation.fromFrameData(
              earthquakeBackground.image,
              SpriteAnimationData.sequenced(
                amount: 3,
                stepTime: 0.5,
                textureSize: Vector2(bgSize.x / 3, bgSize.y),
              ),
            )
            ..anchor = Anchor.topLeft;

      earthquakingBackground.size = Vector2(
        game.size.x,
        game.size.x * (bgSize.y / (bgSize.x / 3)),
      );
      earthquakingBackground!.add(
        MoveEffect.by(
          Vector2(6, 3),
          InfiniteEffectController(ZigzagEffectController(period: 0.2)),
        ),
      );
      add(earthquakingBackground);

      // student
      studentSprite = SpriteComponent()
        ..sprite = await game.loadSprite('earthquake/characters/Worried.png')
        ..anchor = Anchor.bottomLeft;
      studentSprite
        ..position = Vector2(0, levelSize.y * 1.25)
        ..size = Vector2(
          levelSize.y * (studentSprite.size.x / studentSprite.size.y),
          levelSize.y,
        );
      studentSprite!.add(
        MoveEffect.by(
          Vector2(-6, -3),
          InfiniteEffectController(ZigzagEffectController(period: 0.4)),
        ),
      );
      add(studentSprite);

      SpeechBubble speechBubble = SpeechBubble(
        text: 'There\'s an earthquake! What should I do?',
        tail: BubbleTail.left,
        tailDirection: BubbleTailDirection.right,
        padding: 16,
        radius: 24,
        tailSize: 30,
        maxBubbleWidth: game.size.x * 0.3,
      );
      speechBubble
        ..anchor = Anchor.topLeft
        ..position = Vector2(25, 25);
      add(speechBubble);
    }

    final slotY = levelSize.y * 0.5;
    final totalSlotWidth = 3 * kContainerSize + 2 * 24.0;
    final slotStartX = (levelSize.x - totalSlotWidth) / 2;

    slots = List.generate(3, (i) {
      final slot = ContainerSlot(
        index: i,
        position: Vector2(slotStartX + i * (kContainerSize + 24), slotY),
      );
      add(slot);
      return slot;
    });

    final boxY = levelSize.y * 0.2;
    final totalBoxWidth = 3 * kBoxSize + 2 * 32.0;
    final boxStartX = (levelSize.x - totalBoxWidth) / 2;

    boxes = List.generate(kBoxData.length, (i) {
      final origin = Vector2(boxStartX + i * (kBoxSize + 32), boxY - 12);
      final box = BoxSprite(
        label: kBoxData[i]['label']!,
        spritePath: kBoxData[i]['sprite']!,
        origin: origin.clone(),
        world: this,
      )..position = origin.clone();
      box.isTutorialMode = game.tutorialModeEarthquake;
      add(box);
      return box;
    });

    game.router.pushOverlay('earthquake_level_1_puzzle_check');
  }

  Future<void> onValidate() async {
    final result = List<String?>.filled(3, null);
    for (final slot in slots) {
      if (slot.occupant != null) {
        result[slot.index] = slot.occupant!.label;
      }
    }

    lastResultCorrect =
        result[0] == kCorrectOrder[0] &&
        result[1] == kCorrectOrder[1] &&
        result[2] == kCorrectOrder[2];
    lastResult = result;

    if (!lastResultCorrect && lives > 0) {
      // Incorrect answer - lose a life and show worried/injured student
      lives--;
      debugPrint('Incorrect order! Lives remaining: $lives');
      if (game.tutorialModeEarthquake) {
        studentSprite.sprite = await game.loadSprite(
          'earthquake/characters/Worried.png',
        );
      } else {
        studentSprite.sprite = await game.loadSprite(
          'earthquake/characters/Injured.png',
        );
      }
    }
    if (!lastResultCorrect && lives == 0 && !game.tutorialModeEarthquake) {
      // Game over - show injured student and print message
      debugPrint('Game over! No lives remaining.');
      studentSprite.sprite = await game.loadSprite(
        'earthquake/characters/Bandage.png',
      );
    }

    game.router.pushOverlay('earthquake_level_1_puzzle_result');
  }

  Future<void> dismissResult() async {
    game.router.pop();
    if (game.tutorialModeEarthquake) {
      studentSprite.sprite = await game.loadSprite(
        'earthquake/characters/Normal.png',
      );
    }
    if (!lastResultCorrect && lives == 0) {
      // If game over, reset lives and return to level 1 dialog
      debugPrint('Restarting tutorial... Lives reset to 3.');
      lives = 3;
      game.skipIntroCutsceneEarthquake = true;
      game.tutorialModeEarthquake = true;
      game.router.pop();
      game.router.pushReplacementNamed('earthquake_level_1');
      debugPrint('WHY');
    }
    if (game.tutorialModeEarthquake && lastResultCorrect) {
      // If tutorial completed successfully, exit tutorial mode and go to puzzle earthquake level
      debugPrint('Tutorial completed! Moving to earthquake during cutscene...');
      game.tutorialModeEarthquake = false;
      game.router.pop();
      game.router.pushNamed('earthquake_during_cutscene');
    }
  }

  ContainerSlot? nearestSlot(Vector2 worldPos) {
    ContainerSlot? best;
    double bestDist = kSnapRadius;
    for (final slot in slots) {
      final center = slot.position + Vector2.all(kContainerSize / 2);
      final dist = worldPos.distanceTo(center);
      if (dist < bestDist) {
        bestDist = dist;
        best = slot;
      }
    }
    return best;
  }
}

// ─── Flutter Overlay Builders ─────────────────────────────────────────────────

/// "Check Order" button pinned to the bottom of the screen.
Widget checkButtonOverlayBuilder(BuildContext context, SafetyStepsGame game) {
  return Align(
    alignment: const Alignment(0, 0.82),
    child: ElevatedButton(
      onPressed: () {
        final world = game.cam.world as EarthquakeLvl1Puzzle?;
        world?.onValidate();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFA500),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Comic Relief',
          letterSpacing: 0.5,
        ),
        elevation: 4,
      ),
      child: const Text('Check Answer'),
    ),
  );
}

/// Result card overlay shown after validation.
Widget resultOverlayBuilder(BuildContext context, SafetyStepsGame game) {
  final world = game.cam.world as EarthquakeLvl1Puzzle?;

  if (world == null) return const SizedBox.shrink();

  return _ResultOverlayWidget(
    correct: world.lastResultCorrect,
    result: world.lastResult,
    lives: world.lives,
    onDismiss: world.dismissResult,
  );
}

class _ResultOverlayWidget extends StatefulWidget {
  final bool correct;
  final List<String?> result;
  final int lives;
  final VoidCallback onDismiss;

  const _ResultOverlayWidget({
    required this.correct,
    required this.result,
    required this.lives,
    required this.onDismiss,
  });

  @override
  State<_ResultOverlayWidget> createState() => _ResultOverlayWidgetState();
}

class _ResultOverlayWidgetState extends State<_ResultOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final correct = widget.correct;
    final accentColor = correct
        ? const Color(0xFF5CCB7A)
        : const Color(0xFFE05C5C);
    final titleColor = correct
        ? const Color(0xFF2A7A46)
        : const Color(0xFFB03030);
    final lives = widget.lives;
    return GestureDetector(
      onTap: widget.onDismiss,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Accent bar
                      Container(height: 6, color: accentColor),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              correct
                                  ? '🎉Correct! 🎉'
                                  : lives > 0
                                  ? 'Try Again 😔'
                                  : 'Game Over 😞',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                                fontFamily: 'Comic Relief',
                              ),
                            ),
                            const SizedBox(height: 20),

                            if (lives < 2)
                              Text(
                                lives > 0
                                    ? '💡 Hint: DUCK, COVER, and HOLD.'
                                    : 'No more chances! Study the safety steps again.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            const SizedBox(height: 20),

                            // Dismiss hint
                            Text(
                              'Tap to try again',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF555555),
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

// ─── BoxSprite ────────────────────────────────────────────────────────────────

class BoxSprite extends PositionComponent with DragCallbacks {
  final String label;
  final String spritePath;
  final Vector2 origin;
  final EarthquakeLvl1Puzzle world;

  ContainerSlot? currentSlot;

  bool _animating = false;
  Vector2 _animStart = Vector2.zero();
  Vector2 _animTarget = Vector2.zero();
  double _animT = 0;
  bool _isDragging = false;

  late SpriteComponent _spriteComponent;
  late TextComponent _labelComponent;

  static const int kDragPriority = 10;
  static const int kIdlePriority = 1;

  bool isTutorialMode = true;

  BoxSprite({
    required this.label,
    required this.spritePath,
    required this.origin,
    required this.world,
  }) : super(size: Vector2.all(kBoxSize), anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    final sprite = await Sprite.load(spritePath);
    _spriteComponent = SpriteComponent(
      sprite: sprite,
      size: Vector2.all(kBoxSize),
    );
    add(_spriteComponent);

    _labelComponent = TextComponent(
      text: label,
      textRenderer: TextPaint(
        style: TextStyle(
          color: isTutorialMode ? Colors.white : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Comic Relief',
        ),
      ),
    );
    // Layout first so we can read the size for centering
    _labelComponent.position = Vector2(
      (kBoxSize - _labelComponent.width) / 2,
      kBoxSize,
    );
    add(_labelComponent);
  }

  void _showLabel() => _labelComponent.scale = Vector2.all(1.0);
  void _hideLabel() => _labelComponent.scale = Vector2.all(0.0);

  @override
  void onDragStart(DragStartEvent event) {
    if (_animating) return;
    _isDragging = true;
    priority = kDragPriority;
    _spriteComponent.opacity = 0.85;
    _hideLabel();
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_isDragging) return;
    position += event.canvasDelta;
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!_isDragging) return;
    _isDragging = false;
    priority = kIdlePriority;
    _spriteComponent.opacity = 1.0;

    final center = position + size / 2;
    final target = world.nearestSlot(center);

    if (target != null) {
      _snapTo(target);
    } else {
      _returnToOrigin();
    }
    super.onDragEnd(event);
  }

  void _snapTo(ContainerSlot slot) {
    if (slot.occupant != null && slot.occupant != this) {
      slot.occupant!._evict();
    }
    currentSlot?.occupant = null;
    currentSlot = slot;
    slot.occupant = this;

    // Snapped to a slot — keep label hidden
    _hideLabel();
    _animateTo(slot.position + Vector2.all((kContainerSize - kBoxSize) / 2));
  }

  void _evict() {
    currentSlot?.occupant = null;
    currentSlot = null;
    _returnToOrigin();
  }

  void _returnToOrigin() {
    currentSlot?.occupant = null;
    currentSlot = null;
    // Label will be shown once animation finishes back at origin
    _animateTo(origin.clone(), returnToOrigin: true);
  }

  void _animateTo(Vector2 target, {bool returnToOrigin = false}) {
    _animStart = position.clone();
    _animTarget = target;
    _animT = 0;
    _animating = true;
    _returningToOrigin = returnToOrigin;
  }

  bool _returningToOrigin = false;

  @override
  void update(double dt) {
    super.update(dt);
    if (_animating) {
      _animT = (_animT + dt / kAnimDuration).clamp(0.0, 1.0);
      final t = 1 - (1 - _animT) * (1 - _animT) * (1 - _animT);
      position = _animStart + (_animTarget - _animStart) * t;
      if (_animT >= 1.0) {
        _animating = false;
        if (_returningToOrigin) {
          _returningToOrigin = false;
          _showLabel();
        }
      }
    }
  }
}

// ─── ContainerSlot ────────────────────────────────────────────────────────────

class ContainerSlot extends PositionComponent {
  final int index;
  BoxSprite? occupant;

  ContainerSlot({required this.index, required Vector2 position})
    : super(size: Vector2.all(kContainerSize), position: position, priority: 0);

  @override
  void render(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, kContainerSize, kContainerSize),
      const Radius.circular(14),
    );

    canvas.drawRRect(rect, Paint()..color = const Color(0xFFEEEEEE));

    _drawDashedRRect(
      canvas,
      rect,
      Paint()
        ..color = const Color(0xFFAAAAAA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: 'STEP ${index + 1}',
        style: const TextStyle(
          color: Color(0xFF000000),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Comic Relief',
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(
      canvas,
      Offset((kContainerSize - tp.width) / 2, kContainerSize - tp.height - 6),
    );
  }

  void _drawDashedRRect(
    Canvas canvas,
    RRect rrect,
    Paint paint, {
    double dashLength = 8,
    double gapLength = 5,
  }) {
    final metrics = (Path()..addRRect(rrect)).computeMetrics().first;
    double dist = 0;
    bool draw = true;
    while (dist < metrics.length) {
      final len = draw ? dashLength : gapLength;
      if (draw) canvas.drawPath(metrics.extractPath(dist, dist + len), paint);
      dist += len;
      draw = !draw;
    }
  }
}
