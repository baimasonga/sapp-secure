import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design/app_typography.dart';
import '../../app/design/design_tokens.dart';
import '../../core/widgets/ds_components.dart';
import '../application/moderation_controllers.dart';
import '../domain/moderation_models.dart';
import 'moderation_strings.dart';

/// Remote detection rules.
///
/// Two honesty notes are built into this page. First, rule changes are
/// administrator-only, and a moderator is told that rather than shown controls
/// that fail. Second, the phone app ships its own rules and does not read
/// these yet — so the page says a change here currently affects nothing,
/// instead of implying detection just improved.
class RulesPage extends ConsumerWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(rulesProvider);
    final role = ref.watch(currentRoleProvider).valueOrNull;
    final canEdit = role?.canManageRules ?? false;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DsSpace.x6,
            DsSpace.x6,
            DsSpace.x6,
            DsSpace.x2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Mod.rulesTitle,
                style: AppType.headline.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: DsSpace.x1),
              Text(
                Mod.rulesBody,
                style: AppType.caption.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (!canEdit) ...[
                const SizedBox(height: DsSpace.x4),
                const DsNotice(
                  icon: Icons.lock_outline,
                  text: Mod.rulesAdminOnly,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: rules.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(DsSpace.x6),
              child: DsNotice(
                icon: Icons.cloud_off_outlined,
                tone: DsNoticeTone.danger,
                text: Mod.queueLoadFailed,
              ),
            ),
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(DsSpace.x6),
                    child: DsNotice(icon: Icons.rule, text: Mod.rulesEmpty),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      DsSpace.x6,
                      DsSpace.x2,
                      DsSpace.x6,
                      DsSpace.x8,
                    ),
                    children: [
                      DsListGroup(
                        children: [
                          for (final rule in list)
                            _RuleRow(rule: rule, canEdit: canEdit),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _RuleRow extends ConsumerWidget {
  const _RuleRow({required this.rule, required this.canEdit});

  final RemoteRule rule;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      value: rule.enabled,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DsSpace.x4,
        vertical: DsSpace.x1,
      ),
      title: Text(
        rule.ruleCode,
        style: AppType.mono.copyWith(fontSize: 14, color: scheme.onSurface),
      ),
      subtitle: Text(
        '${rule.category} · ${Mod.ruleWeight} ${rule.weight} · '
        '${Mod.ruleFloor} ${rule.escalationFloor} · '
        '${rule.patternCount} ${Mod.rulePatterns.toLowerCase()}',
        style: AppType.caption.copyWith(color: scheme.onSurfaceVariant),
      ),
      onChanged: canEdit
          ? (value) async {
              await ref
                  .read(moderationGatewayProvider)
                  .setRuleEnabled(ruleId: rule.id, enabled: value);
              ref.invalidate(rulesProvider);
            }
          : null,
    );
  }
}
