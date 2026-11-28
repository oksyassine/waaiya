/// Protection that survives a weak moment (docs/FEATURES_CONTRACT.md, lane B): a waiting period and a local PIN.
/// Snapshot section `protect`, methods `protect.*`. The guard itself is native (Android: Protection.kt; desktop and
/// tests: ProtectionGate in protection_core.dart); this file only shows the card and the dialogs.
///
/// `features.protect`:
///   pinSet (bool), delayMinutes (int),
///   pending {what, value, dueAt, confirmUntil, ready}?   one change waiting (what: a setting key, `stop`,
///                                                       `pin_change`, `pin_clear`); times are ms since the epoch
///   lockedUntil (int)?                                  too many wrong PINs: no PIN is checked until then
///   prompt {id, need, what, delayMinutes, dueAt?}?      a Stop refused outside the app (notification, tile): asked here
/// A refusal is BackendException('protected', json {need: pin|wait|pin_wait|waiting, what, value, delayMinutes, dueAt?}).
/// Methods (each returns {status: done|pending|waiting|none|pin_needed|pin_wrong|locked, dueAt?, triesLeft?,
/// lockedUntil?}): protect.request {what, value?, pin?}, protect.setPin {pin, oldPin?}, protect.clearPin {pin},
/// protect.cancel, protect.confirm, protect.promptShown.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';
import 'home.dart';
import 'widgets.dart';

/// The waiting periods offered, in minutes.
const protectDelays = [0, 1, 5, 15, 30, 60, 240, 1440];

class ProtectPending {
  ProtectPending(Map<Object?, Object?> m)
      : what = m['what'] as String? ?? '',
        value = m['value'],
        dueAt = DateTime.fromMillisecondsSinceEpoch((m['dueAt'] as num?)?.toInt() ?? 0),
        confirmUntil = DateTime.fromMillisecondsSinceEpoch((m['confirmUntil'] as num?)?.toInt() ?? 0),
        _ready = m['ready'] == true;

  final String what;
  final Object? value;
  final DateTime dueAt;
  final DateTime confirmUntil;
  final bool _ready;

  /// The wait is over (the backend says so, or the time shown has come: the backend checks again on Confirm).
  bool get ready => _ready || !DateTime.now().isBefore(dueAt);
}

/// The `features.protect` section, read with defaults.
class ProtectInfo {
  ProtectInfo(Map<Object?, Object?> m)
      : pinSet = m['pinSet'] == true,
        delayMinutes = (m['delayMinutes'] as num?)?.toInt() ?? 0,
        pending = m['pending'] is Map ? ProtectPending(m['pending'] as Map<Object?, Object?>) : null,
        lockedUntil = m['lockedUntil'] is num
            ? DateTime.fromMillisecondsSinceEpoch((m['lockedUntil'] as num).toInt())
            : null,
        prompt = m['prompt'] is Map ? m['prompt'] as Map<Object?, Object?> : null;

  final bool pinSet;
  final int delayMinutes;
  final ProtectPending? pending;
  final DateTime? lockedUntil;
  final Map<Object?, Object?>? prompt;
}

String protectDelayLabel(AppLocalizations l, int minutes) => switch (minutes) {
      0 => l.protectDelayOff,
      1 => l.protectDelay1m,
      5 => l.protectDelay5m,
      15 => l.protectDelay15m,
      30 => l.protectDelay30m,
      60 => l.protectDelay1h,
      240 => l.protectDelay4h,
      1440 => l.protectDelay24h,
      _ => l.protectDelayOther(minutes),
    };

/// What a pending or refused change does, in words. (Generated messages take their placeholders in alphabetical
/// order: protectPending(time, what).)
String protectWhat(AppLocalizations l, String what, Object? value) {
  String? name(String key) => switch (key) {
        SettingKeys.blurEnabled => l.blurTitle,
        SettingKeys.blurWomen => l.blurWomenTitle,
        SettingKeys.blurNudity => l.blurNudityTitle,
        SettingKeys.blurFailCover => l.blurFailTitle,
        SettingKeys.silenceUnfilterable => l.settingSilenceTitle,
        SettingKeys.holdSilence => l.settingHoldSilenceTitle,
        SettingKeys.muteWomenSinging => l.settingSingingTitle,
        SettingKeys.keepSinging => l.singingKeepTitle,
        SettingKeys.filterOffApps => l.fixFilterAppsTitle,
        SettingKeys.blurOffApps => l.fixBlurAppsTitle,
        _ => null,
      };
  return switch (what) {
    'stop' => l.protectWhatStop,
    'pin_change' => l.protectWhatPinChange,
    'pin_clear' => l.protectWhatPinClear,
    SettingKeys.blurStrictness => l.protectWhatStrictness,
    SettingKeys.gender => l.protectWhatGender,
    SettingKeys.protectDelayMinutes => l.protectWhatDelay(protectDelayLabel(l, value is int ? value : 0)),
    SettingKeys.keepSinging => l.protectWhatOn(l.singingKeepTitle),
    SettingKeys.filterOffApps || SettingKeys.blurOffApps => l.protectWhatApps(name(what)!),
    _ => name(what) != null ? l.protectWhatOff(name(what)!) : l.protectWhatSetting,
  };
}

