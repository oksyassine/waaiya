import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_desktop/links.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

Map<String, Object?> f(String id,
        {String? v, String? a, String ext = 'mp4', int? w, int? h, num? tbr, num? abr, String protocol = 'https', int? ch}) =>
    {
      'format_id': id, 'url': 'https://x/$id', 'protocol': protocol, 'ext': ext, 'vcodec': ?v, 'acodec': ?a, //
      'width': ?w, 'height': ?h, 'tbr': ?tbr, 'abr': ?abr, 'audio_channels': ?ch,
    };

/// A YouTube-like page: H.264 video-only in several sizes, VP9, AAC and Opus audio, a storyboard.
final youtube = <String, Object?>{
  'title': 'A talk',
  'extractor_key': 'Youtube',
  'duration': 125.4,
  'formats': [
    f('sb0', v: 'none', a: 'none', ext: 'mhtml', protocol: 'mhtml'),
    f('139', v: 'none', a: 'mp4a.40.5', ext: 'm4a', abr: 48),
    f('140', v: 'none', a: 'mp4a.40.2', ext: 'm4a', abr: 129),
    f('140-drc', v: 'none', a: 'mp4a.40.2', ext: 'm4a', abr: 130),
    f('251', v: 'none', a: 'opus', ext: 'webm', abr: 140),
    f('18', v: 'avc1.42001E', a: 'mp4a.40.2', w: 640, h: 360, tbr: 500),
    f('136', v: 'avc1.4d401f', a: 'none', w: 1280, h: 720, tbr: 1500),
    f('137', v: 'avc1.640028', a: 'none', w: 1920, h: 1080, tbr: 3000),
    f('299', v: 'avc1.64002a', a: 'none', w: 1920, h: 1080, tbr: 4500),
    f('400', v: 'av01.0.12M.08', a: 'none', w: 2560, h: 1440, tbr: 6000),
    f('401', v: 'avc1.640033', a: 'none', w: 3840, h: 2160, tbr: 12000),
    f('248', v: 'vp9', a: 'none', ext: 'webm', w: 1920, h: 1080, tbr: 2500),
  ],
};

