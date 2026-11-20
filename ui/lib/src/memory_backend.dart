import 'dart:async';
import 'dart:typed_data';

import 'backend.dart';

/// A [WaaiyaBackend] that keeps everything in memory. Used by the tests, and as the base of the desktop backend
/// (which adds a settings file and, later, the engine). Start/stop only change the reported state.
class MemoryBackend implements WaaiyaBackend {
  MemoryBackend({AppState initial = const AppState(platform: 'test')}) : _state = initial;

  AppState _state;
  final _controller = StreamController<AppState>.broadcast();

  AppState get state => _state;

  /// Replaces the snapshot and tells the listeners.
  void emit(AppState s) {
    _state = s;
    _controller.add(s);
  }

  /// Persistence hook for subclasses: called after every settings or language change.
  Future<void> saved() async {}

  @override
  Stream<AppState> get states async* {
    yield _state;
    yield* _controller.stream;
  }

  @override
  Future<AppState> getState() async => _state;

  @override
  Future<void> setSetting(String key, Object value) async {
    final error = SettingKeys.validate(key, value);
    if (error != null) throw BackendException('bad_args', error);
    emit(_state.copyWith(settings: WaaiyaSettings.fromMap({..._state.settings.toMap(), key: value})));
    await saved();
  }

  @override
  Future<StartResult> startFilter() async {
    if (_state.filter.running) return StartResult.alreadyRunning;
    final f = _state.filter;
    emit(_state.copyWith(
        filter: FilterInfo(state: FilterState.filtering, delayMs: 40, simulated: f.simulated, autostart: f.autostart)));
    return StartResult.started;
  }

  @override
  Future<void> stopFilter() async =>
      emit(_state.copyWith(filter: FilterInfo(simulated: _state.filter.simulated, autostart: _state.filter.autostart)));

  @override
  Future<void> runSetupStep(int step) async => throw const BackendException('unsupported', 'runSetupStep');

  @override
  Future<void> blurSetup() async => throw const BackendException('unsupported', 'blurSetup');

  @override
  Future<void> openOverlaySettings() async => throw const BackendException('unsupported', 'openOverlaySettings');

  @override
  Future<void> openShizuku() async => throw const BackendException('unsupported', 'openShizuku');

  @override
  Future<void> openDeveloperOptions() async => throw const BackendException('unsupported', 'openDeveloperOptions');

  @override
  Future<void> setLanguage(String tag) async {
    if (!appLanguages.containsKey(tag)) throw BackendException('bad_args', 'language "$tag"');
    emit(_state.copyWith(language: tag));
    await saved();
  }

  @override
  Future<void> setAutostart(bool on) async {
    if (!_state.capabilities.autostart) throw const BackendException('unsupported', 'setAutostart');
    emit(_state.copyWith(filter: FilterInfo(
      state: _state.filter.state,
      delayMs: _state.filter.delayMs,
      simulated: _state.filter.simulated,
      autostart: on,
    )));
  }

  @override
  Future<void> openLinkScreen() async => throw const BackendException('unsupported', 'openLinkScreen');

  /// Links in the simulation: the last link opened in the "browser" ([watchLink]).
  String? openedLink;

  /// Links in the simulation: how [saveLink] ends (null: saved; a code: failed with it). Tests set it.
  String? linkSaveOutcome;

  /// The simulated save waits for [finishLinkSave] (tests: to see the progress, cancel it) instead of ending at once.
  bool holdLinkSave = false;

  /// The web link in [text] (http or https with a host), or null.
  static Uri? webLink(String text) {
    final m = RegExp(r'https?://\S+', caseSensitive: false).firstMatch(text.trim());
    final u = m == null ? null : Uri.tryParse(m.group(0)!);
    return u != null && u.host.isNotEmpty ? u : null;
  }

  @override
  Future<LinkMeta> resolveLink(String url) async {
    if (!_state.capabilities.linkPage) throw const BackendException('unsupported', 'resolveLink');
    final u = webLink(url);
    if (u == null) throw const BackendException('invalid_url');
    if (u.path.contains('playlist')) throw const BackendException('playlist');
    return LinkMeta(url: u.toString(), title: 'Video', site: u.host, durationSec: 95);
  }

  @override
  Future<void> watchLink(String url) async {
    if (!_state.capabilities.linkPage) throw const BackendException('unsupported', 'watchLink');
    final u = webLink(url);
    if (u == null) throw const BackendException('invalid_url');
    if (!_state.filter.running && await startFilter() != StartResult.started) {
      throw const BackendException('filter_failed');
    }
    openedLink = u.toString();
  }

  @override
  Future<void> saveLink(String url) async {
    if (!_state.capabilities.linkSave) throw const BackendException('unsupported', 'saveLink');
    if (_state.linkSave.busy) throw const BackendException('busy');
    final meta = await resolveLink(url);
    emit(_state.copyWith(
        linkSave: LinkSaveInfo(phase: LinkSavePhase.downloading, title: meta.title, progress: 0)));
    if (!holdLinkSave) finishLinkSave();
  }

  /// Ends a simulated save the way [linkSaveOutcome] says.
  void finishLinkSave() {
    final s = _state.linkSave;
    if (!s.busy) return;
    final outcome = linkSaveOutcome;
    emit(_state.copyWith(
      linkSave: outcome == null
          ? LinkSaveInfo(phase: LinkSavePhase.done, title: s.title, progress: 1, path: 'Videos/Waaiya/${s.title}.mp4')
          : LinkSaveInfo(phase: LinkSavePhase.failed, title: s.title, error: BackendMessage(outcome)),
    ));
  }

  @override
  Future<void> cancelLinkSave() async {
    final s = _state.linkSave;
    if (!s.busy) return;
    emit(_state.copyWith(
        linkSave: LinkSaveInfo(phase: LinkSavePhase.failed, title: s.title, error: const BackendMessage('cancelled'))));
  }

  /// The simulation's "player" and "folder": the path last opened.
  String? openedFile;

  @override
  Future<void> openSavedLink() async => openedFile = _state.linkSave.path;

  @override
  Future<void> showSavedLink() async => openedFile = _state.linkSave.path;

  @override
  Future<Licences> getLicences() async => const Licences(notice: '', docs: []);

  @override
  Future<String> getLicenceText(String file) async => '';

  @override
  Future<String> diagnosticsReport() async => 'Waaiya ${_state.version} (${_state.platform})\n'
      'Filter: ${_state.filter.state.name}\nBlur: ${_state.blur.state?.name ?? 'off'}';

  @override
  Future<String> wirelessStart() async => throw const BackendException('unsupported', 'wirelessStart');

  @override
  Future<bool> wirelessEnterCode(String code) async => throw const BackendException('unsupported', 'wirelessEnterCode');

  @override
  Future<void> wirelessCancel() async {}

  @override
  Future<void> openAboutPhone() async => throw const BackendException('unsupported', 'openAboutPhone');

  @override
  Future<void> openWifiSettings() async => throw const BackendException('unsupported', 'openWifiSettings');

  /// No pictures off Android (tests and desktop): the steps show their words only.
  @override
  Future<Uint8List?> guidePicture(String name) async => null;

  @override
  Future<void> openSetupGuide() async => throw const BackendException('unsupported', 'openSetupGuide');

  @override
  Future<void> pageShown() async {}

  @override
  Future<void> shareText(String text) async => throw const BackendException('unsupported', 'shareText');

  Future<void> close() => _controller.close();
}