/// "14:05", or "tomorrow at 14:05".
String protectTime(BuildContext context, DateTime t) {
  final l = AppLocalizations.of(context);
  final hm = MaterialLocalizations.of(context)
      .formatTimeOfDay(TimeOfDay.fromDateTime(t), alwaysUse24HourFormat: MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false);
  final now = DateTime.now();
  final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
  return sameDay ? hm : l.protectTomorrow(hm);
}

/// Called by runAction when the backend refused a change with `protected` (waiting period or PIN).
Future<void> onProtected(BuildContext context, BackendException e) async {
  Map<String, Object?>? d;
  try {
    final j = jsonDecode(e.message);
    if (j is Map<String, Object?>) d = j;
  } on FormatException {
    d = null;
  }
  final what = d?['what'];
  if (d == null || what is! String) {
    // an older or test backend without the detail: say it is held back, change nothing
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).protectHeldBack)));
    return;
  }
  await askProtected(
    context,
    need: d['need'] as String? ?? 'wait',
    what: what,
    value: d['value'],
    delayMinutes: (d['delayMinutes'] as num?)?.toInt() ?? 0,
    dueAt: d['dueAt'] is num ? DateTime.fromMillisecondsSinceEpoch((d['dueAt'] as num).toInt()) : null,
  );
}

/// The PIN and/or the waiting period for one change; then `protect.request`.
Future<void> askProtected(
  BuildContext context, {
  required String need,
  required String what,
  Object? value,
  int delayMinutes = 0,
  DateTime? dueAt,
}) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final whatText = protectWhat(l, what, value);
  if (need == 'waiting') {
    if (dueAt != null) messenger?.showSnackBar(SnackBar(content: Text(l.protectAlreadyWaiting(protectTime(context, dueAt)))));
    return;
  }
  final wait = need == 'wait' || need == 'pin_wait';
  final at = DateTime.now().add(Duration(minutes: delayMinutes));
  final waitText = l.protectWaitBody(protectTime(context, at), whatText);
  final args = <String, Object?>{'what': what, 'value': value};
  if (need == 'wait') {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true, // large text on a small screen: nothing is cut off
        title: Text(l.protectWaitTitle),
        content: Text(waitText),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.protectCancel)),
          FilledButton(
              key: const Key('protect_wait_start'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.protectWaitStart)),
        ],
      ),
    );
    if (go != true || !context.mounted) return;
    final r = await _call(context, 'protect.request', args);
    if (context.mounted) await _report(context, r);
    return;
  }
  await _withPin(context, l.protectPinTitle, wait ? waitText : whatText,
      (pin) => _call(context, 'protect.request', {...args, 'pin': pin}));
}

/// Asks the PIN until it is right, cancelled or locked, calling [send] with it.
Future<void> _withPin(BuildContext context, String title, String body,
    Future<Map<Object?, Object?>?> Function(String pin) send) async {
  final l = AppLocalizations.of(context);
  String? error;
  while (true) {
    if (!context.mounted) return;
    final pins = await _pinDialog(context, title: title, body: body, error: error, fields: const [_PinField.current]);
    if (pins == null || !context.mounted) return;
    final r = await send(pins.first);
    if (r == null || !context.mounted) return;
    if (r['status'] == 'pin_wrong') {
      error = l.protectPinWrong((r['triesLeft'] as num?)?.toInt() ?? 0);
      continue;
    }
    await _report(context, r);
    return;
  }
}

Future<Map<Object?, Object?>?> _call(BuildContext context, String method, Map<String, Object?> args) async {
  final backend = WaaiyaScope.of(context).backend;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l = AppLocalizations.of(context);
  try {
    final r = await backend.invoke(method, args);
    return r is Map ? r : const {'status': 'done'};
  } on BackendException catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(l.actionFailed(e.message.isEmpty ? e.code : e.message))));
    return null;
  }
}

