import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/app_typography.dart';
import '../../../app/design/design_tokens.dart';
import '../../../app/router.dart';
import '../../../core/widgets/ds_components.dart';
import '../../../l10n/app_localizations.dart';

/// Four-page onboarding (section 7.3).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<({IconData icon, String title, String body})> _pages(
    AppLocalizations l10n,
  ) => [
    (
      icon: Icons.search,
      title: l10n.onboardingTitle1,
      body: l10n.onboardingBody1,
    ),
    (
      icon: Icons.phone_in_talk_outlined,
      title: l10n.onboardingTitle2,
      body: l10n.onboardingBody2,
    ),
    (
      icon: Icons.qr_code_2_outlined,
      title: l10n.onboardingTitle3,
      body: l10n.onboardingBody3,
    ),
    (
      icon: Icons.lock_outline,
      title: l10n.onboardingTitle4,
      body: l10n.onboardingBody4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _pages(l10n);
    final isLast = _page == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => context.goNamed(AppRoute.permissions.name),
                child: Text(l10n.actionSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  final scheme = Theme.of(context).colorScheme;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DsSpace.x8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // The one gradient moment on this screen, and the
                        // same mark the app wears everywhere else.
                        const DsBrandMark(size: 64),
                        const SizedBox(height: DsSpace.x8),
                        DsIconChip(icon: page.icon, size: 72),
                        const SizedBox(height: DsSpace.x8),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: AppType.headline.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: DsSpace.x3),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: AppType.body.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < pages.length; index++)
                  AnimatedContainer(
                    duration: DsMotion.base,
                    curve: DsMotion.ease,
                    width: index == _page ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: DsSpace.x1),
                    decoration: BoxDecoration(
                      color: index == _page
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      borderRadius: DsRadius.all(DsRadius.pill),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(DsSpace.x6),
              child: FilledButton(
                onPressed: () {
                  if (isLast) {
                    context.goNamed(AppRoute.permissions.name);
                  } else {
                    _pageController.nextPage(
                      duration: DsMotion.slow,
                      curve: DsMotion.ease,
                    );
                  }
                },
                child: Text(isLast ? l10n.actionGetStarted : l10n.actionNext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
