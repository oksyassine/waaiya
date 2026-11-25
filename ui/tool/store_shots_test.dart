// Screenshots of the Windows app for the Microsoft Store listing (desktop/windows/msix/STORE_LISTING.md), rendered
// here with real fonts (Roboto, Noto Naskh Arabic from the Flutter checkout, Material icons), not on a PC:
//
//   cd ui && for l in en fr ar; do flutter test tool/store_shots_test.dart --dart-define=SHOTS=<out dir> \
//       --dart-define=LANG=$l [--dart-define=ARABIC_FONT_DIR=<dir with Amiri-Regular.ttf, Amiri-Bold.ttf>]; done
//
// One language per run: the test renderer does not fall back from one font to another, so for Arabic the app's
// font family (Roboto) is filled with Amiri (Arabic and Latin, SIL OFL) instead.
//
// 1366x768 window at 2x = 2732x1536 PNGs (the Store takes 1366x768 up to 3840x2160), per language and page.
//
// --dart-define=FORM=phone: the Android app of the store build (no links, no updater; docs/STORES.md) on a
// 1080x2400 phone (411x914 at 2.625x), for Google Play and the other Android stores: <lang>-phone-<page>.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

const out = String.fromEnvironment('SHOTS');
const lang = String.fromEnvironment('LANG', defaultValue: 'en');
const arabicDir = String.fromEnvironment('ARABIC_FONT_DIR');
const phone = String.fromEnvironment('FORM') == 'phone';

Future<void> loadFont(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

void main() {
  final flutter = File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path; // .../flutter
  setUpAll(() async {
    final mat = '$flutter/bin/cache/artifacts/material_fonts';
    final home = Platform.environment['HOME'] ?? '';
    final ar = arabicDir.isNotEmpty ? arabicDir : '$home/.fonts';
    await loadFont(
      'Roboto',
      lang == 'ar'
          ? ['$ar/Amiri-Regular.ttf', '$ar/Amiri-Bold.ttf']
          : ['$mat/Roboto-Regular.ttf', '$mat/Roboto-Medium.ttf', '$mat/Roboto-Bold.ttf'],
    );
    await loadFont('MaterialIcons', ['$mat/MaterialIcons-Regular.otf']);
  });

  {
    testWidgets('store screenshots $lang', (tester) async {
      tester.view.physicalSize = phone ? const Size(1080, 2400) : const Size(2732, 1536);
      tester.view.devicePixelRatio = phone ? 2.625 : 2;
      final dpr = tester.view.devicePixelRatio;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: WaaiyaApp(
            backend: MemoryBackend(
              initial: phone
                  ? AppState(
                      version: '0.2.20',
                      language: lang,
                      settings: const WaaiyaSettings(gender: 'man', prayerSilent: true),
                      filter: const FilterInfo(state: FilterState.filtering, delayMs: 30),
                      setup: const SetupInfo(originalsMuted: true, consentSkipped: true),
                      blur: const BlurInfo(
                          overlayAllowed: true, touchPassThrough: true, shellLayer: true, layerSupported: true),
                      features: {
                        'worship': {
                          'supported': true, 'placeSet': true, 'placeValid': true, 'placeLabel': lang == 'ar' ? 'الدار البيضاء' : 'Casablanca',
                          'times': [
                            {'name': 'fajr', 'hm': '06:12'}, {'name': 'sunrise', 'hm': '07:41'},
                            {'name': 'dhuhr', 'hm': '13:16'}, {'name': 'asr', 'hm': '15:58'},
                            {'name': 'maghrib', 'hm': '18:22'}, {'name': 'isha', 'hm': '19:42'},
                          ],
                        },
                      },
                      capabilities: const Capabilities(
                          shizukuSetup: true, adbSetup: true, captureConsent: true, screenBlur: true,
                          links: false, womenSinging: true),
                    )
                  : AppState(
                platform: 'windows',
                version: '0.2.13',
                language: lang,
                settings: const WaaiyaSettings(gender: 'man'),
                filter: const FilterInfo(state: FilterState.filtering, delayMs: 0, autostart: true),
                setup: const SetupInfo(originalsMuted: true, consentSkipped: true),
                blur: const BlurInfo(overlayAllowed: true, touchPassThrough: true),
                detectorModel: false, // no women's-singing model in the Windows build yet: its switch is hidden
                capabilities: const Capabilities(
                  womenSinging: false,
                  autostart: true,
                  screenBlur: true,
                  blurStandalone: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final page in phone ? ['filter', 'screen', 'settings'] : ['filter', 'screen', 'settings']) {
        final nav = find.byKey(Key('nav_$page'));
        if (nav.evaluate().isNotEmpty) {
          await tester.tap(nav);
          await tester.pumpAndSettle();
        }
        await tester.runAsync(() async {
          final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await b.toImage(pixelRatio: dpr);
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          Directory(out).createSync(recursive: true);
          File('$out/$lang${phone ? '-phone' : ''}-$page.png').writeAsBytesSync(png!.buffer.asUint8List());
        });
      }
    });
  }
}