void main() {
  group('pickFormats (im_links.py _pick, up to 1080p)', () {
    test('YouTube: the best H.264 within 1080p + the best AAC (never the DRC copy)', () {
      final c = pickFormats(youtube);
      expect(c.video!['format_id'], '299');
      expect(c.audio!['format_id'], '140');
      expect(c.progressive, isNull);
      expect(c.hasVideo, isTrue);
    });

    test('at the same size, a plain file before HLS pieces (known size: real progress)', () {
      final c = pickFormats({
        'formats': [
          f('312', v: 'avc1.64002A', a: 'none', w: 1920, h: 1080, tbr: 9000, protocol: 'm3u8_native'),
          f('299', v: 'avc1.64002A', a: 'none', w: 1920, h: 1080, tbr: 3000),
          f('140', v: 'none', a: 'mp4a.40.2', ext: 'm4a'),
        ],
      });
      expect(c.video!['format_id'], '299');
    });

    test('portrait videos count by their short side (a 1080x1920 reel is 1080p)', () {
      final c = pickFormats({
        'formats': [
          f('v1', v: 'avc1', a: 'none', w: 1080, h: 1920, tbr: 3000),
          f('v2', v: 'avc1', a: 'none', w: 720, h: 1280, tbr: 1500),
          f('a', v: 'none', a: 'mp4a.40.2', ext: 'm4a', abr: 128),
        ],
      });
      expect(c.video!['format_id'], 'v1');
    });

    test('every video larger than 1080p: the smallest of them, never audio only', () {
      final c = pickFormats({
        'formats': [
          f('4k', v: 'avc1', a: 'none', w: 3840, h: 2160),
          f('2k', v: 'avc1', a: 'none', w: 2560, h: 1440),
          f('a', v: 'none', a: 'mp4a.40.2', ext: 'm4a'),
        ],
      });
      expect(c.video!['format_id'], '2k');
    });

    test('TikTok: one MP4 with both (HEVC left out)', () {
      final c = pickFormats({
        'formats': [
          f('h265', v: 'h265', a: 'aac', w: 1080, h: 1920),
          f('h264', v: 'h264', a: 'aac', w: 576, h: 1024, tbr: 900),
        ],
      });
      expect(c.progressive!['format_id'], 'h264');
    });

    test('a direct MP4 link (generic extractor): no codec information, taken as progressive', () {
      final c = pickFormats({'url': 'http://127.0.0.1/clip.mp4', 'ext': 'mp4', 'protocol': 'http', 'format_id': '0'});
      expect(c.progressive!['format_id'], '0');
    });

    test('only VP9 video: audio only (Opus when there is no AAC: ffmpeg decodes it here)', () {
      final c = pickFormats({
        'formats': [
          f('248', v: 'vp9', a: 'none', ext: 'webm', w: 1920, h: 1080),
          f('251', v: 'none', a: 'opus', ext: 'webm', abr: 140),
        ],
      });
      expect(c.hasVideo, isFalse);
      expect(c.audio!['format_id'], '251');
    });

    test('stereo before 5.1', () {
      final c = pickFormats({
        'formats': [
          f('v', v: 'avc1', a: 'none', w: 1280, h: 720),
          f('51', v: 'none', a: 'mp4a.40.2', ext: 'm4a', abr: 384, ch: 6),
          f('20', v: 'none', a: 'mp4a.40.2', ext: 'm4a', abr: 128, ch: 2),
        ],
      });
      expect(c.audio!['format_id'], '20');
    });

    test('nothing usable: no_format', () {
      expect(() => pickFormats({'formats': [f('sb', v: 'none', a: 'none', ext: 'mhtml', protocol: 'mhtml')]}),
          throwsA(isA<LinkError>().having((e) => e.code, 'code', 'no_format')));
    });
  });

  group('resolvedFrom', () {
    test('title, site, duration', () {
      final r = resolvedFrom('https://youtu.be/x', youtube);
      expect(r.meta.title, 'A talk');
      expect(r.meta.site, 'Youtube');
      expect(r.meta.durationSec, 125);
      expect(r.meta.hasVideo, isTrue);
      expect(r.meta.audioOnly, isFalse);
    });

    test('a playlist is refused', () {
      expect(() => resolvedFrom('u', {'_type': 'playlist', 'entries': []}),
          throwsA(isA<LinkError>().having((e) => e.code, 'code', 'playlist')));
    });

    test('a page with video of which only the sound can be used says so', () {
      final r = resolvedFrom('u', {
        'formats': [f('248', v: 'vp9', a: 'none', ext: 'webm'), f('140', v: 'none', a: 'mp4a.40.2', ext: 'm4a')],
      });
      expect(r.meta.audioOnly, isTrue);
      expect(r.meta.hasVideo, isFalse);
    });

    test('a live stream without a usable format can still be watched', () {
      final r = resolvedFrom('u', {'is_live': true, 'formats': [f('hls', v: 'vp9', a: 'opus', protocol: 'm3u8_native', ext: 'webm')]});
      expect(r.meta.isLive, isTrue);
      expect(r.choice, isNull);
    });
  });

  test("yt-dlp's errors become the app's codes", () {
    expect(linkErrorFrom('ERROR: [Instagram] x: Requested content is not available, rate-limit reached or login required').code,
        'limited');
    expect(linkErrorFrom('ERROR: [Instagram] x: This content may be inappropriate: use --cookies').code, 'login');
    expect(linkErrorFrom('ERROR: Unsupported URL: https://example.com/').code, 'unsupported_site');
    expect(linkErrorFrom('ERROR: HTTP Error 429: Too Many Requests').code, 'limited');
    final e = linkErrorFrom('WARNING: x\nERROR: [youtube] abc: Video unavailable');
    expect(e.code, 'failed');
    expect(e.detail, '[youtube] abc: Video unavailable');
  });

  test('findLink: the first web link in a shared text', () {
    expect(findLink('see https://www.tiktok.com/@a/video/1?x=2 now').toString(), 'https://www.tiktok.com/@a/video/1?x=2');
    expect(findLink('ftp://x/y'), isNull);
    expect(findLink('no link'), isNull);
    expect(findLink('https://'), isNull);
  });

  test('file names: Windows-safe, at most 80, never empty, unique', () {
    expect(fileBaseName('a/b: c? "d" <e> | f*'), 'a b c d e f');
    expect(fileBaseName('...'), 'Waaiya');
    expect(fileBaseName('CON'), 'Waaiya');
    expect(fileBaseName('x' * 120).length, 80);
    expect(fileBaseName('Trailing dot.'), 'Trailing dot');
    final taken = {r'C:\V\T.mp4', r'C:\V\T (2).mp4'};
    expect(uniquePath(r'C:\V', 'T', '.mp4', exists: taken.contains), r'C:\V\T (3).mp4');
    expect(uniquePath('/v', 'T', '.m4a', exists: (_) => false), '/v/T.m4a');
  });

  test('progress lines', () {
    expect(parseProgress('WAAIYA 100 1000 NA'), (100, 1000));
    expect(parseProgress('WAAIYA 100 NA 2000.5'), (100, 2001));
    expect(parseProgress('WAAIYA 5 NA NA'), (5, 0));
    expect(parseProgress('[download] 5%'), isNull);
  });

  group('LinkSaver with fake tools', () {
    late Directory tmp;
    late FakeTools fake;
    late List<LinkSaveInfo> statuses;
    late LinkSaver saver;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('waaiya-links-test-');
      fake = FakeTools(youtube);
      statuses = [];
      saver = LinkSaver(
        const LinkTools(
            ytDlp: 'yt-dlp', qjs: 'qjs', ffmpeg: 'ffmpeg', imProcess: 'im-process', model: 'm.onnx', detector: 'd.onnx'),
        workDir: '${tmp.path}/work',
        videosDir: '${tmp.path}/Videos/Waaiya',
        musicDir: '${tmp.path}/Music/Waaiya',
        onStatus: statuses.add,
        start: fake.start,
        kill: (p) async => p.kill(),
        windows: false,
      );
    });

    tearDown(() => tmp.deleteSync(recursive: true));

    List<String> saved() => [
          for (final d in ['Videos', 'Music'])
            if (Directory('${tmp.path}/$d/Waaiya').existsSync())
              ...Directory('${tmp.path}/$d/Waaiya').listSync().map((e) => e.uri.pathSegments.last),
        ];
    bool workEmpty() =>
        !Directory('${tmp.path}/work').existsSync() ||
        Directory('${tmp.path}/work').listSync().every((e) => e.path.endsWith('cache'));

    test('resolve runs yt-dlp -J with QuickJS and no config', () async {
      final r = await saver.resolve('watch https://www.youtube.com/watch?v=x');
      expect(r.meta.title, 'A talk');
      final args = fake.calls.first;
      expect(args.first, 'yt-dlp');
      expect(args, containsAllInOrder(['--no-config', '--no-js-runtimes', '--js-runtimes', 'quickjs:qjs', '-J']));
      expect(args.last, 'https://www.youtube.com/watch?v=x');
    });

    test('resolve: yt-dlp fails -> the code', () async {
      fake.resolveError = 'ERROR: Unsupported URL: https://example.com/';
      await expectLater(saver.resolve('https://example.com/'),
          throwsA(isA<LinkError>().having((e) => e.code, 'code', 'unsupported_site')));
    });

    test('save: download both, filter, the file appears in Videos\\Waaiya, the work folder is gone', () async {
      final r = await saver.resolve('https://youtu.be/x');
      await saver.save(r);
      expect(saver.status.phase, LinkSavePhase.done, reason: '${saver.status.error}');
      expect(saved(), ['A talk.mp4']);
      expect(File(saver.status.path!).readAsStringSync(), 'filtered+video');
      expect(workEmpty(), isTrue);
      expect(statuses.map((s) => s.phase).toSet(),
          containsAll([LinkSavePhase.downloading, LinkSavePhase.filtering, LinkSavePhase.done]));
      // the formats chosen, then the filter chain
      expect(fake.calls.where((c) => c.contains('--load-info-json')).map((c) => c[c.indexOf('-f') + 1]), ['299', '140']);
      final imp = fake.calls.firstWhere((c) => c.first == 'im-process');
      expect(imp, containsAllInOrder(['-m', 'm.onnx', '--raw']));
      expect(imp, isNot(contains('--mute-female-singing')));
      final enc = fake.calls.last;
      expect(enc, containsAllInOrder(['-map', '1:v:0', '-map', '0:a:0', '-c:v', 'copy', '-c:a', 'aac']));
      // a second save of the same video keeps both
      await saver.save(await saver.resolve('https://youtu.be/x'));
      expect(saved()..sort(), ['A talk (2).mp4', 'A talk.mp4']);
    });

    test("women's singing on: the detector, fail-closed", () async {
      await saver.save(await saver.resolve('https://youtu.be/x'), singing: true);
      final imp = fake.calls.firstWhere((c) => c.first == 'im-process');
      expect(imp, containsAllInOrder(['-d', 'd.onnx', '--mute-female-singing', '--fail-closed']));
    });

    test('sound only goes to Music\\Waaiya as .m4a', () async {
      fake.info = {
        'title': 'Nasheed',
        'formats': [f('140', v: 'none', a: 'mp4a.40.2', ext: 'm4a')],
      };
      await saver.save(await saver.resolve('https://youtu.be/x'));
      expect(saver.status.phase, LinkSavePhase.done);
      expect(saved(), ['Nasheed.m4a']);
      expect(fake.calls.last, isNot(contains('-c:v')));
    });

    test('the filter fails: nothing is saved, the reason is kept, no files left', () async {
      fake.imProcessExit = 1;
      await saver.save(await saver.resolve('https://youtu.be/x'));
      expect(saver.status.phase, LinkSavePhase.failed);
      expect(saver.status.error!.code, 'failed');
      expect(saver.status.error!.detail, contains('im-process: exit 1'));
      expect(saved(), isEmpty);
      expect(workEmpty(), isTrue);
    });

    test('a download fails: nothing is saved', () async {
      fake.downloadExit = 1;
      await saver.save(await saver.resolve('https://youtu.be/x'));
      expect(saver.status.phase, LinkSavePhase.failed);
      expect(saved(), isEmpty);
      expect(workEmpty(), isTrue);
    });

    test('cancel while downloading: cancelled, nothing saved, the tools are stopped', () async {
      fake.holdDownload = true;
      final r = await saver.resolve('https://youtu.be/x');
      final done = saver.save(r);
      while (!fake.downloading) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(saver.busy, isTrue);
      expect(() => saver.save(r), throwsA(isA<LinkError>().having((e) => e.code, 'code', 'busy')));
      await saver.cancel();
      await done;
      expect(saver.status.phase, LinkSavePhase.failed);
      expect(saver.status.error!.code, 'cancelled');
      expect(saved(), isEmpty);
      expect(workEmpty(), isTrue);
      expect(fake.killed, isNotEmpty);
    });

    test('a live stream is not saved', () async {
      fake.info = {...youtube, 'is_live': true};
      final r = await saver.resolve('https://youtu.be/x');
      expect(() => saver.save(r), throwsA(isA<LinkError>().having((e) => e.code, 'code', 'live')));
    });
  });
}

