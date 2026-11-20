import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_desktop/desktop_backend.dart';
import 'package:waaiya_desktop/filter_host.dart';
import 'package:waaiya_desktop/links.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

import 'links_test.dart' show FakeTools, youtube;

/// A filter that starts (or not) on command.
class FakeFilter implements FilterHost {
  FakeFilter({this.starts = true});
  bool starts;
  bool running = false;
  int startCalls = 0;

  @override
  Future<BackendMessage?> start() async {
    startCalls++;
    if (!starts) return const BackendMessage('start_failed', 'no sound device');
    running = true;
    return null;
  }

  @override
  Future<BackendMessage?> stop() async {
    running = false;
    return null;
  }

  @override
  Future<EngineStatus> status() async => EngineStatus(
      sinkUp: running, active: running ? 'active' : 'inactive', autostart: false, filter: running ? 'running' : '');

  @override
  String get bundledVersion => '0.2.12-test';
  @override
  String? get installedVersion => bundledVersion;
  @override
  bool get hasDetector => false;
  @override
  bool? get stereoSet => null;
  @override
  bool? get keepSilentSet => null;
  @override
  void writeNotice(String title, String text) {}
  @override
  Future<BackendMessage?> preflight() async => null;
  @override
  Future<BackendMessage?> installIfNeeded() async => null;
  @override
  Future<BackendMessage?> setWomenSinging(bool on) async => null;
  @override
  Future<BackendMessage?> setStereo(bool on) async => null;
  @override
  Future<BackendMessage?> setKeepSilent(bool on) async => null;
  @override
  Future<BackendMessage?> reload() async => null;
  @override
  Future<BackendMessage?> setAutostart(bool on) async => null;
  @override
  Future<String> journal({int lines = 6}) async => '';
  @override
  String filterLogTail({int maxBytes = 3000}) => '';
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('waaiya_links_backend'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<(DesktopBackend, List<String>)> open(FakeFilter f, {LinkTools? tools, ProcessStarter? processes}) async {
    final opened = <String>[];
    final b = await DesktopBackend.open(
      file: File('${dir.path}/s.json'),
      licencesDir: dir,
      engine: f,
      findBlur: false,
      platform: 'windows',
      poll: null,
      linkTools: tools,
      findLinkTools: false,
      linkWorkDir: '${dir.path}/work',
      linkFolders: ('${dir.path}/Videos', '${dir.path}/Music'),
      linkProcesses: processes,
      openUrl: (u) async {
        opened.add(u);
        return true;
      },
    );
    return (b, opened);
  }

  test('without the save tools (the Store package): Links watches only, offline', () async {
    final (b, _) = await open(FakeFilter());
    expect(b.state.capabilities.links, isTrue);
    expect(b.state.capabilities.linkPage, isTrue);
    expect(b.state.capabilities.linkSave, isFalse);
    final m = await b.resolveLink('look: https://www.youtube.com/watch?v=x');
    expect(m.site, 'www.youtube.com');
    expect(m.url, 'https://www.youtube.com/watch?v=x');
    await expectLater(b.saveLink('https://www.youtube.com/watch?v=x'),
        throwsA(isA<BackendException>().having((e) => e.code, 'code', 'unsupported')));
    await expectLater(b.resolveLink('no link'),
        throwsA(isA<BackendException>().having((e) => e.code, 'code', 'invalid_url')));
  });

  test('with the tools: Save is offered', () async {
    const t = LinkTools(ytDlp: 'y', qjs: 'q', ffmpeg: 'f', imProcess: 'i', model: 'm');
    final (b, _) = await open(FakeFilter(), tools: t);
    expect(b.state.capabilities.linkSave, isTrue);
  });

  test('Watch starts the filter first, then opens the browser', () async {
    final f = FakeFilter();
    final (b, opened) = await open(f);
    await b.watchLink('https://vm.tiktok.com/x/');
    expect(f.startCalls, 1);
    expect(b.state.filter.state, FilterState.filtering);
    expect(opened, ['https://vm.tiktok.com/x/']);
    // already filtering: no second start
    await b.watchLink('https://youtu.be/y');
    expect(f.startCalls, 1);
    expect(opened, hasLength(2));
  });

  test('the filter does not start: the link is never opened unfiltered', () async {
    final f = FakeFilter(starts: false);
    final (b, opened) = await open(f);
    await expectLater(b.watchLink('https://youtu.be/y'),
        throwsA(isA<BackendException>().having((e) => e.code, 'code', 'filter_failed')));
    expect(opened, isEmpty);
  });

  test('not a web link: nothing starts, nothing opens', () async {
    final f = FakeFilter();
    final (b, opened) = await open(f);
    await expectLater(b.watchLink('javascript:alert(1)'),
        throwsA(isA<BackendException>().having((e) => e.code, 'code', 'invalid_url')));
    await expectLater(b.watchLink('file:///C:/Windows/System32/calc.exe'),
        throwsA(isA<BackendException>().having((e) => e.code, 'code', 'invalid_url')));
    expect(f.startCalls, 0);
    expect(opened, isEmpty);
  });

  test('Save right after Open does not ask the site again (YouTube takes 15-20 s)', () async {
    final fake = FakeTools(youtube);
    const t = LinkTools(ytDlp: 'yt-dlp', qjs: 'q', ffmpeg: 'ffmpeg', imProcess: 'im-process', model: 'm');
    final (b, _) = await open(FakeFilter(), tools: t, processes: fake.start);
    b.links = LinkSaver(t,
        workDir: '${dir.path}/work',
        videosDir: '${dir.path}/Videos',
        musicDir: '${dir.path}/Music',
        start: fake.start,
        kill: (p) async => p.kill(),
        windows: false,
        onStatus: (st) => b.emit(b.state.copyWith(linkSave: st)));
    int resolves() => fake.calls.where((c) => c.contains('-J')).length;
    final m = await b.resolveLink('https://youtu.be/x');
    expect(m.title, 'A talk');
    await b.saveLink('https://youtu.be/x');
    while (b.state.linkSave.busy) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(b.state.linkSave.phase, LinkSavePhase.done, reason: '${b.state.linkSave.error}');
    expect(resolves(), 1);
    // another Open asks again
    await b.resolveLink('https://youtu.be/x');
    expect(resolves(), 2);
  });
}
