import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:waaiya_ui/waaiya_ui.dart';

/// The Links page on the computer (Android: LinkActivity, LinkExport.kt, python/im_links.py).
///
/// Watch: the system filter already covers the browser, so the app makes sure the filter runs, then opens the link
/// in the default browser (DesktopBackend.watchLink). Never while the filter is not running.
///
/// Save without music ([LinkSaver]), with the tools in the bundle ([LinkTools]):
///  1. `yt-dlp -J` says what the link is and which formats it has ([pickFormats], the rules of im_links.py `_pick`);
///  2. yt-dlp downloads the chosen formats (video and audio apart, or one file with both) into a private folder;
///  3. `ffmpeg` decodes the sound -> `im-process --raw` (the same engine as the live filter, delay-compensated, the
///     women's-singing detector when that option is on, fail-closed) -> `ffmpeg` encodes AAC and copies the video;
///  4. only then the file is moved to Videos\Waaiya (Music\Waaiya for sound only). Any error or a cancel deletes the
///     private folder: the user's folders only ever receive a fully filtered file.
///
/// The Microsoft Store package has no save tools (desktop/tool/make_msix.ps1 leaves them out: the Store's rules
/// forbid saving from sites whose terms do not allow it); there the page only watches.

/// A failure with one of [linkErrorCodes] (or `cancelled`), as Android's LinkError.
class LinkError implements Exception {
  const LinkError(this.code, [this.detail = '']);
  final String code;
  final String detail;
  @override
  String toString() => detail.isEmpty ? code : '$code: $detail';
}

/// The save tools in the bundle: `engine\links\{yt-dlp,qjs,ffmpeg}.exe` and `engine\im-process.exe` with the voice
/// model (and the women's-singing detector when the bundle has it).
class LinkTools {
  const LinkTools({
    required this.ytDlp,
    required this.qjs,
    required this.ffmpeg,
    required this.imProcess,
    required this.model,
    this.detector,
  });

  final String ytDlp;
  final String qjs;
  final String ffmpeg;
  final String imProcess;
  final String model;
  final String? detector;

  /// The tools under [engineDir], or null when one is missing (the Store package, a development run).
  static LinkTools? find(String engineDir, {bool windows = true}) {
    final sep = windows ? r'\' : '/';
    final exe = windows ? '.exe' : '';
    String p(String rel) => '$engineDir$sep${rel.replaceAll('/', sep)}';
    final t = LinkTools(
      ytDlp: p('links/yt-dlp$exe'),
      qjs: p('links/qjs$exe'),
      ffmpeg: p('links/ffmpeg$exe'),
      imProcess: p('im-process$exe'),
      model: p('models/dfn3/dfn3_stream_int8.onnx'),
      detector: File(p('models/detector/detector_v1.onnx')).existsSync() ? p('models/detector/detector_v1.onnx') : null,
    );
    return [t.ytDlp, t.qjs, t.ffmpeg, t.imProcess, t.model].every((f) => File(f).existsSync()) ? t : null;
  }
}

/// The web link in [text]: the first http(s) address with a host (pasted text may have words around it), or null.
Uri? findLink(String? text) {
  if (text == null) return null;
  final m = RegExp(r'https?://[^\s<>"]+', caseSensitive: false).firstMatch(text.trim());
  if (m == null) return null;
  final u = Uri.tryParse(m.group(0)!);
  return u != null && u.host.isNotEmpty && (u.scheme == 'http' || u.scheme == 'https') ? u : null;
}

/// yt-dlp's error text -> a code (im_links.py). Instagram & co. refuse anonymous visitors only some of the time:
/// "rate-limit reached or login required" is a refusal to retry later, not proof the post is private.
LinkError linkErrorFrom(String stderr) {
  final low = stderr.toLowerCase();
  if (low.contains('rate-limit') || low.contains('rate limit') || low.contains('too many requests') ||
      low.contains('http error 429')) {
    return const LinkError('limited');
  }
  if (low.contains('logged-in') || low.contains('login') || low.contains('log in') || low.contains('cookies')) {
    return const LinkError('login');
  }
  if (stderr.contains('Unsupported URL')) return const LinkError('unsupported_site');
  final lines = stderr.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  final err = lines.lastWhere((l) => l.startsWith('ERROR:'), orElse: () => lines.isEmpty ? '' : lines.last);
  final d = err.replaceFirst('ERROR: ', '');
  return LinkError('failed', d.length > 300 ? d.substring(0, 300) : d);
}