/// Pretends to be yt-dlp, ffmpeg and im-process: records the command lines and writes what they would.
class FakeTools {
  FakeTools(this.info);
  Map<String, Object?> info;
  String? resolveError;
  int imProcessExit = 0;
  int downloadExit = 0;
  bool holdDownload = false;
  bool downloading = false;
  final calls = <List<String>>[];
  final killed = <FakeProcess>[];

  Future<Process> start(String exe, List<String> args, {String? workingDirectory, Map<String, String>? environment}) async {
    calls.add([exe, ...args]);
    final p = FakeProcess(this);
    unawaited(_run(p, exe, args));
    return p;
  }

  Future<void> _run(FakeProcess p, String exe, List<String> args) async {
    await Future<void>.delayed(Duration.zero);
    if (exe == 'yt-dlp' && args.contains('-J')) {
      if (resolveError != null) return p.finish(1, err: resolveError!);
      return p.finish(0, out: jsonEncode(info));
    }
    if (exe == 'yt-dlp') {
      final out = args[args.indexOf('-o') + 1].replaceAll('%(ext)s', 'mp4');
      p.emit('WAAIYA 10 100 NA\n');
      if (holdDownload) {
        downloading = true;
        return; // until killed
      }
      if (downloadExit != 0) return p.finish(downloadExit, err: 'ERROR: unable to download video data: HTTP Error 403');
      File(out).writeAsStringSync(out.contains('video') ? 'video' : 'audio');
      return p.finish(0);
    }
    if (exe == 'ffmpeg' && args.last == 'pipe:1') {
      p.emit('pcm' * 1000); // decoded sound
      return p.finish(0);
    }
    if (exe == 'im-process') {
      final data = await p.stdinBytes();
      if (imProcessExit != 0) return p.finish(imProcessExit, err: 'engine: cannot load the model');
      p.emit(utf8.decode(data));
      return p.finish(0);
    }
    if (exe == 'ffmpeg') {
      final data = await p.stdinBytes();
      if (data.isEmpty) return p.finish(1, err: 'no input');
      File(args.last).writeAsStringSync(args.contains('-c:v') ? 'filtered+video' : 'filtered');
      return p.finish(0);
    }
    p.finish(127, err: 'unknown $exe');
  }
}

