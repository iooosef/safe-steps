import 'package:flutter/material.dart';
import 'package:safesteps/tutorial_state.dart';

/// Flutter overlay widget for the dialogue box.
/// Renders on top of the Flame canvas, making rich text styling easy.
class DialogueOverlay extends StatelessWidget {
  final DialogueLine line;
  final VoidCallback onTap;

  const DialogueOverlay({
    super.key,
    required this.line,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speaker label
              Text(
                line.isMonologue ? '(${line.speaker})' : line.speaker,
                style: TextStyle(
                  fontFamily: 'Cherry Bomb One',
                  fontSize: 14,
                  color: line.isMonologue
                      ? Colors.grey.shade400
                      : const Color(0xFF00A5FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              // Dialogue text with optional yellow highlights
              _buildDialogueText(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to continue ▶',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogueText() {
    if (line.highlights.isEmpty) {
      return Text(
        line.text,
        style: const TextStyle(
          fontFamily: 'Cherry Bomb One',
          fontSize: 18,
          color: Colors.white,
          height: 1.4,
        ),
      );
    }

    // Build rich text with highlighted segments
    final spans = <InlineSpan>[];
    int cursor = 0;
    for (final (start, end) in line.highlights) {
      if (cursor < start) {
        spans.add(TextSpan(text: line.text.substring(cursor, start)));
      }
      spans.add(
        TextSpan(
          text: line.text.substring(start, end),
          style: const TextStyle(
            color: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      cursor = end;
    }
    if (cursor < line.text.length) {
      spans.add(TextSpan(text: line.text.substring(cursor)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Cherry Bomb One',
          fontSize: 18,
          color: Colors.white,
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }
}

/// Overlay shown during the puzzle phase with mistake feedback.
class MistakeFeedbackOverlay extends StatelessWidget {
  final String teacherLine;
  final String playerLine;
  final VoidCallback onTap;

  const MistakeFeedbackOverlay({
    super.key,
    required this.teacherLine,
    required this.playerLine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.redAccent, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Teacher',
                style: TextStyle(
                  fontFamily: 'Cherry Bomb One',
                  fontSize: 14,
                  color: Color(0xFF00A5FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                teacherLine,
                style: const TextStyle(
                  fontFamily: 'Cherry Bomb One',
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '(You)',
                style: TextStyle(
                  fontFamily: 'Cherry Bomb One',
                  fontSize: 14,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                playerLine,
                style: const TextStyle(
                  fontFamily: 'Cherry Bomb One',
                  fontSize: 16,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to retry ▶',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Success overlay shown when puzzle is solved.
class SuccessOverlay extends StatelessWidget {
  final String message;
  final VoidCallback onTap;

  const SuccessOverlay({
    super.key,
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.greenAccent, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Teacher',
                style: TextStyle(
                  fontFamily: 'Cherry Bomb One',
                  fontSize: 14,
                  color: Color(0xFF00A5FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Cherry Bomb One',
                  fontSize: 18,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to continue ▶',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Game Over overlay.
class GameOverOverlay extends StatelessWidget {
  final VoidCallback onRetry;

  const GameOverOverlay({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Game Over',
              style: TextStyle(
                fontFamily: 'Cherry Bomb One',
                fontSize: 36,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You ran out of chances.\nLet\'s study the safety steps again!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cherry Bomb One',
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A5FF),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontFamily: 'Cherry Bomb One',
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hint overlay showing the correct order step by step.
class HintOverlay extends StatelessWidget {
  const HintOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.yellow, width: 1),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '💡 Hint: Correct order',
              style: TextStyle(
                fontFamily: 'Cherry Bomb One',
                fontSize: 12,
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text('1. Drop', style: TextStyle(fontSize: 12, color: Colors.white)),
            Text('2. Cover under desk',
                style: TextStyle(fontSize: 12, color: Colors.white)),
            Text('3. Hold the table',
                style: TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Minigame-specific full-screen overlays (Success & Game Over).
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen success overlay for the earthquake minigame.
class GameSuccessOverlay extends StatelessWidget {
  final VoidCallback onBackToLevels;

  const GameSuccessOverlay({super.key, required this.onBackToLevels});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/Congratulations.png',
            width: 320,
          ),
          const SizedBox(height: 16),
          const Text(
            'You remembered the safety steps!\nDrop, Cover, and Hold!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cherry Bomb One',
              fontSize: 16,
              color: Colors.white70,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onBackToLevels,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A5FF),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to Levels',
              style: TextStyle(
                fontFamily: 'Cherry Bomb One',
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen game over overlay for the earthquake minigame.
class GameFailureOverlay extends StatelessWidget {
  final VoidCallback onPlayAgain;

  const GameFailureOverlay({super.key, required this.onPlayAgain});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/GameOver.png',
            width: 320,
          ),
          const SizedBox(height: 16),
          const Text(
            'You ran out of chances.\nLet\'s study the safety steps again!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cherry Bomb One',
              fontSize: 16,
              color: Colors.white70,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onPlayAgain,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A5FF),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Play Again',
              style: TextStyle(
                fontFamily: 'Cherry Bomb One',
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
