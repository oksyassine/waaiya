import 'dart:async';

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
    emit(_state.copyWith(filter: FilterInfo(state: FilterState.filtering, delayMs: 40, simulated: _state.filter.simulated)));
    return StartResult.started;
  }

  @override
  Future<void> stopFilter() async =>
      emit(_state.copyWith(filter: FilterInfo(simulated: _state.filter.simulated)));

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
    if (tag != 'ar' && tag != 'en') throw BackendException('bad_args', 'language "$tag"');
    emit(_state.copyWith(language: tag));
    await saved();
  }

  @override
  Future<void> openLinkScreen() async => throw const BackendException('unsupported', 'openLinkScreen');

  @override
  Future<Licences> getLicences() async => const Licences(notice: '', docs: []);

  @override
  Future<String> getLicenceText(String file) async => '';

  Future<void> close() => _controller.close();
}
