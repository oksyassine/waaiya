import 'package:flutter/material.dart';

/// Waaiya's motion: short, calm, and none at all when the system asks for less motion (Android's "Remove
/// animations", Windows' "Animation effects" off).
abstract final class Motion {
  static const fast = Duration(milliseconds: 120);
  static const medium = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 420);
  static const curve = Curves.easeOutCubic;

  /// [d], or zero when the system asks for less motion.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;
}

/// Shrinks its child a little while it is pressed (a button that answers the finger or the mouse at once). The press
/// itself is handled by the child (InkWell, buttons); this only listens.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.scale = 0.96, this.enabled = true});

  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: widget.enabled ? (_) => _set(true) : null,
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: Motion.of(context, Motion.fast),
          curve: Motion.curve,
          child: widget.child,
        ),
      );
}

/// Fades and slides its child in the first time it is built (a card that appears: a link's result, a save).
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.offset = 12});

  final Widget child;

  /// Logical pixels it comes up from.
  final double offset;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Motion.of(context, Motion.medium),
        curve: Motion.curve,
        child: child,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * offset), child: child),
        ),
      );
}

/// Cross-fades text (or any child) when it changes: a state line, a status.
class SwitchFade extends StatelessWidget {
  const SwitchFade({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: Motion.of(context, Motion.medium),
        switchInCurve: Motion.curve,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: child,
      );
}

/// A determinate progress bar that moves smoothly between the values it is given; indeterminate when [value] is
/// null.
class SmoothProgress extends StatelessWidget {
  const SmoothProgress({super.key, required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v == null) return const LinearProgressIndicator();
    return TweenAnimationBuilder<double>(
      tween: Tween(end: v.clamp(0, 1)),
      duration: Motion.of(context, Motion.slow),
      curve: Motion.curve,
      builder: (context, t, _) => LinearProgressIndicator(value: t),
    );
  }
}

/// A button's content while its action runs: a small spinner and a word ("Starting…").
class BusyLabel extends StatelessWidget {
  const BusyLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: DefaultTextStyle.of(context).style.color),
          ),
          const SizedBox(width: 10),
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
        ],
      );
}
