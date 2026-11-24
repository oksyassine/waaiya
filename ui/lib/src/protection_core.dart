/// Protection that survives a weak moment, for the backends written in Dart (desktop, tests): the same rules as
/// Android's ProtectionCore.kt. What weakens, the waiting period on a clock that a reboot or a clock change cannot
/// shorten, confirming within 15 minutes, and the PIN (PBKDF2-HMAC-SHA256) with its lockout.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'backend.dart';

/// Wall clock (display only), a monotonic clock, and an id of the current boot ('' when unknown).
abstract interface class ProtectionClock {
  int wallMs();
  int elapsedMs();
  String bootId();
}

/// A clock for one process: every start of the app counts as a new boot, so the time while it is closed never counts.
class ProcessClock implements ProtectionClock {
  ProcessClock() : _boot = '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
  final _watch = Stopwatch()..start();
  final String _boot;
  @override
  int wallMs() => DateTime.now().millisecondsSinceEpoch;
  @override
  int elapsedMs() => _watch.elapsedMilliseconds;
  @override
  String bootId() => _boot;
}

abstract final class ProtectionRules {
  /// The waiting periods offered, in minutes (0: none).
  static const delays = [0, 1, 5, 15, 30, 60, 240, 1440];
  static const confirmMs = 15 * 60000;
  static const tries = 5;
  static const lockMsBase = 30000;
  static const iterations = 120000;

  static const _onToOff = {
    SettingKeys.blurEnabled,
    SettingKeys.blurWomen,
    SettingKeys.blurNudity,
    SettingKeys.blurFailCover,
    SettingKeys.silenceUnfilterable,
    SettingKeys.holdSilence,
    SettingKeys.muteWomenSinging,
  };
  static const _apps = {SettingKeys.filterOffApps, SettingKeys.blurOffApps};

  static Set<String> csv(Object? s) =>
      (s is String ? s : '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();

  /// The value with its type checked, or null when [key] cannot be held or the value is wrong.
  static Object? normalize(String key, Object? v) {
    if (_onToOff.contains(key) || key == SettingKeys.keepSinging) return v is bool ? v : null;
    if (_apps.contains(key)) return v is String ? (csv(v).toList()..sort()).join(',') : null;
    return switch (key) {
      SettingKeys.blurStrictness => v is int && v >= 0 && v <= 2 ? v : null,
      SettingKeys.gender => v is String && const ['', 'man', 'woman'].contains(v) ? v : null,
      SettingKeys.protectDelayMinutes => v is int && v >= 0 && v <= 1440 ? v : null,
      _ => null,
    };
  }

  /// Does changing [key] from [old] to [value] weaken protection? (ProtectionRules.isWeakening on Android.)
  static bool isWeakening(String key, Object? old, Object? value) {
    if (normalize(key, value) == null) return false;
    if (_onToOff.contains(key)) return old == true && value == false;
    if (_apps.contains(key)) return csv(value).difference(csv(old)).isNotEmpty;
    return switch (key) {
      SettingKeys.keepSinging => old != true && value == true,
      SettingKeys.blurStrictness => old is int && (value as int) > old,
      SettingKeys.gender => old is String && old.isNotEmpty && value != old,
      SettingKeys.protectDelayMinutes => old is int && (value as int) < old,
      _ => false,
    };
  }

  static ({bool pin, bool wait}) gate(String key, Object? old, Object? value, bool pinSet, int delayMinutes) {
    final weak = isWeakening(key, old, value);
    return (
      pin: pinSet && (weak || (key == SettingKeys.protectDelayMinutes && old != value)),
      wait: weak && delayMinutes > 0,
    );
  }

  static bool pinValid(String? pin) => pin != null && RegExp(r'^[0-9]{4,8}$').hasMatch(pin);

  /// Lockout after [n] wrong tries in a row: 30 s after 5, doubled after each further 5; 0 between.
  static int lockMs(int n) => n <= 0 || n % tries != 0 ? 0 : lockMsBase << min(n ~/ tries - 1, 12);
}

/// Time left on a monotonic clock (Countdown in ProtectionCore.kt): in the same boot the time since the anchor
/// counts; after a reboot (another boot id, or the clock went back) only the time since that boot counts.
class Countdown {
  const Countdown(this.remainingMs, this.anchorElapsed, this.boot);
  factory Countdown.start(int ms, ProtectionClock c) => Countdown(ms, c.elapsedMs(), c.bootId());

