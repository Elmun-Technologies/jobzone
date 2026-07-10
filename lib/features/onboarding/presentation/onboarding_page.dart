import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/providers/app_flags.dart';
import 'widgets/onboarding_art.dart';

class _Slide {
  const _Slide(this.title, this.body);
  final String title;
  final String body;
}

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(appFlagsProvider.notifier).markOnboardingSeen();
    // Next stop is the first-run language picker; the router guard also
    // enforces this hop, so a returning user who already chose skips it.
    if (mounted) context.go(Routes.chooseLanguage);
  }

  void _next(bool isLast) {
    if (isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final slides = [
      _Slide(l.onboard1Title, l.onboard1Body),
      _Slide(l.onboard2Title, l.onboard2Body),
      _Slide(l.onboard3Title, l.onboard3Body),
    ];
    final isLast = _index == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: TextButton(
                    onPressed: isLast ? null : _finish,
                    child: Text(
                      l.skip,
                      style: context.text.titleMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final s = slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        Expanded(
                          flex: 9,
                          child: _Parallax(
                            controller: _controller,
                            page: i,
                            child: OnboardingArt(i),
                          ),
                        ),
                        const Spacer(),
                        HighlightText(
                          s.title,
                          textAlign: TextAlign.center,
                          highlightColor: colors.primary,
                          style: context.text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          s.body,
                          style: context.text.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                children: [
                  _Dots(count: slides.length, index: _index),
                  const SizedBox(height: AppSpacing.xl),
                  JzPrimaryButton(
                    label: isLast ? l.getStarted : l.continueLabel,
                    icon: isLast ? null : Icons.arrow_forward_rounded,
                    onPressed: () => _next(isLast),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gives the hero art a subtle horizontal drift as the pager scrolls, for depth.
class _Parallax extends StatelessWidget {
  const _Parallax({
    required this.controller,
    required this.page,
    required this.child,
  });
  final PageController controller;
  final int page;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double delta = 0;
        if (controller.hasClients && controller.position.haveDimensions) {
          delta = (controller.page ?? page.toDouble()) - page;
        }
        return Transform.translate(
          offset: Offset(-delta * 60, 0),
          child: Opacity(
            opacity: (1 - delta.abs()).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 9,
          width: active ? 26 : 9,
          decoration: BoxDecoration(
            color: active
                ? colors.primary
                : colors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        );
      }),
    );
  }
}
