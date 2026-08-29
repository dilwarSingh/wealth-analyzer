import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/contracts/ai_portfolio_contract.dart';
import 'ai_glass_card.dart';

/// Glassmorphic Live Streaming & Collapsible Thought Box for AI Reasoning
class AIThoughtStreamBox extends StatefulWidget {
  final String thinkingContent;
  final bool isThinking;
  final Duration? duration;
  final AIThemeData theme;
  final bool initiallyExpanded;

  const AIThoughtStreamBox({
    super.key,
    required this.thinkingContent,
    this.isThinking = false,
    this.duration,
    required this.theme,
    this.initiallyExpanded = false,
  });

  @override
  State<AIThoughtStreamBox> createState() => _AIThoughtStreamBoxState();
}

class _AIThoughtStreamBoxState extends State<AIThoughtStreamBox> with SingleTickerProviderStateMixin {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isThinking || widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant AIThoughtStreamBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isThinking && !oldWidget.isThinking) {
      _isExpanded = true;
    } else if (!widget.isThinking && oldWidget.isThinking) {
      // Auto-collapse when thinking finishes
      _isExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.thinkingContent.isEmpty && !widget.isThinking) {
      return const SizedBox.shrink();
    }

    final theme = widget.theme;
    final durationStr = widget.duration != null
        ? '${(widget.duration!.inMilliseconds / 1000).toStringAsFixed(1)}s'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible Header Pill
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.surfaceLightColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (widget.isThinking ? theme.secondaryAccentColor : theme.borderColor).withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isThinking) ...[
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: theme.secondaryAccentColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Thinking${durationStr.isNotEmpty ? ' ($durationStr)' : ''}...',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.secondaryAccentColor,
                      ),
                    ),
                  ] else ...[
                    Text('💭', style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 5),
                    Text(
                      'Thought${durationStr.isNotEmpty ? ' for $durationStr' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: theme.textMutedColor,
                  ),
                ],
              ),
            ),
          ),

          // Expandable Body
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: AIGlassCard(
                theme: theme,
                backgroundColor: theme.surfaceColor.withOpacity(0.5),
                borderColor: theme.borderColor.withOpacity(0.25),
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  widget.thinkingContent,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    height: 1.4,
                    color: theme.textSecondaryColor.withOpacity(0.85),
                  ),
                ),
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