/// Says what happened, when it is not visible on the screen already.
Future<void> _report(BuildContext context, Map<Object?, Object?>? r) async {
  if (r == null || !context.mounted) return;
  final l = AppLocalizations.of(context);
  DateTime? time(String k) => r[k] is num ? DateTime.fromMillisecondsSinceEpoch((r[k] as num).toInt()) : null;
  final text = switch (r['status']) {
    'pending' => time('dueAt') == null ? null : l.protectStarted(protectTime(context, time('dueAt')!)),
    'waiting' => time('dueAt') == null ? null : l.protectAlreadyWaiting(protectTime(context, time('dueAt')!)),
    'locked' => time('lockedUntil') == null ? null : l.protectLocked(protectTime(context, time('lockedUntil')!)),
    'pin_needed' => l.protectPinTitle,
    _ => null,
  };
  if (text != null) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));
}

enum _PinField { current, newPin, again }

/// One dialog with the PIN fields asked; returns their values (validated: 4 to 8 digits, the two new ones equal).
Future<List<String>?> _pinDialog(BuildContext context,
    {required String title, String? body, String? error, required List<_PinField> fields}) {
  return showDialog<List<String>>(
    context: context,
    builder: (context) => _PinDialog(title: title, body: body, error: error, fields: fields),
  );
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.title, this.body, this.error, required this.fields});

  final String title;
  final String? body;
  final String? error;
  final List<_PinField> fields;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  late final _controllers = [for (final _ in widget.fields) TextEditingController()];
  late String? _error = widget.error;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _ok() {
    final l = AppLocalizations.of(context);
    final values = [for (final c in _controllers) c.text];
    for (var i = 0; i < values.length; i++) {
      if (!RegExp(r'^[0-9]{4,8}$').hasMatch(values[i])) {
        setState(() => _error = l.protectPinBad);
        return;
      }
    }
    final n = widget.fields.indexOf(_PinField.newPin), a = widget.fields.indexOf(_PinField.again);
    if (n >= 0 && a >= 0 && values[n] != values[a]) {
      setState(() => _error = l.protectPinDiffer);
      return;
    }
    Navigator.pop(context, values);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.body != null) Text(widget.body!),
            for (var i = 0; i < widget.fields.length; i++)
              TextField(
                key: Key('protect_pin_${widget.fields[i].name}'),
                controller: _controllers[i],
                autofocus: i == 0,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: switch (widget.fields[i]) {
                    _PinField.current => l.protectPinCurrent,
                    _PinField.newPin => l.protectPinNew,
                    _PinField.again => l.protectPinAgain,
                  },
                  counterText: '',
                ),
                onSubmitted: (_) => i == widget.fields.length - 1 ? _ok() : null,
              ),
            if (_error != null) StatusText(_error!, isError: true),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.protectCancel)),
        FilledButton(key: const Key('protect_pin_ok'), onPressed: _ok, child: Text(l.protectOk)),
      ],
    );
  }
}

/// Settings page, under the worship card: the waiting period, the PIN, a waiting change with Cancel / Confirm, and
/// what this cannot stop.
class ProtectionCard extends StatefulWidget {
  const ProtectionCard({super.key});

  @override
  State<ProtectionCard> createState() => _ProtectionCardState();
}