/// What to download: separate video + audio, one file with both, or audio only (exactly one way is set).
class LinkChoice {
  const LinkChoice({this.video, this.audio, this.progressive});
  final Map<String, Object?>? video;
  final Map<String, Object?>? audio;
  final Map<String, Object?>? progressive;

  bool get hasVideo => video != null || progressive != null;
  List<Map<String, Object?>> get parts => [?progressive, ?video, ?audio];
}

String _s(Object? v) => v == null ? '' : '$v';
num _n(Object? v) => v is num ? v : 0;
bool _known(Object? v) => v != null && v != 'unknown';

/// The short side of a video format (a portrait 1080x1920 reel counts as 1080p), 0 if unknown.
int _shortSide(Map<String, Object?> f) {
  final w = _n(f['width']).toInt(), h = _n(f['height']).toInt();
  return w > 0 && h > 0 ? (w < h ? w : h) : (h > 0 ? h : w);
}

/// im_links.py `_best_video`: the largest within [maxSide]; if every one is larger, the smallest.
Map<String, Object?> _bestVideo(List<Map<String, Object?>> fs, int maxSide) {
  num rate(Map<String, Object?> f) => _n(f['tbr']) > 0 ? _n(f['tbr']) : _n(f['vbr']);
  int cmp(Map<String, Object?> a, Map<String, Object?> b) {
    final c = _shortSide(a).compareTo(_shortSide(b));
    return c != 0 ? c : rate(a).compareTo(rate(b));
  }

  final fit = fs.where((f) => _shortSide(f) > 0 && _shortSide(f) <= maxSide).toList();
  if (fit.isNotEmpty) return fit.reduce((a, b) => cmp(a, b) >= 0 ? a : b);
  final big = fs.where((f) => _shortSide(f) > maxSide).toList();
  if (big.isNotEmpty) {
    return big.reduce((a, b) {
      final c = _shortSide(a).compareTo(_shortSide(b));
      return c < 0 || (c == 0 && rate(a) >= rate(b)) ? a : b;
    });
  }
  return fs.reduce((a, b) => rate(a) >= rate(b) ? a : b);
}

