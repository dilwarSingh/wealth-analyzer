import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/contracts/ai_portfolio_contract.dart';
import '../viewmodels/ai_session_viewmodel.dart';

class AISessionDrawer extends ConsumerWidget {
  final AIThemeData theme;
  final VoidCallback? onSessionSelected;
  final ValueChanged<String>? onNewSessionCreated;

  const AISessionDrawer({
    super.key,
    required this.theme,
    this.onSessionSelected,
    this.onNewSessionCreated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(aiSessionProvider);
    final sessions = sessionState.sessions;
    final activeId = sessionState.activeSessionId;

    return Container(
      width: 280,
      color: theme.surfaceColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.forum_rounded, color: theme.secondaryAccentColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Chat Threads',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.add_rounded, color: theme.secondaryAccentColor, size: 22),
                    tooltip: 'New Chat Thread',
                    onPressed: () async {
                      final newSession = await ref.read(aiSessionProvider.notifier).createNewSession();
                      if (onSessionSelected != null) onSessionSelected!();
                      if (onNewSessionCreated != null) onNewSessionCreated!(newSession.id);
                    },
                  ),
                ],
              ),
            ),
            Divider(color: theme.borderColor.withOpacity(0.2), height: 1),

            // Session List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sessions.length,
                itemBuilder: (ctx, i) {
                  final s = sessions[i];
                  final isActive = s.id == activeId;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: InkWell(
                      onTap: () {
                        ref.read(aiSessionProvider.notifier).selectSession(s.id);
                        if (onSessionSelected != null) onSessionSelected!();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? theme.surfaceLightColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isActive
                              ? Border.all(color: theme.secondaryAccentColor.withOpacity(0.4))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 15,
                              color: isActive ? theme.secondaryAccentColor : theme.textSecondaryColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.title,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                  color: isActive ? theme.textPrimaryColor : theme.textSecondaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (sessions.length > 1)
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded, size: 14, color: theme.textMutedColor),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                onPressed: () {
                                  ref.read(aiSessionProvider.notifier).deleteSession(s.id);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
