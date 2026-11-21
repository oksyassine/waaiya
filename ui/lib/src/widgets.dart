import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'motion.dart';
import 'theme.dart';

/// Scrolling page column, at most 640 wide (phones use the full width; desktop windows stay readable).
class PageColumn extends StatelessWidget {
  const PageColumn({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ),
        ],
      );
}

/// App name and tagline, at the top of the main and first-launch screens.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(l.appName, style: text.headlineMedium)),
        const SizedBox(height: 4),
        Text(l.tagline, style: text.bodyMedium),
      ],
    );
  }
}

/// The name of a page at its top (the Filter page has the app header instead).
class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
      );
}

/// A card with a title, optional body text and content.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, this.body, this.children = const []});

  final String title;
  final String? body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: AnimatedSize(
        duration: Motion.of(context, Motion.medium),
        curve: Motion.curve,
        alignment: Alignment.topCenter,
        child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(title, style: text.titleMedium)),
            if (body != null) ...[const SizedBox(height: 6), Text(body!, style: text.bodyMedium)],
            ...children,
          ],
        ),
        ),
      ),
    );
  }
}

/// A switch row: title, explanation, switch (the whole row is the tap target).
class SettingSwitch extends StatelessWidget {
  const SettingSwitch({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.body,
    this.bodyIsError = false,
    this.id,
  });

  final String title;
  final String? body;
  final bool bodyIsError;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Android resource-id for UI tests (android/tools/emu_check.py), the same as the native screen's.
  final String? id;

  @override
  Widget build(BuildContext context) {
    final c = WaaiyaColors.of(context);
    // the press highlight gets room around the text (rounded, 12 px each side); the row is widened by as much into
    // the card's padding, so the text stays in line with the rest of the card
    const inset = 12.0;
    final tile = SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: inset),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      value: value,
      onChanged: onChanged,
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: body == null
          ? null
          : Text(body!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: bodyIsError ? c.error : null)),
    );
    final wide = LayoutBuilder(
      builder: (context, box) => box.hasBoundedWidth
          ? OverflowBox(
              minWidth: box.maxWidth + 2 * inset,
              maxWidth: box.maxWidth + 2 * inset,
              fit: OverflowBoxFit.deferToChild,
              child: tile,
            )
          : tile,
    );
    // one node: the id on the same node as the switch's checked state
    return id == null ? wide : MergeSemantics(child: Semantics(identifier: id, child: wide));
  }
}

/// Gives [child] its own accessibility node with an Android resource-id, for UI tests (emu_check.py).
class TestId extends StatelessWidget {
  const TestId(this.id, {super.key, required this.child});

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(container: true, identifier: id, child: child);
}

/// A line of secondary text that turns red for problems.
class StatusText extends StatelessWidget {
  const StatusText(this.text, {super.key, this.isError = false, this.color, this.id});

  /// Android resource-id for UI tests.
  final String? id;

  final String text;
  final bool isError;

  /// Overrides the colour (e.g. the primary colour for a hint).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color ?? (isError ? WaaiyaColors.of(context).error : null)),
    );
    final f = SwitchFade(child: KeyedSubtree(key: ValueKey('$text$isError'), child: t));
    return Padding(padding: const EdgeInsets.only(top: 12), child: id == null ? f : TestId(id!, child: f));
  }
}

/// "Label: value" with a Change button.
class ValueRow extends StatelessWidget {
  const ValueRow({super.key, required this.label, required this.action, required this.onPressed});

  final String label;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: LabelAndActions(
          label: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          actions: [TextButton(onPressed: onPressed, child: Text(action))],
        ),
      );
}

/// A label with its buttons at the end of the same line; when they do not fit (a long language, large text, a
/// small phone) the buttons go under the label instead of off the screen.
class LabelAndActions extends StatelessWidget {
  const LabelAndActions({super.key, required this.label, required this.actions});

  final Widget label;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [label, Wrap(children: actions)],
      );
}

/// A one-choice dialog; returns the chosen index, or null when cancelled.
Future<int?> chooseOne(BuildContext context, {required String title, required List<String> options, int? selected}) {
  return showDialog<int>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: [
        for (var i = 0; i < options.length; i++)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, i),
            child: Row(
              children: [
                Icon(i == selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: i == selected ? Theme.of(context).colorScheme.primary : null),
                const SizedBox(width: 16),
                Expanded(child: Text(options[i], style: Theme.of(context).textTheme.bodyLarge)),
              ],
            ),
          ),
      ],
    ),
  );
}

/// The language list ([appLanguages], each in its own name); the choice goes through the backend.
Future<void> chooseLanguage(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final current = WaaiyaScope.of(context).state.language;
  final tags = appLanguages.keys.toList();
  final i = await chooseOne(context,
      title: l.languageTitle, options: appLanguages.values.toList(), selected: tags.indexOf(current));
  if (i != null && tags[i] != current && context.mounted) await runAction(context, (b) => b.setLanguage(tags[i]));
}

/// One numbered step of a setup: a circle with the number (a tick when done), the title, one sentence, and, for the
/// current step only, its buttons.
class StepRow extends StatelessWidget {
  const StepRow({
    super.key,
    required this.index,
    required this.done,
    required this.title,
    required this.body,
    required this.current,
    this.children = const [],
  });

  final int index;
  final bool done;
  final String title;
  final String body;
  final bool current;

  /// Shown under the sentence while this is the current step (buttons, live status).
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = WaaiyaColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? c.primary : null,
                border: done ? null : Border.all(color: current ? c.primary : c.offRing, width: 2),
              ),
              child: done
                  ? Icon(Icons.check_rounded, size: 20, color: c.onPrimary)
                  : Text('${index + 1}', style: text.bodyLarge),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: '${done ? l.stepDoneCd : l.stepTodoCd(index + 1)}. $title',
                  excludeSemantics: true,
                  child: Text(title, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                ),
                // a finished step keeps only its title: less to read
                if (!done) ...[const SizedBox(height: 2), Text(body, style: text.bodyMedium)],
                if (current) ...[const SizedBox(height: 8), ...children],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
