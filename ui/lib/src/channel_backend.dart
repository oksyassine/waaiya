import 'package:flutter/services.dart';

import 'backend.dart';

/// [WaaiyaBackend] over the platform channels of docs/UI_CONTRACT.md. Android implements them in UiBridge.kt.
class ChannelBackend implements WaaiyaBackend {
  ChannelBackend({
    MethodChannel methods = const MethodChannel('waaiya/app'),
    EventChannel events = const EventChannel('waaiya/state'),
  })  : _methods = methods,
        _states = events.receiveBroadcastStream().map((e) => AppState.fromMap(e as Map));

  final MethodChannel _methods;
  final Stream<AppState> _states;

  @override
  Stream<AppState> get states => _states;

  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _methods.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw BackendException(e.code, e.message ?? '');
    } on MissingPluginException {
      throw BackendException('unsupported', method);
    }
  }

  @override
  Future<Object?> invoke(String method, [Map<String, Object?> args = const {}]) => _call<Object?>(method, args);

  @override
  Future<AppState> getState() async => AppState.fromMap(await _call<Map<Object?, Object?>>('getState') ?? const {});

  @override
  Future<void> setSetting(String key, Object value) => _call<void>('setSetting', {'key': key, 'value': value});

  @override
  Future<StartResult> startFilter() async => startResultFromCode(await _call<String>('startFilter'));

  @override
  Future<void> stopFilter() => _call<void>('stopFilter');

  @override
  Future<void> runSetupStep(int step) => _call<void>('runSetupStep', {'step': step});

  @override
  Future<void> blurSetup() => _call<void>('blurSetup');

  @override
  Future<void> openOverlaySettings() => _call<void>('openOverlaySettings');

  @override
  Future<void> openShizuku() => _call<void>('openShizuku');

  @override
  Future<void> openDeveloperOptions({String? highlight}) =>
      _call<void>('openDeveloperOptions', {'highlight': ?highlight});

  @override
  Future<void> setLanguage(String tag) => _call<void>('setLanguage', {'tag': tag});

  @override
  Future<void> setAutostart(bool on) => _call<void>('setAutostart', {'on': on});

  @override
  Future<void> openLinkScreen() => _call<void>('openLinkScreen');

  // The Links page is Android's native screen ([openLinkScreen]); capability `linkPage` is false there.
  @override
  Future<LinkMeta> resolveLink(String url) async => throw const BackendException('unsupported', 'resolveLink');

  @override
  Future<void> watchLink(String url) async => throw const BackendException('unsupported', 'watchLink');

  @override
  Future<void> saveLink(String url) async => throw const BackendException('unsupported', 'saveLink');

  @override
  Future<void> cancelLinkSave() async => throw const BackendException('unsupported', 'cancelLinkSave');

  @override
  Future<void> openSavedLink() async => throw const BackendException('unsupported', 'openSavedLink');

  @override
  Future<void> showSavedLink() async => throw const BackendException('unsupported', 'showSavedLink');

  @override
  Future<Licences> getLicences() async {
    final m = await _call<Map<Object?, Object?>>('getLicences') ?? const {};
    final docs = (m['docs'] as List? ?? const [])
        .whereType<Map>()
        .map((d) => LicenceDoc('${d['label']}', '${d['file']}'))
        .toList();
    return Licences(notice: m['notice'] as String? ?? '', docs: docs);
  }

  @override
  Future<String> getLicenceText(String file) async => await _call<String>('getLicenceText', {'file': file}) ?? '';

  @override
  Future<String> diagnosticsReport() async => await _call<String>('diagnosticsReport') ?? '';

  @override
  Future<String> wirelessStart() async => await _call<String>('wirelessStart') ?? 'started';

  @override
  Future<bool> wirelessEnterCode(String code) async => await _call<bool>('wirelessEnterCode', {'code': code}) ?? false;

  @override
  Future<void> wirelessCancel() => _call<void>('wirelessCancel');

  @override
  Future<void> openAboutPhone() => _call<void>('openAboutPhone');

  @override
  Future<void> openWifiSettings() => _call<void>('openWifiSettings');

  @override
  Future<Uint8List?> guidePicture(String name) => _call<Uint8List?>('guidePicture', {'name': name});

  @override
  Future<void> openSetupGuide() => _call<void>('openSetupGuide');

  @override
  Future<void> pageShown() => _call<void>('pageShown');

  @override
  Future<void> shareText(String text) => _call<void>('shareText', {'text': text});
}