  final int remainingMs;
  final int anchorElapsed;
  final String boot;

  int remaining(ProtectionClock c) {
    final now = c.elapsedMs();
    final sameBoot = c.bootId() == boot && now >= anchorElapsed;
    return remainingMs - (sameBoot ? now - anchorElapsed : max(now, 0));
  }

  Countdown checkpoint(ProtectionClock c) => Countdown(remaining(c), c.elapsedMs(), c.bootId());

  Map<String, Object> toJson() => {'remaining': remainingMs, 'anchor': anchorElapsed, 'boot': boot};

  static Countdown? fromJson(Object? m) {
    if (m is! Map) return null;
    final r = m['remaining'], a = m['anchor'], b = m['boot'];
    return r is int && a is int && b is String ? Countdown(r, a, b) : null;
  }
}

// --- PBKDF2-HMAC-SHA256 (no package needed) ---

const _k = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, //
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];
const _h0 = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];

int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xffffffff;

/// One SHA-256 block (16 big-endian words) into [h].
void _compress(List<int> h, List<int> block, List<int> w) {
  for (var i = 0; i < 16; i++) {
    w[i] = block[i];
  }
  for (var i = 16; i < 64; i++) {
    final a = w[i - 15], b = w[i - 2];
    final s0 = _rotr(a, 7) ^ _rotr(a, 18) ^ (a >> 3);
    final s1 = _rotr(b, 17) ^ _rotr(b, 19) ^ (b >> 10);
    w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
  }
  var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
  for (var i = 0; i < 64; i++) {
    final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
    final ch = (e & f) ^ ((~e & 0xffffffff) & g);
    final t1 = (hh + s1 + ch + _k[i] + w[i]) & 0xffffffff;
    final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
    final maj = (a & b) ^ (a & c) ^ (b & c);
    final t2 = (s0 + maj) & 0xffffffff;
    hh = g;
    g = f;
    f = e;
    e = (d + t1) & 0xffffffff;
    d = c;
    c = b;
    b = a;
    a = (t1 + t2) & 0xffffffff;
  }
  h[0] = (h[0] + a) & 0xffffffff;
  h[1] = (h[1] + b) & 0xffffffff;
  h[2] = (h[2] + c) & 0xffffffff;
  h[3] = (h[3] + d) & 0xffffffff;
  h[4] = (h[4] + e) & 0xffffffff;
  h[5] = (h[5] + f) & 0xffffffff;
  h[6] = (h[6] + g) & 0xffffffff;
  h[7] = (h[7] + hh) & 0xffffffff;
}

/// SHA-256 of [data] continuing from [state] after [prefixLen] bytes already hashed (a multiple of 64).
List<int> _sha256(List<int> data, {List<int>? state, int prefixLen = 0}) {
  final h = List<int>.of(state ?? _h0);
  final total = prefixLen + data.length;
  final padded = Uint8List(((data.length + 9 + 63) ~/ 64) * 64)..setAll(0, data);
  padded[data.length] = 0x80;
  final bits = total * 8;
  for (var i = 0; i < 8; i++) {
    padded[padded.length - 1 - i] = (bits >> (8 * i)) & 0xff;
  }
  final w = List<int>.filled(64, 0), block = List<int>.filled(16, 0);
  for (var off = 0; off < padded.length; off += 64) {
    for (var i = 0; i < 16; i++) {
      final j = off + 4 * i;
      block[i] = (padded[j] << 24) | (padded[j + 1] << 16) | (padded[j + 2] << 8) | padded[j + 3];
    }
    _compress(h, block, w);
  }
  return h;
}

List<int> _bytes(List<int> words) => [for (final x in words) ...[(x >> 24) & 0xff, (x >> 16) & 0xff, (x >> 8) & 0xff, x & 0xff]];

