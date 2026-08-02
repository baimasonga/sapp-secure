import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design/app_typography.dart';
import '../../app/design/design_tokens.dart';
import '../../core/widgets/ds_components.dart';
import '../application/moderation_controllers.dart';
import '../domain/moderation_models.dart';
import 'audit_log_page.dart';
import 'moderation_strings.dart';
import 'queue_page.dart';
import 'rules_page.dart';

/// The signed-in dashboard: a rail, three destinations, nothing else.
///
/// The role gate lives here rather than on each page, so a new page cannot be
/// added without it. An ordinary account is refused outright rather than shown
/// an empty queue — an empty queue reads as "no work today", which is a
/// dangerous thing to tell someone who is not supposed to be here at all.
class ModerationShell extends ConsumerStatefulWidget {
  const ModerationShell({super.key, required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  ConsumerState<ModerationShell> createState() => _ModerationShellState();
}

class _ModerationShellState extends ConsumerState<ModerationShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentRoleProvider);

    return role.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => _Refusal(
        title: Mod.queueLoadFailed,
        body: Mod.notAModeratorBody,
        onSignOut: widget.onSignOut,
      ),
      data: (value) {
        if (!value.canModerate) {
          return _Refusal(
            title: Mod.notAModeratorTitle,
            body: Mod.notAModeratorBody,
            onSignOut: widget.onSignOut,
          );
        }
        return _Dashboard(
          role: value,
          index: _index,
          onIndex: (index) => setState(() => _index = index),
          onSignOut: widget.onSignOut,
        );
      },
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.role,
    required this.index,
    required this.onIndex,
    required this.onSignOut,
  });

  final ModeratorRole role;
  final int index;
  final ValueChanged<int> onIndex;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pages = [const QueuePage(), const AuditLogPage(), const RulesPage()];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: onIndex,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: DsSpace.x5),
              child: Column(
                children: [
                  const DsBrandMark(size: 40),
                  const SizedBox(height: DsSpace.x2),
                  Text(
                    role.name,
                    style: AppType.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: DsSpace.x5),
                  child: IconButton(
                    tooltip: Mod.signOut,
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout),
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.inbox_outlined),
                selectedIcon: Icon(Icons.inbox),
                label: Text(Mod.navQueue),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text(Mod.navAudit),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.rule_outlined),
                selectedIcon: Icon(Icons.rule),
                label: Text(Mod.navRules),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[index]),
        ],
      ),
    );
  }
}

class _Refusal extends StatelessWidget {
  const _Refusal({
    required this.title,
    required this.body,
    required this.onSignOut,
  });

  final String title;
  final String body;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(DsSpace.x6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DsNotice(
                  icon: Icons.no_accounts_outlined,
                  tone: DsNoticeTone.danger,
                  title: title,
                  text: body,
                ),
                const SizedBox(height: DsSpace.x5),
                OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(Mod.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
