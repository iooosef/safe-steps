import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:safesteps/components/speech_bubble.dart';
import 'package:safesteps/safetysteps_game.dart';

// ─── EarthquakeLvl2Puzzle ─────────────────────────────────────────────────────

class EarthquakeLvl2Puzzle extends World
    with HasGameReference<SafetyStepsGame> {
  late Vector2 levelSize;
  SpeechBubble? _speechBubble;

  @override
  Future<void> onLoad() async {
    game.setWorld(this);
    levelSize = game.size;

    // Static post-earthquake background — no shaking
    final background = SpriteComponent()
      ..sprite = await game.loadSprite(
        'earthquake/backgrounds/ClassroomDestroyed.png',
      )
      ..size = levelSize
      ..position = Vector2.zero()
      ..anchor = Anchor.topLeft;
    add(background);

    // Worried student, standing still
    final studentSprite = SpriteComponent()
      ..sprite = await game.loadSprite('earthquake/characters/Worried.png')
      ..anchor = Anchor.bottomLeft;
    studentSprite
      ..position = Vector2(0, levelSize.y * 1.25)
      ..size = Vector2(
        levelSize.y * (studentSprite.size.x / studentSprite.size.y),
        levelSize.y,
      );
    add(studentSprite);

    _runDialogue();
  }

  Future<void> _runDialogue() async {
    await Future.delayed(const Duration(milliseconds: 600));

    _speechBubble = SpeechBubble(
      text: 'The earthquake stopped.',
      tail: BubbleTail.left,
      tailDirection: BubbleTailDirection.right,
      padding: 16,
      radius: 24,
      tailSize: 30,
      maxBubbleWidth: levelSize.x * 0.35,
    )
      ..anchor = Anchor.topLeft
      ..position = Vector2(25, 25);
    add(_speechBubble!);

    await Future.delayed(const Duration(seconds: 2));
    _speechBubble!.updateText('What do I do next?');

    await Future.delayed(const Duration(milliseconds: 1800));
    game.router.pushOverlay('earthquake_level_2_choice');
  }
}

// ─── Overlay: Two-choice buttons ─────────────────────────────────────────────

Widget choiceLvl2OverlayBuilder(BuildContext context, SafetyStepsGame game) {
  return _ChoiceOverlay(game: game);
}

class _ChoiceOverlay extends StatelessWidget {
  final SafetyStepsGame game;
  const _ChoiceOverlay({required this.game});

  void _onWrong() {
    game.router.pop(); // pop choice overlay
    game.router.pushOverlay('earthquake_level_2_wrong_feedback');
  }

  void _onCorrect() {
    game.router.pop(); // pop choice overlay
    game.router.pushOverlay('earthquake_level_2_correct_feedback');
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final btnSize = screenH * 0.38;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'What will you do?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: 'Comic Relief',
              ),
            ),
            SizedBox(height: screenH * 0.04),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Wrong choice — Wait
                _ChoiceButton(
                  imagePath: 'assets/images/fire/Wait1.png',
                  label: 'Wait',
                  size: btnSize,
                  onTap: _onWrong,
                  borderColor: const Color(0xFFE05C5C),
                ),
                SizedBox(width: screenW * 0.06),
                // Correct choice — Leave the Building
                _ChoiceButton(
                  imagePath:
                      'assets/images/earthquake/buttons/LTB(Unselected).png',
                  label: 'Leave the Building',
                  size: btnSize,
                  onTap: _onCorrect,
                  borderColor: const Color(0xFF5CCB7A),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String imagePath;
  final String label;
  final double size;
  final VoidCallback onTap;
  final Color borderColor;

  const _ChoiceButton({
    required this.imagePath,
    required this.label,
    required this.size,
    required this.onTap,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 4),
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Comic Relief',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Overlay: Wrong feedback card ────────────────────────────────────────────

Widget wrongFeedbackLvl2OverlayBuilder(
  BuildContext context,
  SafetyStepsGame game,
) {
  return _WrongFeedbackOverlay(game: game);
}

class _WrongFeedbackOverlay extends StatefulWidget {
  final SafetyStepsGame game;
  const _WrongFeedbackOverlay({required this.game});

  @override
  State<_WrongFeedbackOverlay> createState() => _WrongFeedbackOverlayState();
}

class _WrongFeedbackOverlayState extends State<_WrongFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDismiss() {
    widget.game.router.pop(); // pop wrong feedback overlay
    while (widget.game.router.canPop()) {
      widget.game.router.pop();
    }
    widget.game.router.pushNamed('earthquake_level_2_puzzle');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onDismiss,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
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
                      Container(height: 6, color: const Color(0xFFE05C5C)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '❌ Wrong Choice!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB03030),
                                fontFamily: 'Comic Relief',
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Don't stay in the room after an earthquake!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                color: Color(0xFF444444),
                                fontFamily: 'Comic Relief',
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Tap to try again',
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

// ─── Overlay: Correct feedback card ──────────────────────────────────────────

Widget correctFeedbackLvl2OverlayBuilder(
  BuildContext context,
  SafetyStepsGame game,
) {
  return _CorrectFeedbackOverlay(game: game);
}

class _CorrectFeedbackOverlay extends StatefulWidget {
  final SafetyStepsGame game;
  const _CorrectFeedbackOverlay({required this.game});

  @override
  State<_CorrectFeedbackOverlay> createState() =>
      _CorrectFeedbackOverlayState();
}

class _CorrectFeedbackOverlayState extends State<_CorrectFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDismiss() {
    widget.game.router.pop(); // pop feedback overlay
    while (widget.game.router.canPop()) {
      widget.game.router.pop();
    }
    widget.game.router.pushNamed('earthquake_level_3_puzzle');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onDismiss,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
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
                      Container(height: 6, color: const Color(0xFF5CCB7A)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '🎉 Correct Choice! 🎉',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2A7A46),
                                fontFamily: 'Comic Relief',
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'After an earthquake, leave the building safely!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                color: Color(0xFF444444),
                                fontFamily: 'Comic Relief',
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Tap to continue',
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
