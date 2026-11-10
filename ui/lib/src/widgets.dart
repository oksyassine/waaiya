import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
  });

  final String title;
  final String? body;
  final bool bodyIsError;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = WaaiyaColors.of(context);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: body == null
          ? null
          : Text(body!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: bodyIsError ? c.error : null)),
    );
  }
}

/// A line of secondary text that turns red for problems.
class StatusText extends StatelessWidget {
  const StatusText(this.text, {super.key, this.isError = false, this.color});

  final String text;
  final bool isError;

  /// Overrides the colour (e.g. the primary colour for a hint).
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color ?? (isError ? WaaiyaColors.of(context).error : null)),
        ),
      );
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
        child: Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
            TextButton(onPressed: onPressed, child: Text(action)),
          ],
        ),
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
