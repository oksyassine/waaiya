// Fix mistakes on the spot (lane A) on desktop: apps heard unfiltered are handed to the Linux daemon through
// $XDG_CONFIG_HOME/islamic-mute/filter_off_apps (linux/test_filter_off_apps.py checks the daemon's routing), and the
// wrong-detection notes are kept in a local file.
@TestOn('linux')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_desktop/desktop_backend.dart';
import 'package:waaiya_desktop/linux_engine.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('waaiya_fix'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('application names from pactl, ours left out', () {
    const out = '''
Sink Input #12
	Driver: protocol-native.c
	Properties:
		media.name = "Playback"
		application.name = "Firefox"
Sink Input #13
	Properties:
		application.name = "Waaiya filter"
Sink Input #14
	Properties:
		application.name = "Firefox"
Sink Input #15
	Properties:
		application.name = "Quran Player"
''';
    expect(LinuxEngine.appNames(out), ['Firefox', 'Quran Player']);
  });

  test('the list file: written for the daemon, removed when empty', () {
    final e = LinuxEngine(Directory('${dir.path}/engine'), environment: {'HOME': dir.path, 'XDG_CONFIG_HOME': '${dir.path}/cfg'});
    final f = File('${dir.path}/cfg/islamic-mute/filter_off_apps');
    e.writeFilterOffApps(['Firefox', 'Quran Player', '']);
    expect(f.readAsStringSync(), 'Firefox\nQuran Player\n');
    e.writeFilterOffApps([]);
    expect(f.existsSync(), isFalse);
  });

  test('setSetting filter_off_apps reaches the daemon file; the list is offered from what plays', () async {
    final env = {'HOME': dir.path, 'XDG_CONFIG_HOME': '${dir.path}/cfg', 'PATH': '/nonexistent'};
    final engine = LinuxEngine(Directory('${dir.path}/engine'), environment: env);
    final b = await DesktopBackend.open(
        file: File('${dir.path}/s.json'),
        licencesDir: dir,
        engine: engine,
        findBlur: false,
        platform: 'linux',
        poll: null);
    expect(b.state.feature('fix')['filterApps'], isTrue);
    await b.setSetting(SettingKeys.filterOffApps, 'Firefox,Quran Player');
    expect(File('${dir.path}/cfg/islamic-mute/filter_off_apps').readAsLinesSync(), ['Firefox', 'Quran Player']);
    // no pactl here: only the apps already chosen are offered
    final apps = await b.invoke('fix.apps') as List;
    expect(apps.map((a) => (a as Map)['package']), containsAll(['Firefox', 'Quran Player']));
    await b.setSetting(SettingKeys.filterOffApps, '');
    expect(File('${dir.path}/cfg/islamic-mute/filter_off_apps').existsSync(), isFalse);
  });

  test('notes: added, shown, counted in the snapshot, deleted', () async {
    final b = await DesktopBackend.open(
        file: File('${dir.path}/s.json'), licencesDir: dir, findEngine: false, findBlur: false, poll: null);
    final fix = b.state.feature('fix');
    expect(fix['filterApps'], isFalse, reason: 'no engine: nothing to leave unfiltered');
    expect(fix['notes'], 0);
    expect(fix.containsKey('blurApps'), isFalse);
    expect(fix.containsKey('handCover'), isFalse);
    expect(await b.invoke('fix.note', {'kind': 'missed', 'where': 'filter'}), 1);
    expect(await b.invoke('fix.note', {'kind': 'wrong', 'where': 'screen'}), 2);
    expect(b.state.feature('fix')['notes'], 2);
    final text = await b.invoke('fix.notes') as String;
    expect(text, contains('hidden by mistake (from screen)'));
    expect(text.indexOf('hidden by mistake'), lessThan(text.indexOf('missed something')), reason: 'newest first');
    expect(File('${dir.path}/fix_notes.txt').existsSync(), isTrue);
    await expectLater(b.invoke('fix.note', {'kind': 'other'}), throwsA(isA<BackendException>()));
    await b.invoke('fix.clearNotes');
    expect(b.state.feature('fix')['notes'], 0);
    expect(File('${dir.path}/fix_notes.txt').existsSync(), isFalse);
  });
}