/// PBKDF2-HMAC-SHA256 with a 32-byte result (one block).
Uint8List pbkdf2Sha256(String pin, List<int> salt, int iterations) {
  var key = utf8.encode(pin);
  if (key.length > 64) key = Uint8List.fromList(_bytes(_sha256(key)));
  final ipad = Uint8List(64), opad = Uint8List(64);
  for (var i = 0; i < 64; i++) {
    final k = i < key.length ? key[i] : 0;
    ipad[i] = k ^ 0x36;
    opad[i] = k ^ 0x5c;
  }
  // the states after the pads, computed once
  List<int> after(Uint8List pad) {
    final h = List<int>.of(_h0), w = List<int>.filled(64, 0);
    _compress(h, [for (var i = 0; i < 16; i++) (pad[4 * i] << 24) | (pad[4 * i + 1] << 16) | (pad[4 * i + 2] << 8) | pad[4 * i + 3]], w);
    return h;
  }

  final inner = after(ipad), outer = after(opad);
  List<int> hmac(List<int> msg) =>
      _sha256(_bytes(_sha256(msg, state: inner, prefixLen: 64)), state: outer, prefixLen: 64);

  // later rounds hash exactly 32 bytes: one fixed block each, padded once
  final w = List<int>.filled(64, 0);
  final block = List<int>.filled(16, 0)
    ..[8] = 0x80000000
    ..[15] = (64 + 32) * 8;
  List<int> fast(List<int> u) {
    final h1 = List<int>.of(inner);
    block.setRange(0, 8, u);
    _compress(h1, block, w);
    final h2 = List<int>.of(outer);
    block.setRange(0, 8, h1);
    _compress(h2, block, w);
    return h2;
  }

  var u = hmac([...salt, 0, 0, 0, 1]);
  final t = List<int>.of(u);
  for (var i = 1; i < iterations; i++) {
    u = fast(u);
    for (var j = 0; j < 8; j++) {
      t[j] ^= u[j];
    }
  }
  return Uint8List.fromList(_bytes(t));
}

String _hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
Uint8List _unhex(String s) =>
    Uint8List.fromList([for (var i = 0; i + 1 < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16)]);

/// "iterations:salt:hash" (hex), as on Android. Never the digits.
String pinRecord(String pin, int iterations, {Random? random}) {
  final r = random ?? Random.secure();
  final salt = [for (var i = 0; i < 16; i++) r.nextInt(256)];
  return '$iterations:${_hex(salt)}:${_hex(pbkdf2Sha256(pin, salt, iterations))}';
}

