import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'memory_backend.dart';
import 'widgets.dart';

/// The text for a link error code ([linkErrorCodes]; Android's link_* strings).
String linkErrorText(AppLocalizations l, String code) => switch (code) {
      'invalid_url' => l.linkInvalid,
      'login' => l.linkLogin,
      'limited' => l.linkLimited,
      'unsupported_site' => l.linkUnsupported,
      'playlist' => l.linkPlaylist,
      'no_format' => l.linkNoFormat,
      'live' => l.linkLive,
      'busy' => l.linkBusy,
      'filter_failed' => l.linkFilterFailed,
      'cancelled' => l.linkCancelled,
      'export_failed' => l.linkExportFailed,
      _ => l.linkFailed,
    };

/// "1:05" or "1:02:03" (LinkActivity.show).
String linkDuration(int s) => s >= 3600
    ? '${s ~/ 3600}:${(s ~/ 60 % 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}'
    : '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

/// The Links page drawn in Flutter (capability `linkPage`, desktop), as Android's LinkActivity: paste or type a link,
/// Open shows what it is, then Watch (in the browser, with the filter on: the filter covers every app) and, with
/// capability `linkSave`, Save without music with its progress, Cancel, Play and Show in folder. The save goes on
/// in the background (state in [AppState.linkSave]) when another page is shown.
class LinksPanel extends StatefulWidget {
  const LinksPanel({super.key});

  @override
  State<LinksPanel> createState() => _LinksPanelState();
}

class _LinksPanelState extends State<LinksPanel> {
  final _input = TextEditingController();
  LinkMeta? _meta;
  bool _resolving = false;
  bool _watching = false;
  String? _error;
  String? _errorDetail;

  /// Increases with every Open: a slow answer for an older link is dropped.
  int _request = 0;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _fail(BackendException e) => setState(() {
        _error = linkErrorText(AppLocalizations.of(context), e.code);
        _errorDetail = e.code == 'failed' && e.message.isNotEmpty ? e.message : null;
      });

