import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/l10n/app_localizations_en.dart';
import 'package:waaiya_ui/src/app.dart';
import 'package:waaiya_ui/src/backend.dart';
import 'package:waaiya_ui/src/links_page.dart';
import 'package:waaiya_ui/src/memory_backend.dart';

/// The desktop Links page (capability `linkPage`) against the simulated backend.
final l = AppLocalizationsEn();

AppState desktop({bool save = true, bool singing = false}) => AppState(
      platform: 'windows',
      language: 'en',
      settings: WaaiyaSettings(gender: 'man', muteWomenSinging: singing),
      capabilities: Capabilities(links: true, linkPage: true, linkSave: save, womenSinging: true, autostart: true),
    );

Future<MemoryBackend> open(WidgetTester tester, AppState s, {void Function(MemoryBackend)? setup}) async {
  final b = MemoryBackend(initial: s);
  setup?.call(b);
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  await tester.pumpWidget(WaaiyaApp(backend: b));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav_links')));
  await tester.pumpAndSettle();
  return b;
}

Future<void> openLink(WidgetTester tester, String url) async {
  await tester.enterText(find.byKey(const Key('link_input')), url);
  await tester.tap(find.byKey(const Key('link_open')));
  await tester.pumpAndSettle();
}

void main() {
  test('durations as on Android', () {
    expect(linkDuration(65), '1:05');
    expect(linkDuration(3723), '1:02:03');
    expect(linkDuration(0), '0:00');
  });

  test('every link error code has its own sentence', () {
    for (final code in linkErrorCodes.where((c) => c != 'failed')) {
      expect(linkErrorText(l, code), isNot(l.linkFailed), reason: code);
    }
    expect(linkErrorText(l, 'cancelled'), l.linkCancelled);
    expect(linkErrorText(l, 'something new'), l.linkFailed);
  });

  testWidgets('Android keeps its native screen: the page only has the Open button', (tester) async {
    await open(tester, const AppState(settings: WaaiyaSettings(gender: 'man'), capabilities: Capabilities.android));
    expect(find.byKey(const Key('link_input')), findsNothing);
  });

  testWidgets('a link: title, site and duration, then Watch opens it with the filter on', (tester) async {
    final b = await open(tester, desktop());
    expect(find.text(l.linkEntryBodyDesktop), findsOneWidget);
    await openLink(tester, 'look at this https://www.youtube.com/watch?v=abc please');
    expect(find.byKey(const Key('link_result')), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    expect(find.textContaining('www.youtube.com · 1:35'), findsOneWidget);
    expect(b.state.filter.running, isFalse);
    await tester.tap(find.byKey(const Key('link_watch')));
    await tester.pumpAndSettle();
    expect(b.state.filter.running, isTrue, reason: 'the filter starts before the link opens');
    expect(b.openedLink, 'https://www.youtube.com/watch?v=abc');
  });

  testWidgets('not a link, and a playlist: the error is said, nothing opens', (tester) async {
    final b = await open(tester, desktop());
    await openLink(tester, 'hello');
    expect(find.text(l.linkInvalid), findsOneWidget);
    expect(find.byKey(const Key('link_result')), findsNothing);
    await openLink(tester, 'https://www.youtube.com/playlist?list=x');
    expect(find.text(l.linkPlaylist), findsOneWidget);
    expect(b.openedLink, isNull);
  });

  testWidgets('Paste takes the link out of the clipboard text', (tester) async {
    final b = await open(tester, desktop());
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return {'text': 'shared: https://vm.tiktok.com/xyz/'};
      return null;
    });
    await tester.tap(find.byKey(const Key('link_paste')));
    await tester.pumpAndSettle();
    expect(find.textContaining('vm.tiktok.com'), findsWidgets);
    expect(b.openedLink, isNull);
  });

  testWidgets('save: progress, then Play and Show in folder', (tester) async {
    final b = await open(tester, desktop(), setup: (b) => b.holdLinkSave = true);
    await openLink(tester, 'https://www.youtube.com/watch?v=abc');
    await tester.tap(find.byKey(const Key('link_save')));
    await tester.pumpAndSettle();
    expect(find.text(l.linkDownloading), findsOneWidget);
    expect(find.byKey(const Key('link_cancel')), findsOneWidget);
    // one save at a time
    final save = tester.widget<FilledButton>(find.ancestor(of: find.text(l.linkSave), matching: find.byType(FilledButton)));
    expect(save.onPressed, isNull);
    b.finishLinkSave();
    await tester.pumpAndSettle();
    expect(find.textContaining(l.linkSavedVideoDesktop), findsOneWidget);
    await tester.tap(find.byKey(const Key('link_show')));
    await tester.pumpAndSettle();
    expect(b.openedFile, 'Videos/Waaiya/Video.mp4');
  });

  testWidgets('cancel: "Nothing was saved", no Play button', (tester) async {
    final b = await open(tester, desktop(), setup: (b) => b.holdLinkSave = true);
    await openLink(tester, 'https://www.youtube.com/watch?v=abc');
    await tester.tap(find.byKey(const Key('link_save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('link_cancel')));
    await tester.pumpAndSettle();
    expect(find.text(l.linkCancelled), findsOneWidget);
    expect(find.byKey(const Key('link_play')), findsNothing);
    expect(b.state.linkSave.phase, LinkSavePhase.failed);
  });

  testWidgets('a failed save says so, with the details', (tester) async {
    await open(tester, desktop(), setup: (b) => b.linkSaveOutcome = 'login');
    await openLink(tester, 'https://www.instagram.com/reel/x/');
    await tester.tap(find.byKey(const Key('link_save')));
    await tester.pumpAndSettle();
    expect(find.text(l.linkLogin), findsOneWidget);
  });

  testWidgets("women's singing on: the page says the save mutes it too", (tester) async {
    await open(tester, desktop(singing: true));
    await openLink(tester, 'https://www.youtube.com/watch?v=abc');
    expect(find.text(l.linkSingingNote), findsOneWidget);
  });

  testWidgets('the Store package: watch only, no Save button', (tester) async {
    final b = await open(tester, desktop(save: false));
    expect(find.text(l.linkEntryBodyWatch), findsOneWidget);
    await openLink(tester, 'https://www.youtube.com/watch?v=abc');
    expect(find.byKey(const Key('link_save')), findsNothing);
    await tester.tap(find.byKey(const Key('link_watch')));
    await tester.pumpAndSettle();
    expect(b.openedLink, isNotNull);
  });

  test('the state round-trips through a map (the platform channel)', () {
    const s = AppState(
      linkSave: LinkSaveInfo(phase: LinkSavePhase.done, title: 'T', progress: 1, isVideo: false, path: 'C:/x.m4a'),
      capabilities: Capabilities(linkPage: true, linkSave: true),
    );
    final back = AppState.fromMap(s.toMap());
    expect(back.linkSave.phase, LinkSavePhase.done);
    expect(back.linkSave.path, 'C:/x.m4a');
    expect(back.linkSave.isVideo, isFalse);
    expect(back.capabilities.linkPage, isTrue);
    expect(back.capabilities.linkSave, isTrue);
    final m = LinkMeta.fromMap(const LinkMeta(url: 'u', title: 't', site: 's', durationSec: 5, isLive: true).toMap());
    expect((m.url, m.title, m.site, m.durationSec, m.isLive), ('u', 't', 's', 5, true));
  });
}