bool pinMatches(String pin, String? record) {
  final p = record?.split(':');
  if (p == null || p.length != 3) return false;
  final it = int.tryParse(p[0]);
  if (it == null) return false;
  final a = pbkdf2Sha256(pin, _unhex(p[1]), it), b = _unhex(p[2]);
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

/// A result of a `protect.*` call: `done`, `pending`, `waiting`, `none`, `pin_needed`, `pin_wrong`, `locked`.
class ProtectOutcome {
  const ProtectOutcome(this.status, {this.dueAt, this.triesLeft, this.lockedUntil, this.apply});
  final String status;
  final int? dueAt;
  final int? triesLeft;
  final int? lockedUntil;

  /// The change to make now: (setting key or "stop", value).
  final (String, Object?)? apply;

  Map<String, Object?> toMap() => {
        'status': status,
        'dueAt': ?dueAt,
        'triesLeft': ?triesLeft,
        'lockedUntil': ?lockedUntil,
      };
}

/// The waiting period and the PIN (ProtectionCore.kt). [store] is saved through [save] after every change.
class ProtectionCore {
  ProtectionCore({
    required this.store,
    required this.clock,
    required this.delayMinutes,
    required this.current,
    this.save,
    this.iterations = ProtectionRules.iterations,
  });

  final Map<String, Object?> store;
  final ProtectionClock clock;
  final int Function() delayMinutes;
  final Object? Function(String key) current;
  final void Function()? save;
  final int iterations;

  static const stop = 'stop', pinChange = 'pin_change', pinClear = 'pin_clear';

  bool get pinSet => store['pin'] is String;

  void _put(String k, Object? v) {
    if (v == null) {
      store.remove(k);
    } else {
      store[k] = v;
    }
  }

  void _saved() => save?.call();

  /// Null when the setting change is allowed; else what it needs. See ProtectionCore.check on Android.
  ({bool pin, bool wait})? check(String key, Object? value) {
    final g = ProtectionRules.gate(key, current(key), value, pinSet, delayMinutes());
    final p = pending();
    if (!g.pin && !g.wait) {
      if (p != null && p.what == key) _clearPending();
      return null;
    }
    if (g.wait && p != null && p.what == key && p.value == ProtectionRules.normalize(key, value) && p.left(clock) <= 0) {
      _clearPending();
      return null;
    }
    return g;
  }

  ({bool pin, bool wait}) get _stopGate => (pin: pinSet, wait: delayMinutes() > 0);

  ({bool pin, bool wait})? checkStop() {
    final g = _stopGate;
    if (!g.pin && !g.wait) return null;
    final p = pending();
    if (g.wait && p != null && p.what == stop && p.left(clock) <= 0) {
      _clearPending();
      return null;
    }
    return g;
  }

  bool get guarded => pinSet || delayMinutes() > 0;

  /// Throws ArgumentError for a key or value that cannot be held.
  ProtectOutcome request(String what, Object? rawValue, String? pin) {
    final Object? value;
    if (what == stop) {
      value = null;
    } else {
      value = ProtectionRules.normalize(what, rawValue);
      if (value == null) throw ArgumentError('$what cannot take $rawValue');
    }
    final g = what == stop ? _stopGate : ProtectionRules.gate(what, current(what), value, pinSet, delayMinutes());
    if (!g.pin && !g.wait) return ProtectOutcome('done', apply: (what, value));
    final p = pending();
    if (p != null && p.what == what && p.value == value) {
      return p.left(clock) > 0 ? ProtectOutcome('waiting', dueAt: due(p)) : confirm();
    }
    if (g.pin) {
      final v = _verify(pin);
      if (v != null) return v;
    }
    if (!g.wait) return ProtectOutcome('done', apply: (what, value));
    return _startWait(what, value, null);
  }

  ProtectOutcome setPin(String? newPin, String? oldPin) {
    if (!ProtectionRules.pinValid(newPin)) throw ArgumentError('the PIN is 4 to 8 digits');
    final record = pinRecord(newPin!, iterations);
    if (!pinSet) {
      _put('pin', record);
      _saved();
      return const ProtectOutcome('done');
    }
    final v = _verify(oldPin);
    if (v != null) return v;
    if (delayMinutes() > 0) return _startWait(pinChange, null, record);
    _put('pin', record);
    _saved();
    return const ProtectOutcome('done');
  }

  ProtectOutcome clearPin(String? pin) {
    if (!pinSet) return const ProtectOutcome('done');
    final v = _verify(pin);
    if (v != null) return v;
    if (delayMinutes() > 0) return _startWait(pinClear, null, null);
    _put('pin', null);
    _saved();
    return const ProtectOutcome('done');
  }

  void cancel() => _clearPending();

  ProtectOutcome confirm() {
    final p = pending();
    if (p == null) return const ProtectOutcome('none');
    if (p.left(clock) > 0) return ProtectOutcome('waiting', dueAt: due(p));
    _clearPending();
    switch (p.what) {
      case pinChange:
        _put('pin', p.pinRecord);
        _saved();
        return const ProtectOutcome('done');
      case pinClear:
        _put('pin', null);
        _saved();
        return const ProtectOutcome('done');
      default:
        return ProtectOutcome('done', apply: (p.what, p.value));
    }
  }

  ProtectOutcome? _verify(String? pin) {
    final locked = lockedUntil();
    if (locked != null) return ProtectOutcome('locked', lockedUntil: locked);
    if (pin == null || pin.isEmpty) return const ProtectOutcome('pin_needed');
    if (pinMatches(pin, store['pin'] as String?)) {
      _put('pin_fails', null);
      _put('pin_lock', null);
      _saved();
      return null;
    }
    final fails = ((store['pin_fails'] as int?) ?? 0) + 1;
    _put('pin_fails', fails);
    final lock = ProtectionRules.lockMs(fails);
    if (lock > 0) {
      _put('pin_lock', Countdown.start(lock, clock).toJson());
      _saved();
      return ProtectOutcome('locked', lockedUntil: clock.wallMs() + lock);
    }
    _saved();
    return ProtectOutcome('pin_wrong', triesLeft: ProtectionRules.tries - fails % ProtectionRules.tries);
  }

  int? lockedUntil() {
    final left = Countdown.fromJson(store['pin_lock'])?.remaining(clock);
    if (left == null) return null;
    if (left <= 0) {
      _put('pin_lock', null);
      return null;
    }
    return clock.wallMs() + left;
  }

  ProtectOutcome _startWait(String what, Object? value, String? record) {
    final ms = delayMinutes() * 60000;
    _put('pending', {'what': what, 'value': value, 'pin': record, 'due': Countdown.start(ms, clock).toJson()});
    _saved();
    return ProtectOutcome('pending', dueAt: clock.wallMs() + ms);
  }

  /// The pending request; a lapsed one is dropped here.
  PendingRequest? pending() {
    final m = store['pending'];
    final cd = m is Map ? Countdown.fromJson(m['due']) : null;
    final what = m is Map ? m['what'] : null;
    if (m == null) return null;
    if (cd == null || what is! String || cd.remaining(clock) <= -ProtectionRules.confirmMs) {
      _clearPending();
      return null;
    }
    return PendingRequest(what, (m as Map)['value'], cd, m['pin'] as String?);
  }

  void _clearPending() {
    if (store.remove('pending') != null) _saved();
  }

  int due(PendingRequest p) => clock.wallMs() + p.left(clock);

  /// Saves the time left now (every minute while pending).
  void checkpoint() {
    final p = pending();
    if (p != null) (store['pending'] as Map)['due'] = p.countdown.checkpoint(clock).toJson();
    final lock = Countdown.fromJson(store['pin_lock']);
    if (lock != null) store['pin_lock'] = lock.checkpoint(clock).toJson();
    if (p != null || lock != null) _saved();
  }

  /// `features.protect`.
  Map<Object?, Object?> snapshot() {
    final p = pending();
    final left = p?.left(clock);
    return {
      'pinSet': pinSet,
      'delayMinutes': delayMinutes(),
      'pending': p == null
          ? null
          : {
              'what': p.what,
              'value': p.value,
              'dueAt': clock.wallMs() + left!,
              'confirmUntil': clock.wallMs() + left + ProtectionRules.confirmMs,
              'ready': left <= 0,
            },
      'lockedUntil': lockedUntil(),
    };
  }
}

class PendingRequest {
  const PendingRequest(this.what, this.value, this.countdown, this.pinRecord);
  final String what;
  final Object? value;
  final Countdown countdown;
  final String? pinRecord;
  int left(ProtectionClock c) => countdown.remaining(c);
}

/// The guard for a [MemoryBackend]-based backend (desktop, tests): call [checkSetting] / [checkStop] first in
/// setSetting / stopFilter, register [methods] as `protect.*`, and show [section] as `features.protect`.
class ProtectionGate {
  ProtectionGate(this.core, {required this.apply, required this.changed});

  final ProtectionCore core;

  /// Makes an allowed change without the guard: a setting key or "stop".
  final Future<void> Function(String what, Object? value) apply;

  /// The snapshot section changed.
  final void Function() changed;

  String _detail(String what, Object? value, ({bool pin, bool wait}) g) {
    final p = core.pending();
    final same = p != null && p.what == what && p.value == (what == ProtectionCore.stop ? null : ProtectionRules.normalize(what, value));
    return jsonEncode({
      'need': same ? 'waiting' : (g.pin && g.wait ? 'pin_wait' : (g.pin ? 'pin' : 'wait')),
      'what': what,
      'value': value,
      'delayMinutes': core.delayMinutes(),
      if (same) 'dueAt': core.due(p),
    });
  }

  /// Throws BackendException('protected', detail) when the change is held back.
  void checkSetting(String key, Object? value) {
    final had = core.pending() != null;
    final g = core.check(key, value);
    if (had && core.pending() == null) changed();
    if (g != null) throw BackendException('protected', _detail(key, value, g));
  }

  void checkStop() {
    final g = core.checkStop();
    if (g == null) {
      changed();
      return;
    }
    throw BackendException('protected', _detail(ProtectionCore.stop, null, g));
  }

  Map<Object?, Object?> section() => core.snapshot();

  Map<String, Future<Object?> Function(Map<String, Object?> args)> get methods => {
        'protect.request': (a) => _run(() {
              final what = a['what'];
              if (what is! String) throw const BackendException('bad_args', 'what');
              return core.request(what, a['value'], a['pin'] as String?);
            }),
        'protect.setPin': (a) => _run(() => core.setPin(a['pin'] as String?, a['oldPin'] as String?)),
        'protect.clearPin': (a) => _run(() => core.clearPin(a['pin'] as String?)),
        'protect.cancel': (_) => _run(() {
              core.cancel();
              return const ProtectOutcome('done');
            }),
        'protect.confirm': (_) => _run(core.confirm),
        'protect.promptShown': (_) async => const {'status': 'done'},
      };

  Future<Object?> _run(ProtectOutcome Function() f) async {
    final ProtectOutcome o;
    try {
      o = f();
    } on ArgumentError catch (e) {
      throw BackendException('bad_args', '${e.message}');
    }
    final a = o.apply;
    if (a != null) await apply(a.$1, a.$2);
    changed();
    return o.toMap();
  }
}
