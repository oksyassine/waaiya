// Flutter's Windows accessibility bridge (accessibility_bridge.cc) crashes the app
// when a semantics update holds a node that no node in the tree lists as a child:
// it can take such a node for the tree's root, and a later update that lists it
// then reaches a missing parent. Windows sends Flutter's semantics to the bridge
// whenever an accessibility client (Narrator, the touch keyboard, many others)
// reads the window. In Waaiya this closed the app on Settings then Filter.
//
// These tests record every semantics update the engine would receive and check
// that each node in it hangs from the root.
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/src/app.dart';
import 'package:waaiya_ui/src/backend.dart';
import 'package:waaiya_ui/src/memory_backend.dart';

final _updates = <Map<int, List<int>>>[];

/// Records each node's children (in traversal order, as the engine uses them).
class _Recorder implements ui.SemanticsUpdateBuilder {
  final _real = ui.SemanticsUpdateBuilder();
  final _nodes = <int, List<int>>{};

  @override
  dynamic noSuchMethod(Invocation i) {
    final n = i.namedArguments;
    if (i.memberName == #updateNode) {
      _nodes[n[#id] as int] = List<int>.from(n[#childrenInTraversalOrder] as List);
      return Function.apply(_real.updateNode, i.positionalArguments, n);
    }
    if (i.memberName == #updateCustomAction) {
      return Function.apply(_real.updateCustomAction, i.positionalArguments, n);
    }
    return super.noSuchMethod(i);
  }

  @override
  ui.SemanticsUpdate build() {
    _updates.add(_nodes);
    return _real.build();
  }
}

class _Binding extends AutomatedTestWidgetsFlutterBinding {
  @override
  ui.SemanticsUpdateBuilder createSemanticsUpdateBuilder() => _Recorder();
}

/// The engine's view of the tree, kept up to date from the updates.
class _Tree {
  final children = <int, List<int>>{};

  /// Applies the updates recorded so far and returns the nodes they sent that do
  /// not hang from the root (node 0).
  List<int> apply() {
    final problems = <int>[];
    for (final u in _updates) {
      children.addAll(u);
      final reach = <int>{};
      void walk(int id) {
        if (!reach.add(id)) return;
        for (final c in children[id] ?? const <int>[]) {
          walk(c);
        }
      }

      walk(0);
      children.removeWhere((id, _) => !reach.contains(id) && !u.containsKey(id));
      problems.addAll(u.keys.where((id) => !reach.contains(id)));
    }
    _updates.clear();
    return problems;
  }
}

void main() {
  _Binding();

  testWidgets('every page switch sends Windows a tree with no loose nodes', semanticsEnabled: false, (tester) async {
    tester.view.physicalSize = const Size(504, 671);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(WaaiyaApp(
        backend: MemoryBackend(
            initial: const AppState(
                platform: 'windows',
                language: 'en',
                settings: WaaiyaSettings(gender: 'man'),
                capabilities: Capabilities(
                    womenSinging: true,
                    autostart: true,
                    screenBlur: true,
                    blurStandalone: true,
                    links: true,
                    linkPage: true,
                    tray: true)))));
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    Future<void> click(String page) async {
      final at = tester.getCenter(find.byKey(Key('nav_$page')));
      await mouse.moveTo(at);
      await tester.pump();
      await mouse.down(at);
      await tester.pump();
      await mouse.up();
      // frame by frame through the page's animation, as the engine sees it
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    // as in the app: pages visited first, then an accessibility client starts reading
    await click('settings');
    await click('filter');
    final semantics = tester.ensureSemantics();
    await tester.pump();
    final tree = _Tree();
    expect(tree.apply(), isEmpty, reason: 'the first full tree');

    for (final page in ['settings', 'filter', 'screen', 'filter', 'links', 'settings', 'filter']) {
      await click(page);
      expect(tree.apply(), isEmpty, reason: 'after going to $page');
    }
    semantics.dispose();
  });
}
