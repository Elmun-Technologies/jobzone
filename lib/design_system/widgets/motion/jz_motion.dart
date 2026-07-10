/// Motion toolkit — small, reusable pieces behind the app-wide micro-
/// animations (section entrances, stat count-ups, press feedback, badge
/// pulses). All of them are short, GPU-cheap transforms/fades and every one
/// respects the OS "reduce animations" accessibility setting
/// ([MediaQuery.disableAnimationsOf]): motion collapses to the final frame.
///
/// Keep durations in the 150–500ms band and offsets subtle — the goal is a
/// lively, premium feel, never a light show.
library;

import 'package:flutter/material.dart';

/// One-shot entrance: fades the child in while sliding it up slightly (and
/// optionally scaling from [scaleFrom]). Runs once on mount after [delay] —
/// stagger siblings by passing increasing delays.
class JzFadeSlideIn extends StatefulWidget {
  const JzFadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
    this.dy = 16,
    this.scaleFrom = 1.0,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Upward travel in logical px (the child starts shifted down by this).
  final double dy;

  /// Starting scale (1.0 = no scale). E.g. 0.9 for a hero/logo pop-in.
  final double scaleFrom;

  @override
  State<JzFadeSlideIn> createState() => _JzFadeSlideInState();
}

class _JzFadeSlideInState extends State<JzFadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * widget.dy),
            child: widget.scaleFrom == 1.0
                ? child
                : Transform.scale(
                    scale: widget.scaleFrom + (1 - widget.scaleFrom) * v,
                    child: child,
                  ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A number that counts up from 0 to [value] on mount — makes dashboard stats
/// feel alive. Renders a single ellipsised line in [style].
class JzCountUp extends StatelessWidget {
  const JzCountUp({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 700),
  });

  final int value;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context) || value == 0) {
      return Text(
        '$value',
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '${v.round()}',
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Tactile press feedback: the child eases down to [scale] while a pointer is
/// down. Uses a raw [Listener], so it never competes with the child's own
/// taps/ink (safe to wrap cards that already contain an [InkWell]).
class JzPressable extends StatefulWidget {
  const JzPressable({super.key, required this.child, this.scale = 0.98});

  final Widget child;
  final double scale;

  @override
  State<JzPressable> createState() => _JzPressableState();
}

class _JzPressableState extends State<JzPressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A gentle, endless attention pulse (e.g. the unread-notifications dot).
/// Collapses to a static child when animations are disabled.
class JzPulse extends StatefulWidget {
  const JzPulse({super.key, required this.child, this.maxScale = 1.25});

  final Widget child;
  final double maxScale;

  @override
  State<JzPulse> createState() => _JzPulseState();
}

class _JzPulseState extends State<JzPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _configured = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_configured) return;
    _configured = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 1.0,
        end: widget.maxScale,
      ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}
