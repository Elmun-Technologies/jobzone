import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../localization/l10n_extension.dart';

/// Onboarding hero scenes — instead of generic clip-art, each slide stages a
/// little slice of the *real product* (browse cards, the jobs map, chat +
/// apply) drawn with Flutter widgets in the Yolla palette, with staggered
/// entrance motion. Shows value at a glance and reads as intentional.
///
/// Each scene is authored at a fixed 320×320 design size and scaled to the
/// slide by a [FittedBox] in the caller, so it never overflows.
class OnboardingArt extends StatelessWidget {
  const OnboardingArt(this.index, {super.key});
  final int index;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 320,
        height: 320,
        child: switch (index) {
          0 => const _JobsScene(),
          1 => const _MapScene(),
          _ => const _ChatScene(),
        },
      ),
    );
  }
}

// ── shared panel ─────────────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(40),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// A soft volt disc used as a decorative backdrop accent.
class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.alpha});
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.gold.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Scene 1 — browse job cards ───────────────────────────────────────────────

class _JobsScene extends StatelessWidget {
  const _JobsScene();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Panel(
      child: Stack(
        children: [
          Positioned(top: -26, right: -20, child: _Disc(size: 120, alpha: 0.5)),
          Positioned(
            bottom: -30,
            left: -24,
            child: _Disc(size: 110, alpha: 0.3),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                JzFadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: _ChipRow(
                    labels: [
                      l.jobTitleChef,
                      l.jobTitleDriver,
                      l.jobTitleCourier,
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                JzFadeSlideIn(
                  delay: const Duration(milliseconds: 180),
                  dy: 22,
                  child: _MiniJobCard(
                    initial: 'O',
                    accent: context.colors.primary,
                    title: l.jobTitleChef,
                    subtitle: 'Yolla Cafe · ${l.cityTashkent}',
                    pay: '4 500 000',
                  ),
                ),
                const SizedBox(height: 12),
                JzFadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  dy: 26,
                  child: _MiniJobCard(
                    initial: 'H',
                    accent: context.colors.gold,
                    title: l.jobTitleDriver,
                    subtitle: 'Express · ${l.citySamarkand}',
                    pay: '6 000 000',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.labels});
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: i == 0 ? colors.primary : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: colors.border),
          ),
          child: Text(
            labels[i],
            style: context.text.labelMedium?.copyWith(
              color: i == 0 ? colors.onPrimary : colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniJobCard extends StatelessWidget {
  const _MiniJobCard({
    required this.initial,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.pay,
  });
  final String initial;
  final Color accent;
  final String title;
  final String subtitle;
  final String pay;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              initial,
              style: context.text.titleMedium?.copyWith(
                color: accent == colors.gold ? colors.onGold : colors.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.gold,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    "$pay so'm",
                    style: context.text.labelSmall?.copyWith(
                      color: colors.onGold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scene 2 — jobs map ───────────────────────────────────────────────────────

class _MapScene extends StatelessWidget {
  const _MapScene();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return _Panel(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Faint "street" lines to suggest a map.
          const Positioned.fill(child: _MapLines()),
          // Job pins.
          const Positioned(top: 54, left: 46, child: _Pin(label: '4.5 mln')),
          const Positioned(top: 120, right: 40, child: _Pin(label: '6 mln')),
          const Positioned(bottom: 96, left: 70, child: _Pin(label: '3 mln')),
          // "You are here" pulsing dot.
          Positioned(
            bottom: 118,
            right: 96,
            child: JzPulse(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F80ED),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 3),
                ),
              ),
            ),
          ),
          // Result count pill.
          Positioned(
            bottom: 26,
            child: JzFadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.near_me_rounded,
                      size: 16,
                      color: colors.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.vacancyCount(24),
                      style: context.text.labelLarge?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLines extends StatelessWidget {
  const _MapLines();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MapLinesPainter(context.colors.border));
  }
}

class _MapLinesPainter extends CustomPainter {
  _MapLinesPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.42),
      Offset(size.width, size.height * 0.30),
      p,
    );
    canvas.drawLine(
      Offset(size.width * 0.34, 0),
      Offset(size.width * 0.46, size.height),
      p,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, 0),
      Offset(size.width * 0.62, size.height),
      p,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.78),
      Offset(size.width, size.height * 0.86),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _MapLinesPainter old) => old.color != color;
}

class _Pin extends StatelessWidget {
  const _Pin({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return JzFadeSlideIn(
      delay: const Duration(milliseconds: 140),
      scaleFrom: 0.7,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.gold,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              label,
              style: context.text.labelMedium?.copyWith(
                color: colors.onGold,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -2),
            child: Icon(
              Icons.arrow_drop_down_rounded,
              color: colors.gold,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scene 3 — chat + apply ───────────────────────────────────────────────────

class _ChatScene extends StatelessWidget {
  const _ChatScene();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _Panel(
      child: Stack(
        children: [
          Positioned(top: -24, left: -18, child: _Disc(size: 110, alpha: 0.4)),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                JzFadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: _Bubble(
                    text: 'Assalomu alaykum! Ertaga suhbatga kelasizmi?',
                    incoming: true,
                  ),
                ),
                const SizedBox(height: 10),
                JzFadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: _Bubble(text: 'Albatta, rahmat! 🙌', incoming: false),
                ),
                const SizedBox(height: 18),
                JzFadeSlideIn(
                  delay: const Duration(milliseconds: 340),
                  dy: 22,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.success.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: colors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Arizangiz qabul qilindi',
                                style: context.text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Suhbatga taklif etildingiz',
                                style: context.text.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.incoming});
  final String text;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(incoming ? 4 : 18),
      bottomRight: Radius.circular(incoming ? 18 : 4),
    );
    return Align(
      alignment: incoming ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: incoming ? colors.surface : colors.primary,
          borderRadius: radius,
          border: incoming ? Border.all(color: colors.border) : null,
        ),
        child: Text(
          text,
          style: context.text.bodyMedium?.copyWith(
            color: incoming ? colors.textPrimary : colors.onPrimary,
          ),
        ),
      ),
    );
  }
}
