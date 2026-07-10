import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../design_system/design_system.dart';
import '../../../localization/l10n_extension.dart';
import '../../../shared/providers/app_flags.dart';

class _Slide {
  const _Slide(this.title, this.body, this.art);
  final String title;
  final String body;

  /// On-brand illustration for the slide. A raster photo can be dropped in
  /// later by swapping the asset here (see [_OnboardingArt]).
  final String art;
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final slides = [
      _Slide(l.onboard1Title, l.onboard1Body, 'assets/onboarding/step_1.svg'),
      _Slide(l.onboard2Title, l.onboard2Body, 'assets/onboarding/step_2.svg'),
      _Slide(l.onboard3Title, l.onboard3Body, 'assets/onboarding/step_3.svg'),
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
                        color: colors.primary,
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
                        Expanded(flex: 8, child: _OnboardingArt(s.art)),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_index > 0)
                    _NavButton(
                      icon: Icons.arrow_back_rounded,
                      filled: false,
                      onTap: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                    )
                  else
                    const SizedBox(width: 56),
                  _Dots(count: slides.length, index: _index),
                  _NavButton(
                    icon: Icons.arrow_forward_rounded,
                    filled: true,
                    onTap: () => _next(isLast),
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

/// The per-slide illustration. Ships a brand-matched SVG (ink line-art + volt
/// accents on a soft self-framed panel, so it reads on both light and dark
/// app backgrounds). To use a photo instead, point [asset] at a bundled raster
/// (`assets/onboarding/*.png`) — [JzSvgAsset] handles SVGs; swap to
/// `Image.asset` here if you move to raster art.
class _OnboardingArt extends StatelessWidget {
  const _OnboardingArt(this.asset);
  final String asset;

  @override
  Widget build(BuildContext context) {
    // Fixed intrinsic size scaled to the slide via FittedBox, so it never
    // overflows on small screens (matches the old device-frame sizing).
    return FittedBox(
      fit: BoxFit.contain,
      child: JzSvgAsset(asset, width: 320, height: 300),
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.filled,
    required this.onTap,
  });
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: filled ? colors.primary : colors.surface,
      shape: CircleBorder(
        side: filled ? BorderSide.none : BorderSide(color: colors.border),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: filled ? colors.onPrimary : colors.primary),
        ),
      ),
    );
  }
}
