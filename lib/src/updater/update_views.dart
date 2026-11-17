import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/widgets.dart';
import 'github.dart';
import 'updater.dart';

/// Shows nothing unless there is something to say about an update. Put it at the top of the first tab.
class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key, this.showUpToDate = false, this.padding = const EdgeInsets.only(bottom: Gap.md)});

  /// Show the "latest version" and checking states too (used in Settings).
  final bool showUpToDate;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final updater = BasaltUpdater.instance;
    return ListenableBuilder(
      listenable: updater,
      builder: (context, _) {
        final s = updater.state;
        final p = context.basalt;
        Widget? body;
        Color? border;
        switch (s.phase) {
          case UpdatePhase.idle:
            body = null;
          case UpdatePhase.checking:
            if (showUpToDate) {
              body = _row(context, null, 'Checking for updates…', p.textMuted, busy: true);
            }
          case UpdatePhase.upToDate:
            if (showUpToDate) {
              body = _row(context, Icons.check_circle_rounded, "You're on the latest version (${updater.currentVersion})", p.success);
            }
          case UpdatePhase.error:
            body = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _row(context, Icons.error_outline_rounded, 'Update problem', p.danger),
                const SizedBox(height: Gap.sm),
                Text(s.message ?? 'Something went wrong.', style: BasaltType.body.copyWith(color: p.textMuted, fontSize: 14)),
                const SizedBox(height: Gap.md),
                Row(
                  children: [
                    if (s.update != null) ...[
                      Expanded(child: BButton(label: 'Retry', onPressed: updater.download, expand: true)),
                      const SizedBox(width: Gap.sm),
                    ],
                    Expanded(child: BButton(label: 'Dismiss', variant: BButtonVariant.secondary, onPressed: updater.dismiss, expand: true)),
                  ],
                ),
              ],
            );
          case UpdatePhase.available || UpdatePhase.downloading || UpdatePhase.ready:
            final u = s.update!;
            border = p.accent;
            body = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _row(context, Icons.auto_awesome_rounded, 'Version ${u.version} is available', p.accent),
                const SizedBox(height: Gap.xs),
                Text(
                  'You have ${updater.currentVersion} · ${formatBytes(u.sizeBytes)}',
                  style: BasaltType.caption.copyWith(color: p.textMuted),
                ),
                if (u.notes.isNotEmpty) ...[
                  const SizedBox(height: Gap.sm),
                  Text(_cleanNotes(u.notes), maxLines: 6, overflow: TextOverflow.ellipsis, style: BasaltType.body.copyWith(color: p.textMuted, fontSize: 14)),
                ],
                const SizedBox(height: Gap.md),
                if (s.phase == UpdatePhase.downloading) ...[
                  BProgressBar(value: s.progress),
                  Row(
                    children: [
                      Expanded(child: Text('Downloading… ${(s.progress * 100).round()}%', style: BasaltType.caption.copyWith(color: p.textMuted))),
                      BButton(label: 'Cancel', variant: BButtonVariant.ghost, onPressed: updater.cancel),
                    ],
                  ),
                ] else if (s.phase == UpdatePhase.ready) ...[
                  if (s.needsPermission)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.sm),
                      child: Text(
                        'Allow this app to install updates in the screen that opened, then come back and tap Install.',
                        style: BasaltType.caption.copyWith(color: p.warning),
                      ),
                    ),
                  BButton(label: 'Install update', icon: Icons.download_rounded, onPressed: updater.install, expand: true),
                ] else
                  Row(
                    children: [
                      Expanded(child: BButton(label: 'Update', icon: Icons.download_rounded, onPressed: updater.download, expand: true)),
                      const SizedBox(width: Gap.sm),
                      Expanded(child: BButton(label: 'Skip', variant: BButtonVariant.secondary, onPressed: updater.skip, expand: true)),
                    ],
                  ),
              ],
            );
        }
        if (body == null) return const SizedBox.shrink();
        return Padding(padding: padding, child: BCard(borderColor: border, child: body));
      },
    );
  }

  static String _cleanNotes(String notes) => notes
      .replaceAll(RegExp(r'\*\*Full Changelog\*\*.*', dotAll: true), '')
      .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
      .trim();

  Widget _row(BuildContext context, IconData? icon, String text, Color color, {bool busy = false}) {
    final p = context.basalt;
    return Row(
      children: [
        if (busy)
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color))
        else
          Icon(icon, size: 18, color: color),
        const SizedBox(width: Gap.sm),
        Expanded(child: Text(text, style: BasaltType.bodyStrong.copyWith(color: p.text))),
      ],
    );
  }
}

/// Settings block: current version, a "Check for updates" row and the status card.
class UpdatesSection extends StatelessWidget {
  const UpdatesSection({super.key, this.title = 'Updates'});

  final String title;

  @override
  Widget build(BuildContext context) {
    final updater = BasaltUpdater.instance;
    return ListenableBuilder(
      listenable: updater,
      builder: (context, _) {
        final p = context.basalt;
        final checking = updater.state.phase == UpdatePhase.checking;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            BGroup(
              title: title,
              children: [
                BListRow(
                  icon: Icons.system_update_rounded,
                  title: 'Check for updates',
                  subtitle: 'Version ${updater.currentVersion.isEmpty ? '—' : updater.currentVersion} · checks each time the app opens',
                  trailing: checking
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: p.accent))
                      : Text('Check', style: BasaltType.label.copyWith(color: p.accent)),
                  onTap: checking ? null : () => updater.check(),
                ),
                BListRow(
                  icon: Icons.open_in_new_rounded,
                  title: 'Release notes',
                  subtitle: 'All versions on GitHub',
                  chevron: true,
                  onTap: updater.openReleasesPage,
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            const UpdateCard(showUpToDate: true, padding: EdgeInsets.zero),
          ],
        );
      },
    );
  }
}
