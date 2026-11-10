import 'dart:convert';
import 'dart:io';

import 'package:waaiya_ui/waaiya_ui.dart';

/// Desktop backend (docs/UI_CONTRACT.md, "Where the desktop backend differs").
///
/// Settings and the language are kept in a JSON file with the same keys as Android's SharedPreferences file, so a
/// desktop engine host can read them the same way. The filter itself is not connected yet: start/stop only change
/// the reported state, and the screen says it is a preview (`filter.simulated`).
class DesktopBackend extends MemoryBackend {
  DesktopBackend._(this.settingsFile, this.licencesDir, AppState initial) : super(initial: initial);

  /// Where the settings are stored.
  final File settingsFile;

  /// Licence texts shipped next to the app (CI copies NOTICE, LICENSE, THIRD_PARTY_LICENSES.md there).
  final Directory licencesDir;

  static const _langKey = 'lang';

  static Future<DesktopBackend> open({File? file, Directory? licencesDir}) async {
    file ??= defaultSettingsFile();
    licencesDir ??= Directory('${File(Platform.resolvedExecutable).parent.path}${Platform.pathSeparator}licences');
    var saved = <String, Object?>{};
    try {
      saved = (jsonDecode(await file.readAsString()) as Map).cast<String, Object?>();
    } on Object {
      // first run, or an unreadable file: defaults
    }
    final settings = <String, Object>{...SettingKeys.defaults};
    for (final key in SettingKeys.defaults.keys) {
      final v = saved[key];
      if (v != null && SettingKeys.validate(key, v) == null) settings[key] = v;
    }
    final initial = AppState(
      platform: Platform.operatingSystem,
      version: '0.2.2',
      language: saved[_langKey] == 'en' ? 'en' : 'ar', // Arabic first, whatever the system language
      settings: WaaiyaSettings.fromMap(settings),
      filter: const FilterInfo(simulated: true),
      // TODO(engine): true once the engine reports whether the detector model is installed.
      detectorModel: false,
      capabilities: const Capabilities(womenSinging: true),
    );
    return DesktopBackend._(file, licencesDir, initial);
  }

  /// %APPDATA%\Waaiya\settings.json, ~/Library/Application Support/Waaiya/settings.json,
  /// $XDG_CONFIG_HOME/waaiya/settings.json (default ~/.config).
  static File defaultSettingsFile() {
    final env = Platform.environment;
    final sep = Platform.pathSeparator;
    final String dir;
    if (Platform.isWindows) {
      dir = '${env['APPDATA'] ?? env['USERPROFILE'] ?? '.'}${sep}Waaiya';
    } else if (Platform.isMacOS) {
      dir = '${env['HOME'] ?? '.'}/Library/Application Support/Waaiya';
    } else {
      final xdg = env['XDG_CONFIG_HOME'];
      dir = '${xdg != null && xdg.isNotEmpty ? xdg : '${env['HOME'] ?? '.'}/.config'}/waaiya';
    }
    return File('$dir${sep}settings.json');
  }

  @override
  Future<void> saved() async {
    final data = {...state.settings.toMap(), _langKey: state.language};
    await settingsFile.parent.create(recursive: true);
    final tmp = File('${settingsFile.path}.tmp');
    await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    await tmp.rename(settingsFile.path); // atomic: the engine host never reads half a file
  }

  // TODO(engine): Windows: load the engine (engine/include/im_engine.h, built with MSVC) through dart:ffi, or
  // start the Windows audio host (reports/desktop_windows_macos_scope.md §2) and report its state here.
  // Linux: drive the existing host (`waaiya start|stop|status`, linux/bin/waaiya).
  // Until then MemoryBackend only flips the reported state (simulated).
  // Override startFilter / stopFilter here, report the engine's state with emit(state.copyWith(filter: ...)), and
  // set filter.simulated to false.

  static const _docs = [
    LicenceDoc('GNU Affero General Public License v3 or later (Waaiya)', 'LICENSE-Apache-2.0.txt'),
    LicenceDoc('Third-party components, models and training data', 'THIRD_PARTY_LICENSES.txt'),
  ];

  @override
  Future<Licences> getLicences() async {
    final notice = await _read('NOTICE.txt');
    return Licences(notice: notice, docs: _docs);
  }

  @override
  Future<String> getLicenceText(String file) async {
    if (!_docs.any((d) => d.file == file)) throw BackendException('bad_args', 'licence file $file');
    return _read(file);
  }

  Future<String> _read(String name) async {
    try {
      return await File('${licencesDir.path}${Platform.pathSeparator}$name').readAsString();
    } on IOException {
      return 'Waaiya is free software under the GNU Affero General Public License v3 or later. Licence texts: '
          'https://github.com/oksyassine/waaiya (NOTICE, LICENSE, THIRD_PARTY_LICENSES.md).';
    }
  }
}