/// im_links.py `_pick`, for a computer: H.264 video (copied into the saved file, never re-encoded; up to 1080p) +
/// the best audio, else one MP4 with both, else a direct MP4 link without codec information, else audio only.
/// ffmpeg decodes any audio here, so audio that is not AAC (Opus) is taken when there is no AAC.
/// Throws `no_format`.
LinkChoice pickFormats(Map<String, Object?> info, {int maxSide = 1080}) {
  final all = (info['formats'] is List ? (info['formats'] as List).whereType<Map>() : [info])
      .map((m) => m.cast<String, Object?>())
      .toList();
  const protocols = {
    'http', 'https', 'm3u8', 'm3u8_native', 'http_dash_segments', 'http_dash_segments_generator', '',
  };
  final fm = all
      .where((f) => protocols.contains(_s(f['protocol'])) && _s(f['url']).isNotEmpty)
      .where((f) => !_s(f['format_id']).contains('drc'))
      .toList();
  bool hasV(Map<String, Object?> f) => _known(f['vcodec']) && f['vcodec'] != 'none';
  bool hasA(Map<String, Object?> f) => _known(f['acodec']) && f['acodec'] != 'none';
  bool mp4(Map<String, Object?> f) => const {'mp4', 'm4v', 'mov'}.contains(f['ext']);
  bool avc(Map<String, Object?> f) => _s(f['vcodec']).startsWith('avc') || _s(f['vcodec']).startsWith('h264');
  bool aac(Map<String, Object?> f) =>
      _s(f['acodec']).startsWith('mp4a') || (f['ext'] == 'm4a' && f['acodec'] != null && f['acodec'] != 'none');

  // stereo/mono first (5.1 tracks are mixed down, but the voice model is made for 1-2 channels), then bitrate
  Map<String, Object?> bestAudio(List<Map<String, Object?>> fs) {
    int key(Map<String, Object?> f) => (_n(f['audio_channels']) == 0 || _n(f['audio_channels']) <= 2) ? 1 : 0;
    num br(Map<String, Object?> f) => _n(f['abr']) > 0 ? _n(f['abr']) : _n(f['tbr']);
    return fs.reduce((a, b) {
      final c = key(a).compareTo(key(b));
      return c > 0 || (c == 0 && br(a) >= br(b)) ? a : b;
    });
  }

  final video = fm.where((f) => hasV(f) && !hasA(f) && mp4(f) && avc(f)).toList();
  final aacOnly = fm.where((f) => hasA(f) && !hasV(f) && aac(f)).toList();
  final anyAudio = fm.where((f) => hasA(f) && !hasV(f)).toList();
  final audio = aacOnly.isNotEmpty ? aacOnly : anyAudio;
  final both = fm.where((f) => hasV(f) && f['acodec'] != 'none' && mp4(f) && avc(f)).toList();
  if (video.isNotEmpty && audio.isNotEmpty) {
    return LinkChoice(video: _bestVideo(video, maxSide), audio: bestAudio(audio));
  }
  if (both.isNotEmpty) return LinkChoice(progressive: _bestVideo(both, maxSide));
  // direct file links (generic extractor), Instagram's progressive files: no codec information; MP4 by extension
  final unknown = fm.where((f) => !_known(f['vcodec']) && f['acodec'] != 'none' && mp4(f)).toList();
  if (unknown.isNotEmpty) return LinkChoice(progressive: _bestVideo(unknown, maxSide));
  if (audio.isNotEmpty) return LinkChoice(audio: bestAudio(audio));
  final m4a = fm.where((f) => !_known(f['vcodec']) && !_known(f['acodec']) && f['ext'] == 'm4a').toList();
  if (m4a.isNotEmpty) return LinkChoice(audio: m4a.first);
  throw const LinkError('no_format');
}

/// A resolved link: the page's info (for yt-dlp's `--load-info-json`) and what will be saved.
class ResolvedLink {
  ResolvedLink(this.info, this.meta, this.choice);
  final Map<String, Object?> info;
  final LinkMeta meta;

  /// Null for a live stream (watch only).
  final LinkChoice? choice;
}

/// [info] (yt-dlp -J) -> what the page shows, and the formats. Throws `playlist`, `no_format`.
ResolvedLink resolvedFrom(String url, Map<String, Object?> info) {
  if (info['_type'] == 'playlist' || info['entries'] != null) throw const LinkError('playlist');
  final live = info['is_live'] == true;
  LinkChoice? choice;
  try {
    choice = pickFormats(info);
  } on LinkError {
    if (!live) rethrow;
  }
  final formats = info['formats'] is List ? (info['formats'] as List).whereType<Map>() : [info];
  final pageVideo = formats.any((f) => _known(f['vcodec']) && f['vcodec'] != 'none');
  final d = info['duration'];
  return ResolvedLink(
    info,
    LinkMeta(
      url: url,
      title: _s(info['title']),
      site: _s(info['extractor_key']).isNotEmpty ? _s(info['extractor_key']) : _s(info['extractor']),
      durationSec: d is num && d > 0 ? d.round() : null,
      isLive: live,
      hasVideo: choice?.hasVideo ?? pageVideo,
      audioOnly: pageVideo && choice != null && !choice.hasVideo,
    ),
    choice,
  );
}

/// A file name from a title (Android publishToGallery): no characters Windows refuses, at most 80, never empty.
String fileBaseName(String title) {
  var b = title.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (b.length > 80) b = b.substring(0, 80).trim();
  b = b.replaceAll(RegExp(r'[. ]+$'), ''); // Windows drops trailing dots and spaces
  const reserved = {'CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4', 'LPT1', 'LPT2', 'LPT3'};
  if (b.isEmpty || reserved.contains(b.toUpperCase())) return 'Waaiya';
  return b;
}

