library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_desktop/links.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

/// A manual check with real sites (never in CI: they change, limit and block runners):
///
///     WAAIYA_LINK_ENGINE=<bundle>\engine WAAIYA_REAL_LINKS="https://youtu.be/... https://www.tiktok.com/..." \
///       flutter test test/real_links_test.dart
///
/// Each link is resolved and saved without music into a temporary folder; the result is printed.
void main() {
  final engine = Platform.environment['WAAIYA_LINK_ENGINE'];
  final links = (Platform.environment['WAAIYA_REAL_LINKS'] ?? '').split(RegExp(r'\s+')).where((l) => l.isNotEmpty);
  final tools = engine == null ? null : LinkTools.find(engine, windows: Platform.isWindows);
  if (links.isEmpty) test('real links', () {}, skip: 'WAAIYA_REAL_LINKS not set');
  for (final url in links) {
    test(url, () async {
      final tmp = Directory.systemTemp.createTempSync('waaiya-real-');
      final s = LinkSaver(tools!,
          workDir: '${tmp.path}/work',
          videosDir: '${tmp.path}/Videos',
          musicDir: '${tmp.path}/Music',
          onStatus: (_) {},
          windows: Platform.isWindows);
      final sw = Stopwatch()..start();
      try {
        final r = await s.resolve(url);
        final c = r.choice;
        // ignore: avoid_print
        print('$url\n  ${r.meta.site} "${r.meta.title}" ${r.meta.durationSec}s live=${r.meta.isLive} '
            'video=${c?.video?['format_id']} audio=${c?.audio?['format_id']} both=${c?.progressive?['format_id']} '
            '(resolved in ${sw.elapsed.inSeconds}s)');
        await s.save(r);
        // ignore: avoid_print
        print('  save: ${s.status.phase.name} ${s.status.error?.code ?? ''} ${s.status.error?.detail ?? ''} '
            '${s.status.path ?? ''} ${s.status.path != null ? File(s.status.path!).lengthSync() : ''} bytes, '
            '${sw.elapsed.inSeconds}s');
        expect(s.status.phase, LinkSavePhase.done);
      } on LinkError catch (e) {
        // ignore: avoid_print
        print('  resolve: ${e.code} ${e.detail}');
        rethrow;
      } finally {
        tmp.deleteSync(recursive: true);
      }
    }, skip: tools == null ? 'WAAIYA_LINK_ENGINE with the link tools not set' : null, timeout: const Timeout(Duration(minutes: 10)));
  }
}
