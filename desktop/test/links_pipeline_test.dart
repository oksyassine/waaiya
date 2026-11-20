library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_desktop/links.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

/// "Save without music" with the real tools (yt-dlp, QuickJS, ffmpeg, im-process and the voice model), on a clip
/// served from this machine (yt-dlp's generic extractor takes a direct .mp4 link): no YouTube needed.
///
///     WAAIYA_LINK_ENGINE=<bundle>\engine flutter test test/links_pipeline_test.dart
///
/// Skipped without WAAIYA_LINK_ENGINE (CI's windows.yml `desktop` job sets it to the bundled app's engine folder).
final engine = Platform.environment['WAAIYA_LINK_ENGINE'];
final clip = File('test/fixtures/clip.mp4'); // 6 s, 320x240 H.264 + AAC stereo (a tone and noise)

void main() {
  final tools = engine == null ? null : LinkTools.find(engine!, windows: Platform.isWindows);
  final skip = engine == null
      ? 'WAAIYA_LINK_ENGINE not set'
      : tools == null
          ? 'the link tools are not all in $engine'
          : null;

  late HttpServer server;
  late Directory tmp;
  var slow = false;

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final bytes = await clip.readAsBytes();
      req.response.headers
        ..contentType = ContentType('video', 'mp4')
        ..contentLength = bytes.length;
      if (!slow) {
        req.response.add(bytes);
      } else {
        // a slow site: 2 KB every 100 ms (cancel while downloading)
        for (var i = 0; i < bytes.length; i += 2048) {
          req.response.add(bytes.sublist(i, i + 2048 > bytes.length ? bytes.length : i + 2048));
          try {
            await req.response.flush();
          } on Object {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
      try {
        await req.response.close();
      } on Object {
        // the downloader went away
      }
    });
  });

  tearDownAll(() => server.close(force: true));

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('waaiya-pipeline-');
    slow = false;
  });
  tearDown(() async {
    for (var i = 0; i < 20; i++) {
      try {
        tmp.deleteSync(recursive: true);
        return;
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
  });

  String url() => 'http://127.0.0.1:${server.port}/talk/clip.mp4';
  String sep() => Platform.pathSeparator;

  LinkSaver saver(LinkTools t, List<LinkSaveInfo> seen) => LinkSaver(
        t,
        workDir: '${tmp.path}${sep()}work',
        videosDir: '${tmp.path}${sep()}Videos${sep()}Waaiya',
        musicDir: '${tmp.path}${sep()}Music${sep()}Waaiya',
        onStatus: seen.add,
        windows: Platform.isWindows,
      );

  List<File> saved() => [
        for (final d in ['Videos', 'Music'])
          if (Directory('${tmp.path}${sep()}$d').existsSync())
            ...Directory('${tmp.path}${sep()}$d').listSync(recursive: true).whereType<File>(),
      ];

  bool workClean() {
    final w = Directory('${tmp.path}${sep()}work');
    return !w.existsSync() || w.listSync().every((e) => e.path.endsWith('cache'));
  }

  /// What ffmpeg says of a file: (duration in s, video codec, audio codec).
  Future<(double, String?, String?)> probe(LinkTools t, String path) async {
    final r = await Process.run(t.ffmpeg, ['-hide_banner', '-i', path]);
    final err = '${r.stderr}';
    final d = RegExp(r'Duration: (\d+):(\d+):(\d+\.\d+)').firstMatch(err);
    final secs = d == null ? -1.0 : int.parse(d[1]!) * 3600 + int.parse(d[2]!) * 60 + double.parse(d[3]!);
    return (
      secs,
      RegExp(r'Video: (\w+)').firstMatch(err)?.group(1),
      RegExp(r'Audio: (\w+)').firstMatch(err)?.group(1),
    );
  }

  test('a direct MP4 link is resolved by yt-dlp', () async {
    final r = await saver(tools!, []).resolve(url());
    expect(r.meta.site, isNotEmpty);
    expect(r.choice?.progressive, isNotNull);
    expect(r.meta.isLive, isFalse);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('saved: video copied, sound filtered, same length; only the finished file is in Videos', () async {
    final seen = <LinkSaveInfo>[];
    final s = saver(tools!, seen);
    await s.save(await s.resolve(url()));
    expect(s.status.phase, LinkSavePhase.done, reason: '${s.status.error?.code} ${s.status.error?.detail}');
    final files = saved();
    expect(files.map((f) => f.path), [s.status.path]);
    expect(s.status.path, endsWith('.mp4'));
    final (dur, v, a) = await probe(tools, s.status.path!);
    final (inDur, _, _) = await probe(tools, clip.path);
    expect(v, 'h264');
    expect(a, 'aac');
    expect((dur - inDur).abs(), lessThan(0.15), reason: 'in $inDur s, out $dur s');
    expect(workClean(), isTrue);
    expect(seen.map((x) => x.phase), containsAllInOrder([LinkSavePhase.downloading, LinkSavePhase.filtering, LinkSavePhase.done]));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));

  test("women's singing on: the detector runs too (fail-closed)", () async {
    final s = saver(tools!, []);
    await s.save(await s.resolve(url()), singing: true);
    expect(s.status.phase, LinkSavePhase.done, reason: '${s.status.error?.code} ${s.status.error?.detail}');
    expect(saved(), hasLength(1));
  }, skip: skip ?? (tools?.detector == null ? 'no detector in this bundle' : null), timeout: const Timeout(Duration(minutes: 3)));

  test('the filter cannot load its model: nothing is saved, nothing is left', () async {
    final t = tools!;
    final broken = LinkTools(
        ytDlp: t.ytDlp, qjs: t.qjs, ffmpeg: t.ffmpeg, imProcess: t.imProcess, model: '${tmp.path}${sep()}missing.onnx');
    final s = saver(broken, []);
    await s.save(await s.resolve(url()));
    expect(s.status.phase, LinkSavePhase.failed);
    expect(s.status.error!.detail, contains('im-process'));
    expect(saved(), isEmpty);
    expect(workClean(), isTrue);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));

  test('cancel while downloading: nothing is saved, nothing is left', () async {
    final s = saver(tools!, []);
    final r = await s.resolve(url());
    slow = true;
    final done = s.save(r);
    await Future<void>.delayed(const Duration(seconds: 3));
    expect(s.status.phase, LinkSavePhase.downloading);
    await s.cancel();
    await done.timeout(const Duration(seconds: 30));
    expect(s.status.phase, LinkSavePhase.failed);
    expect(s.status.error!.code, 'cancelled');
    expect(saved(), isEmpty);
    expect(workClean(), isTrue);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