  Future<void> _paste() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final link = MemoryBackend.webLink(clip?.text ?? '');
    if (!mounted) return;
    if (link == null) {
      setState(() => _error = AppLocalizations.of(context).linkInvalid);
      return;
    }
    _input.text = link.toString();
    await _open();
  }

  Future<void> _open() async {
    final link = MemoryBackend.webLink(_input.text);
    if (link == null) {
      setState(() {
        _error = AppLocalizations.of(context).linkInvalid;
        _errorDetail = null;
        _meta = null;
      });
      return;
    }
    final id = ++_request;
    final backend = WaaiyaScope.of(context).backend;
    setState(() {
      _resolving = true;
      _error = null;
      _errorDetail = null;
      _meta = null;
    });
    try {
      final m = await backend.resolveLink(link.toString());
      if (mounted && id == _request) setState(() => _meta = m);
    } on BackendException catch (e) {
      if (mounted && id == _request) _fail(e);
    } finally {
      if (mounted && id == _request) setState(() => _resolving = false);
    }
  }

  Future<void> _watch(LinkMeta m) async {
    final backend = WaaiyaScope.of(context).backend;
    setState(() {
      _watching = true;
      _error = null;
    });
    try {
      await backend.watchLink(m.url);
    } on BackendException catch (e) {
      if (mounted) _fail(e);
    } finally {
      if (mounted) setState(() => _watching = false);
    }
  }

  Future<void> _save(LinkMeta m) async {
    final backend = WaaiyaScope.of(context).backend;
    if (m.isLive) {
      _fail(const BackendException('live'));
      return;
    }
    setState(() => _error = null);
    try {
      await backend.saveLink(m.url);
    } on BackendException catch (e) {
      if (mounted) _fail(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = WaaiyaScope.of(context).state;
    final canSave = s.capabilities.linkSave;
    final text = Theme.of(context).textTheme;
    final m = _meta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: l.linkEntryTitle,
          body: canSave ? l.linkEntryBodyDesktop : l.linkEntryBodyWatch,
          children: [
            const SizedBox(height: 16),
            TextField(
              key: const Key('link_input'),
              controller: _input,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              // links read left to right in every language
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: l.linkFieldLabel,
                hintText: l.linkHint,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _open(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  key: const Key('link_paste'),
                  onPressed: _resolving ? null : _paste,
                  icon: const Icon(Icons.content_paste_rounded),
                  label: Text(l.linkPaste),
                ),
                FilledButton(
                  key: const Key('link_open'),
                  onPressed: _resolving ? null : _open,
                  child: Text(l.linkOpen),
                ),
              ],
            ),
            if (_resolving) ...[
              const SizedBox(height: 16),
              Row(children: [
                const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Expanded(child: Text(l.linkResolving, style: text.bodyMedium)),
              ]),
            ],
            if (_error != null) StatusText(_error!, isError: true, id: 'link_error'),
            if (_errorDetail != null)
              Directionality(
                textDirection: TextDirection.ltr,
                child: SelectableText(_errorDetail!, style: text.bodySmall),
              ),
          ],
        ),
        if (m != null) _result(context, l, s, m),
        if (canSave && s.linkSave.phase != LinkSavePhase.idle) _saveCard(context, l, s.linkSave, text),
      ],
    );
  }

  Widget _result(BuildContext context, AppLocalizations l, AppState s, LinkMeta m) {
    final d = m.durationSec;
    final meta = d == null || m.site.isEmpty
        ? (d == null ? m.site : linkDuration(d))
        : l.linkMeta(m.site, linkDuration(d));
    final busy = s.linkSave.busy;
    final singing = s.settings.isMan && s.settings.muteWomenSinging && s.capabilities.womenSinging;
    return SectionCard(
      key: const Key('link_result'),
      title: m.title.isNotEmpty ? m.title : m.site,
      body: [meta, if (m.audioOnly) l.linkAudioOnly].where((t) => t.isNotEmpty).join('\n'),
      children: [
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('link_watch'),
              onPressed: _watching ? null : () => _watch(m),
              icon: const Icon(Icons.open_in_browser_rounded),
              label: Text(m.hasVideo ? l.linkWatch : l.linkListen),
            ),
            if (s.capabilities.linkSave)
              FilledButton.tonalIcon(
                key: const Key('link_save'),
                onPressed: busy ? null : () => _save(m),
                icon: const Icon(Icons.download_rounded),
                label: Text(l.linkSave),
              ),
          ],
        ),
        StatusText(l.linkWatchNoteDesktop),
        if (singing) StatusText(l.linkSingingNote),
      ],
    );
  }

  Widget _saveCard(BuildContext context, AppLocalizations l, LinkSaveInfo st, TextTheme text) {
    final backend = WaaiyaScope.of(context).backend;
    final failed = st.phase == LinkSavePhase.failed;
    final done = st.phase == LinkSavePhase.done;
    final err = st.error;
    final state = switch (st.phase) {
      LinkSavePhase.downloading => l.linkDownloading,
      LinkSavePhase.filtering => l.linkFiltering,
      LinkSavePhase.done => '${l.linkSaved}\n${st.isVideo ? l.linkSavedVideoDesktop : l.linkSavedAudioDesktop}',
      LinkSavePhase.failed => err == null || err.code == 'failed' ? l.linkExportFailed : linkErrorText(l, err.code),
      LinkSavePhase.idle => '',
    };
    return SectionCard(
      key: const Key('link_save_card'),
      title: st.title,
      children: [
        StatusText(state, isError: failed, id: 'link_save_state'),
        if (failed && err != null && err.code == 'failed' && err.detail.isNotEmpty)
          Directionality(
            textDirection: TextDirection.ltr,
            child: SelectableText(err.detail, style: text.bodySmall),
          ),
        if (st.busy) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(value: st.progress < 0 ? null : st.progress),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              key: const Key('link_cancel'),
              onPressed: () => runAction(context, (b) => b.cancelLinkSave()),
              child: Text(l.linkCancel),
            ),
          ),
        ],
        if (done && st.path != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('link_play'),
                onPressed: () => backend.openSavedLink(),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l.linkPlay),
              ),
              OutlinedButton.icon(
                key: const Key('link_show'),
                onPressed: () => backend.showSavedLink(),
                icon: const Icon(Icons.folder_open_rounded),
                label: Text(l.linkShowInFolder),
              ),
            ],
          ),
          StatusText(l.linkShareNote),
        ],
      ],
    );
  }
}