class FakeProcess implements Process {
  FakeProcess(this.tools);
  final FakeTools tools;
  final _out = StreamController<List<int>>();
  final _err = StreamController<List<int>>();
  final _in = StreamController<List<int>>();
  final _exit = Completer<int>();
  late final IOSink _sink = IOSink(_in.sink);
  final _inBytes = <int>[];
  late final Future<void> _inDone = _in.stream.forEach(_inBytes.addAll);

  void emit(String s) => _out.add(utf8.encode(s));

  Future<List<int>> stdinBytes() async {
    await _inDone;
    return _inBytes;
  }

  void finish(int code, {String out = '', String err = ''}) {
    if (_exit.isCompleted) return;
    if (out.isNotEmpty) _out.add(utf8.encode(out));
    if (err.isNotEmpty) _err.add(utf8.encode(err));
    _out.close();
    _err.close();
    _exit.complete(code);
  }

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    tools.killed.add(this);
    finish(-1);
    return true;
  }

  @override
  Future<int> get exitCode => _exit.future;
  @override
  int get pid => 0;
  @override
  IOSink get stdin {
    unawaited(_inDone); // start collecting
    return _sink;
  }

  @override
  Stream<List<int>> get stdout => _out.stream;
  @override
  Stream<List<int>> get stderr => _err.stream;
}