class _ProtectionCardState extends State<ProtectionCard> {
  Timer? _ticker;
  Object? _handledPrompt;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// While a change waits, the card follows the clock (the wait ending, the time to confirm ending).
  void _tick(bool pending) {
    if (pending && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted) setState(() {});
      });
    } else if (!pending) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Future<void> _setPin(ProtectInfo p) async {
    final l = AppLocalizations.of(context);
    String? error;
    while (true) {
      if (!mounted) return;
      final pins = await _pinDialog(context,
          title: p.pinSet ? l.protectPinChangeTitle : l.protectPinNewTitle,
          body: p.pinSet ? null : l.protectPinForgot,
          error: error,
          fields: [if (p.pinSet) _PinField.current, _PinField.newPin, _PinField.again]);
      if (pins == null || !mounted) return;
      final r = await _call(context, 'protect.setPin', {'pin': pins[p.pinSet ? 1 : 0], if (p.pinSet) 'oldPin': pins[0]});
      if (r == null || !mounted) return;
      if (r['status'] == 'pin_wrong') {
        error = l.protectPinWrong((r['triesLeft'] as num?)?.toInt() ?? 0);
        continue;
      }
      await _report(context, r);
      return;
    }
  }

  Future<void> _clearPin() async {
    final l = AppLocalizations.of(context);
    await _withPin(context, l.protectPinTitle, protectWhat(l, 'pin_clear', null),
        (pin) => _call(context, 'protect.clearPin', {'pin': pin}));
  }

  Future<void> _chooseDelay(int current) async {
    final l = AppLocalizations.of(context);
    final i = await chooseOne(context,
        title: l.protectDelayTitle,
        options: [for (final m in protectDelays) protectDelayLabel(l, m)],
        selected: protectDelays.indexOf(current));
    if (i == null || protectDelays[i] == current || !mounted) return;
    final chosen = protectDelays[i];
    // a long wait binds the person for hours (shortening it waits too): one tap in a list is not enough for that
    if (chosen > current && chosen >= 240) {
      final label = protectDelayLabel(l, chosen);
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.protectDelayTitle),
          content: Text(l.protectDelayLongAsk(label)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel)),
            FilledButton(key: const Key('protect_delay_confirm'), onPressed: () => Navigator.pop(ctx, true),
                child: Text(MaterialLocalizations.of(ctx).okButtonLabel)),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    if (!mounted) return;
    await HomeScreen.set(context, SettingKeys.protectDelayMinutes, chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = WaaiyaScope.of(context).state;
    final section = s.feature('protect');
    final p = ProtectInfo(section);
    final pending = p.pending;
    _tick(pending != null);
    // a Stop refused outside the app (notification, Quick Settings tile): asked here, once
    final prompt = p.prompt;
    if (prompt != null && prompt['id'] != _handledPrompt) {
      _handledPrompt = prompt['id'];
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _call(context, 'protect.promptShown', const {});
        if (!context.mounted) return;
        await askProtected(context,
            need: prompt['need'] as String? ?? 'wait',
            what: prompt['what'] as String? ?? 'stop',
            delayMinutes: (prompt['delayMinutes'] as num?)?.toInt() ?? 0,
            dueAt: prompt['dueAt'] is num ? DateTime.fromMillisecondsSinceEpoch((prompt['dueAt'] as num).toInt()) : null);
      });
    }
    final locked = p.lockedUntil;
    final android = s.platform == 'android';
    final text = Theme.of(context).textTheme;
    return KeyedSubtree(
      key: const Key('protect_card'),
      child: SectionCard(
        title: l.protectTitle,
        body: l.protectBody,
        children: [
          ValueRow(
            key: const Key('protect_delay'),
            label: l.protectDelay(protectDelayLabel(l, p.delayMinutes)),
            action: l.change,
            onPressed: () => _chooseDelay(p.delayMinutes),
          ),
          Text(l.protectDelayBody, style: text.bodySmall),
          if (p.pinSet)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LabelAndActions(
                label: Text(l.protectPinIsSet, style: text.bodyLarge),
                actions: [
                  TextButton(key: const Key('protect_pin_change'), onPressed: () => _setPin(p), child: Text(l.change)),
                  TextButton(key: const Key('protect_pin_remove'), onPressed: _clearPin, child: Text(l.protectPinRemove)),
                ],
              ),
            )
          else
            ValueRow(
              key: const Key('protect_pin_set'),
              label: l.protectPinNone,
              action: l.protectPinSet,
              onPressed: () => _setPin(p),
            ),
          Text(l.protectPinBody, style: text.bodySmall),
          if (locked != null && locked.isAfter(DateTime.now()))
            StatusText(l.protectLocked(protectTime(context, locked)), isError: true),
          if (pending != null) ...[
            const SizedBox(height: 4),
            StatusText(
              pending.ready
                  ? l.protectReady(protectTime(context, pending.confirmUntil), protectWhat(l, pending.what, pending.value))
                  : l.protectPending(protectTime(context, pending.dueAt), protectWhat(l, pending.what, pending.value)),
              id: 'protect_pending',
              color: pending.ready ? Theme.of(context).colorScheme.primary : null,
            ),
            Wrap(
              spacing: 8,
              children: [
                if (pending.ready)
                  FilledButton(
                    key: const Key('protect_confirm'),
                    onPressed: () async {
                      final r = await _call(context, 'protect.confirm', const {});
                      if (context.mounted) await _report(context, r);
                    },
                    child: Text(l.protectConfirm),
                  ),
                OutlinedButton(
                  key: const Key('protect_cancel'),
                  onPressed: () => _call(context, 'protect.cancel', const {}),
                  child: Text(l.protectCancelChange),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
              android
                  ? l.protectLimits
                  : (s.platform == 'windows' ? l.protectLimitsWindows : l.protectLimitsDesktop),
              style: text.bodySmall),
        ],
      ),
    );
  }
}

