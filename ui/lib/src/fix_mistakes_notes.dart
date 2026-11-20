/// Desktop "wrong detection" notes (Fix mistakes on the spot, lane A): the same one-line, tab-separated notes as
/// Android's FixMistakesNotes.kt, at most [FixNotes.max], the oldest dropped, in a file of the desktop's state folder.
/// Nothing is sent anywhere: the user reads them, copies them, or deletes them.
library;

import 'dart:io';

class FixNotes {
  FixNotes(this.file, {this.max = 500});

  final File file;
  final int max;

  static const kinds = {'missed', 'wrong'};

  static String _clean(String s) => s.replaceAll(RegExp(r'[\t\r\n]+'), ' ').trim();

  List<String> read() {
    try {
      return file.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
    } on IOException {
      return [];
    }
  }

  int get count => read().length;

  /// Adds one note; returns the number kept. Written to a temporary file first: never half a file.
  int add({
    required DateTime time,
    required String kind,
    required String where,
    String app = '',
    required String filter,
    required String blur,
    required String models,
  }) {
    if (!kinds.contains(kind)) throw ArgumentError.value(kind, 'kind');
    final t = time.toIso8601String().split('.').first.replaceFirst('T', ' ');
    final line = [t, kind, where, app, filter, blur, models].map(_clean).join('\t');
    var lines = [...read(), line];
    if (lines.length > max) lines = lines.sublist(lines.length - max);
    file.parent.createSync(recursive: true);
    final tmp = File('${file.path}.tmp');
    tmp.writeAsStringSync('${lines.join('\n')}\n');
    tmp.renameSync(file.path);
    return lines.length;
  }

  void clear() {
    try {
      file.deleteSync();
    } on IOException {
      // nothing to delete
    }
  }

  /// The notes as plain text, newest first (English field names, like the diagnostics report).
  String text(String header) {
    final notes = [
      for (final l in read())
        if (l.split('\t') case final f when f.length >= 7 && kinds.contains(f[1])) f,
    ];
    final b = StringBuffer()
      ..writeln(header)
      ..writeln('${notes.length} note(s), newest first.');
    for (final f in notes.reversed) {
      b
        ..writeln()
        ..writeln('${f[0]}  ${f[1] == 'missed' ? 'missed something' : 'hidden by mistake'} (from ${f[2]})');
      if (f[3].isNotEmpty) b.writeln('  app: ${f[3]}');
      b
        ..writeln('  filter: ${f[4]}')
        ..writeln('  blur: ${f[5]}');
      if (f[6].isNotEmpty) b.writeln('  models: ${f[6]}');
    }
    return b.toString().trimRight();
  }
}