/// "Title.mp4", else "Title (2).mp4" ... (saving the same video twice keeps both).
String uniquePath(String dir, String base, String ext, {bool Function(String path)? exists}) {
  exists ??= (p) => File(p).existsSync();
  final sep = dir.contains(r'\') ? r'\' : '/';
  for (var i = 1; i < 100; i++) {
    final p = '$dir$sep${i == 1 ? base : '$base ($i)'}$ext';
    if (!exists(p)) return p;
  }
  return '$dir$sep$base ${DateTime.now().millisecondsSinceEpoch}$ext';
}

/// A yt-dlp progress line (our `--progress-template`): `WAAIYA <downloaded> <total> <estimate>` -> (done, total).
(int, int)? parseProgress(String line) {
  final m = RegExp(r'^WAAIYA (\d+) (\S+) (\S+)').firstMatch(line.trim());
  if (m == null) return null;
  final done = int.parse(m.group(1)!);
  final total = int.tryParse(m.group(2)!) ?? double.tryParse(m.group(3)!)?.round() ?? 0;
  return (done, total);
}

typedef ProcessStarter = Future<Process> Function(String exe, List<String> args,
    {String? workingDirectory, Map<String, String>? environment});

Future<Process> _start(String exe, List<String> args, {String? workingDirectory, Map<String, String>? environment}) =>
    Process.start(exe, args, workingDirectory: workingDirectory, environment: environment);

/// Runs the tools: resolve, then save one link at a time. [onStatus] gets every change of the save.
class LinkSaver {
  LinkSaver(
    this.tools, {
    required this.workDir,
    required this.videosDir,
    required this.musicDir,
    required this.onStatus,
    ProcessStarter? start,
    Future<void> Function(Process p)? kill,
    this.windows = true,
  })  : _startProcess = start ?? _start,
        _killHook = kill;

  final LinkTools tools;

  /// Private scratch space (`%LOCALAPPDATA%\Waaiya\links`): downloads and the unfinished output, deleted after.
  final String workDir;

  /// Where saved files go: `Videos\Waaiya`, `Music\Waaiya`.
  final String videosDir;
  final String musicDir;
  final void Function(LinkSaveInfo) onStatus;
  final ProcessStarter _startProcess;
  final Future<void> Function(Process p)? _killHook;
  final bool windows;

  LinkSaveInfo _status = const LinkSaveInfo();
  LinkSaveInfo get status => _status;
  bool _cancelled = false;
  final _running = <Process>{};

  String get _sep => windows ? r'\' : '/';

  void _set(LinkSaveInfo s) {
    _status = s;
    onStatus(s);
  }

  /// Python in yt-dlp.exe writes UTF-8 (titles in every script), whatever the console's code page.
  static const _env = {'PYTHONUTF8': '1', 'PYTHONIOENCODING': 'utf-8'};

  List<String> get _ytBase => [
        '--no-config',
        '--no-warnings',
        '--no-playlist',
        '--no-js-runtimes',
        '--js-runtimes',
        'quickjs:${tools.qjs}',
        '--socket-timeout',
        '20',
        '--cache-dir',
        '$workDir${_sep}cache',
      ];

  Future<Process> _spawn(String exe, List<String> args) async {
    final p = await _startProcess(exe, args, environment: _env);
    _running.add(p);
    unawaited(p.exitCode.whenComplete(() => _running.remove(p)));
    return p;
  }

  /// `yt-dlp -J`: what [url] is. Throws [LinkError].
  Future<ResolvedLink> resolve(String url) async {
    final u = findLink(url);
    if (u == null) throw const LinkError('invalid_url');
    final Process p;
    try {
      p = await _spawn(tools.ytDlp, [..._ytBase, '-J', '--', u.toString()]);
    } on ProcessException catch (e) {
      throw LinkError('failed', e.message);
    }
    unawaited(p.stdin.close());
    final out = p.stdout.transform(utf8.decoder).join();
    final err = p.stderr.transform(const Utf8Decoder(allowMalformed: true)).join();
    final code = await p.exitCode;
    final text = await out, errText = await err;
    if (code != 0) throw linkErrorFrom(errText);
    try {
      return resolvedFrom(u.toString(), (jsonDecode(text) as Map).cast<String, Object?>());
    } on FormatException {
      throw linkErrorFrom(errText);
    }
  }

  bool get busy => _status.busy;

  /// Stops the running save; it ends as failed/`cancelled` and nothing is kept.
  Future<void> cancel() async {
    if (!busy) return;
    _cancelled = true;
    for (final p in [..._running]) {
      await _kill(p);
    }
  }

  /// yt-dlp.exe is a PyInstaller program: the real work is in a child process, so the whole tree is ended.
  Future<void> _kill(Process p) async {
    final hook = _killHook;
    if (hook != null) return hook(p);
    if (windows) {
      try {
        await Process.run('taskkill', ['/PID', '${p.pid}', '/T', '/F']);
      } on ProcessException {
        // fall through
      }
    }
    p.kill(ProcessSignal.sigkill);
  }

  /// Saves [link] without music; [singing]: also mute women's singing (the detector, fail-closed). Returns when
  /// done; the outcome is in [status] (done with its path, or failed with the reason).
  Future<void> save(ResolvedLink link, {bool singing = false}) async {
    if (busy) throw const LinkError('busy');
    if (link.meta.isLive) throw const LinkError('live');
    final choice = link.choice;
    if (choice == null) throw const LinkError('no_format');
    if (singing && tools.detector == null) {
      throw const LinkError('failed', "the women's singing detector is not in this installation");
    }
    _cancelled = false;
    final title = link.meta.title.isNotEmpty ? link.meta.title : link.meta.site;
    final isVideo = choice.hasVideo;
    _set(LinkSaveInfo(phase: LinkSavePhase.downloading, title: title, progress: 0, isVideo: isVideo));
    final dir = Directory('$workDir${_sep}save-${DateTime.now().microsecondsSinceEpoch}');
    try {
      await dir.create(recursive: true);
      final infoFile = File('${dir.path}${_sep}info.json');
      await infoFile.writeAsString(jsonEncode(link.info));
      // 1. download (progress over all parts by bytes when their sizes are known)
      final parts = choice.parts;
      final sizes = parts.map((f) => _n(f['filesize']) > 0 ? _n(f['filesize']) : _n(f['filesize_approx'])).toList();
      final total = sizes.every((s) => s > 0) ? sizes.fold<num>(0, (a, b) => a + b) : 0;
      var before = 0;
      final files = <String>[];
      for (var i = 0; i < parts.length; i++) {
        final name = identical(parts[i], choice.audio) ? 'audio' : 'video';
        final f = await _download(infoFile.path, _s(parts[i]['format_id']), dir.path, name, (n) {
          if (total > 0) _set(_with(progress: ((before + n) / total).clamp(0, 1).toDouble()));
        });
        before += await File(f).length();
        files.add(f);
      }
      // 2. filter the sound, copy the video
      _set(_with(phase: LinkSavePhase.filtering, progress: link.meta.durationSec != null ? 0 : -1));
      final audioIn = choice.audio != null ? files.last : files.first;
      final videoIn = isVideo ? files.first : null;
      final out = '${dir.path}$_sep${isVideo ? 'out.mp4' : 'out.m4a'}';
      await _filter(audioIn, videoIn, out, link.meta.durationSec, singing);
      _checkCancel();
      // 3. into the user's folder: a fully filtered file only
      final dest = isVideo ? videosDir : musicDir;
      await Directory(dest).create(recursive: true);
      final path = uniquePath(dest, fileBaseName(title), isVideo ? '.mp4' : '.m4a');
      await _move(out, path);
      _set(LinkSaveInfo(phase: LinkSavePhase.done, title: title, progress: 1, isVideo: isVideo, path: path));
    } catch (e) {
      final err = _cancelled
          ? const BackendMessage('cancelled')
          : e is LinkError
              ? BackendMessage(e.code, e.detail)
              : BackendMessage('failed', '$e');
      _set(LinkSaveInfo(phase: LinkSavePhase.failed, title: title, isVideo: isVideo, error: err));
    } finally {
      for (final p in [..._running]) {
        await _kill(p);
      }
      await _deleteDir(dir);
    }
  }

  LinkSaveInfo _with({LinkSavePhase? phase, double? progress}) => LinkSaveInfo(
        phase: phase ?? _status.phase,
        title: _status.title,
        progress: progress ?? _status.progress,
        isVideo: _status.isVideo,
      );

  void _checkCancel() {
    if (_cancelled) throw const LinkError('cancelled');
  }

  /// One format with yt-dlp (it handles HLS, DASH and the sites' headers and cookies); returns the file.
  Future<String> _download(String infoJson, String formatId, String dir, String name, void Function(int) progress) async {
    _checkCancel();
    final p = await _spawn(tools.ytDlp, [
      ..._ytBase,
      '--load-info-json',
      infoJson,
      '-f',
      formatId,
      '--ffmpeg-location',
      tools.ffmpeg,
      '--no-part',
      '--no-mtime',
      '--newline',
      '--progress-template',
      'download:WAAIYA %(progress.downloaded_bytes)s %(progress.total_bytes)s %(progress.total_bytes_estimate)s',
      '-o',
      '$dir$_sep$name.%(ext)s',
    ]);
    unawaited(p.stdin.close());
    final err = StringBuffer();
    final errDone = p.stderr.transform(const Utf8Decoder(allowMalformed: true)).forEach(err.write);
    final outDone = p.stdout.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter()).forEach((l) {
      final pr = parseProgress(l);
      if (pr != null) progress(pr.$1);
    });
    final code = await p.exitCode;
    await Future.wait([errDone, outDone]);
    _checkCancel();
    if (code != 0) throw linkErrorFrom(err.toString());
    final found = Directory(dir)
        .listSync()
        .whereType<File>()
        .map((f) => f.path)
        .where((f) => f.split(RegExp(r'[\\/]')).last.startsWith('$name.') && !f.endsWith('.part') && !f.endsWith('.ytdl'))
        .toList();
    if (found.isEmpty) throw const LinkError('failed', 'the download left no file');
    return found.first;
  }

  /// ffmpeg (decode) -> im-process --raw -> ffmpeg (AAC, video copied). Fails unless all three end cleanly.
  Future<void> _filter(String audioIn, String? videoIn, String out, int? durationSec, bool singing) async {
    _checkCancel();
    const rate = 48000, ch = 2;
    final dec = await _spawn(tools.ffmpeg, [
      '-nostdin', '-hide_banner', '-loglevel', 'error', '-i', audioIn, '-map', '0:a:0', '-vn', //
      '-f', 'f32le', '-ac', '$ch', '-ar', '$rate', '-',
    ]);
    final imp = await _spawn(tools.imProcess, [
      '-m', tools.model, '--raw', '--channels', '$ch', '--rate', '$rate', //
      if (singing) ...['-d', tools.detector!, '--mute-female-singing', '--fail-closed'],
    ]);
    final enc = await _spawn(tools.ffmpeg, [
      '-nostdin', '-hide_banner', '-loglevel', 'error', '-y', //
      '-f', 'f32le', '-ac', '$ch', '-ar', '$rate', '-i', '-',
      if (videoIn != null) ...['-i', videoIn, '-map', '1:v:0', '-map', '0:a:0', '-c:v', 'copy'] else ...['-map', '0:a:0'],
      '-c:a', 'aac', '-b:a', '160k', '-movflags', '+faststart', out,
    ]);
    final errs = [StringBuffer(), StringBuffer(), StringBuffer()];
    final stderrDone = [
      for (final (i, p) in [dec, imp, enc].indexed)
        p.stderr.transform(const Utf8Decoder(allowMalformed: true)).forEach(errs[i].write),
    ];
    final total = durationSec != null ? durationSec * rate * ch * 4 : 0;
    var outBytes = 0;
    var lastReport = DateTime.fromMillisecondsSinceEpoch(0);
    // pipes with flow control: the next block is read only once the previous one is written (a long video is
    // never held in memory)
    final a = _pump(dec.stdout, imp.stdin);
    final b = _pump(imp.stdout, enc.stdin, (n) {
      outBytes += n;
      final now = DateTime.now();
      if (total > 0 && now.difference(lastReport).inMilliseconds > 250) {
        lastReport = now;
        _set(_with(progress: (outBytes / total).clamp(0, 1).toDouble()));
      }
    });
    final codes = await Future.wait([dec.exitCode, imp.exitCode, enc.exitCode]);
    await Future.wait([a, b, ...stderrDone]);
    _checkCancel();
    // every program that failed (one failing makes the others fail too: a broken pipe, or no input)
    const names = ['ffmpeg (decoding)', 'im-process', 'ffmpeg (encoding)'];
    final failed = [
      for (var i = 0; i < 3; i++)
        if (codes[i] != 0) '${names[i]}: exit ${codes[i]}\n${_tail(errs[i].toString())}'.trim(),
    ];
    if (failed.isNotEmpty) throw LinkError('failed', failed.join('\n'));
    if (!File(out).existsSync() || File(out).lengthSync() == 0) throw const LinkError('failed', 'no output');
  }

  static String _tail(String text, [int n = 4]) {
    final lines = text.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
    return lines.sublist(lines.length > n ? lines.length - n : 0).join('\n');
  }

  /// Copies [from] into [to] block by block, waiting for each write; closes [to] at the end. A broken pipe (the next
  /// program ended) stops the copy: that program's exit code tells what went wrong.
  static Future<void> _pump(Stream<List<int>> from, IOSink to, [void Function(int)? onBytes]) async {
    try {
      await for (final chunk in from) {
        to.add(chunk);
        await to.flush();
        onBytes?.call(chunk.length);
      }
    } on Object {
      // reported by the exit codes
    } finally {
      try {
        await to.close();
      } on Object {
        // already closed
      }
    }
  }

  /// Rename when the scratch space is on the same drive, else copy to a hidden name first and rename when complete.
  Future<void> _move(String from, String to) async {
    try {
      await File(from).rename(to);
      return;
    } on FileSystemException {
      // another drive
    }
    final tmp = '$to.waaiya-part';
    try {
      await File(from).copy(tmp);
      _checkCancel();
      await File(tmp).rename(to);
    } catch (_) {
      try {
        await File(tmp).delete();
      } on FileSystemException {
        // not there
      }
      rethrow;
    }
  }

  static Future<void> _deleteDir(Directory d) async {
    for (var i = 0; i < 10; i++) {
      try {
        if (await d.exists()) await d.delete(recursive: true);
        return;
      } on FileSystemException {
        // a killed program may hold a file for a moment (Windows)
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
  }
}

/// Opens [target] (a web link or a file) with the computer's default program. Windows: the shell's file protocol
/// handler (no command line is built from the link); Linux: xdg-open.
Future<bool> openWithSystem(String target, {bool windows = true}) async {
  try {
    final r = windows
        ? await Process.run('rundll32', ['url.dll,FileProtocolHandler', target])
        : await Process.run('xdg-open', [target]);
    return r.exitCode == 0;
  } on ProcessException {
    return false;
  }
}

/// Shows [file] selected in its folder (Explorer), or opens the folder (Linux).
Future<void> showInFolder(String file, {bool windows = true}) async {
  try {
    if (windows) {
      await Process.run('explorer.exe', ['/select,', file]);
    } else {
      await Process.run('xdg-open', [File(file).parent.path]);
    }
  } on ProcessException {
    // nothing to show it with
  }
}

/// The user's Videos and Music folders (Windows: where the user moved them, e.g. OneDrive), with `Waaiya` in each.
Future<(String, String)> savedFolders({Map<String, String>? environment, bool windows = true}) async {
  final env = environment ?? Platform.environment;
  if (!windows) {
    final home = env['HOME'] ?? '.';
    return ('$home/Videos/Waaiya', '$home/Music/Waaiya');
  }
  final profile = env['USERPROFILE'] ?? '.';
  var videos = '$profile\\Videos', music = '$profile\\Music';
  try {
    final r = await Process.run(
        'reg', ['query', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders']);
    for (final line in '${r.stdout}'.split('\n')) {
      final m = RegExp(r'^\s*(My Video|My Music)\s+REG_SZ\s+(.+?)\s*$').firstMatch(line);
      if (m == null) continue;
      if (m.group(1) == 'My Video') videos = m.group(2)!;
      if (m.group(1) == 'My Music') music = m.group(2)!;
    }
  } on ProcessException {
    // defaults
  }
  return ('$videos\\Waaiya', '$music\\Waaiya');
}
