import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'widgets.dart';

/// Open-source licences: NOTICE, then one button per full text. The texts come from the backend (Android: the
/// assets copied from the repository at build time), so they cannot drift from NOTICE / THIRD_PARTY_LICENSES.md.
class LicencesScreen extends StatefulWidget {
  const LicencesScreen({super.key});

  @override
  State<LicencesScreen> createState() => _LicencesScreenState();
}

class _LicencesScreenState extends State<LicencesScreen> {
  Future<Licences>? _licences;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _licences ??= WaaiyaScope.of(context).backend.getLicences();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.licences), backgroundColor: Theme.of(context).scaffoldBackgroundColor),
      body: FutureBuilder<Licences>(
        future: _licences,
        builder: (context, snap) {
          final lic = snap.data;
          if (lic == null) {
            return snap.hasError ? Center(child: Text('${snap.error}')) : const Center(child: CircularProgressIndicator());
          }
          return PageColumn(
            children: [
              Text(l.licencesIntro, style: text.bodyLarge),
              const SizedBox(height: 12),
              // NOTICE is English legal text: left to right, also in Arabic.
              if (lic.notice.isNotEmpty)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(lic.notice, style: text.bodyMedium),
                ),
              const SizedBox(height: 12),
              SelectableText(l.licencesCc, style: text.bodyMedium),
              const SizedBox(height: 16),
              Text(l.licencesFull, style: text.titleMedium),
              for (final doc in lic.docs) ...[
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => _LicenceText(doc: doc)),
                  ),
                  child: Text(doc.label, textAlign: TextAlign.center),
                ),
              ],
              // The screens themselves: Flutter engine, framework and Dart packages (their NOTICES).
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => showLicensePage(context: context, applicationName: l.appName),
                child: const Text('Flutter and Dart packages (BSD-3-Clause and others)', textAlign: TextAlign.center),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One full licence text. Some are large (ONNX Runtime's notices: 340 KB), so it is built line by line.
class _LicenceText extends StatefulWidget {
  const _LicenceText({required this.doc});

  final LicenceDoc doc;

  @override
  State<_LicenceText> createState() => _LicenceTextState();
}

class _LicenceTextState extends State<_LicenceText> {
  Future<List<String>>? _lines;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lines ??= WaaiyaScope.of(context).backend.getLicenceText(widget.doc.file).then((t) => t.split('\n'));
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doc.label, overflow: TextOverflow.ellipsis),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: FutureBuilder<List<String>>(
        future: _lines,
        builder: (context, snap) {
          final lines = snap.data;
          if (lines == null) {
            return snap.hasError ? Center(child: Text('${snap.error}')) : const Center(child: CircularProgressIndicator());
          }
          return Directionality(
            textDirection: TextDirection.ltr,
            child: SelectionArea(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: lines.length,
                itemBuilder: (_, i) => Text(lines[i], style: style),
              ),
            ),
          );
        },
      ),
    );
  }
}
