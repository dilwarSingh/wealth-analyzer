// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    print('coverage/lcov.info not found');
    return;
  }
  final lines = file.readAsLinesSync();
  String currentFile = '';
  int lf = 0;
  int lh = 0;
  final results = <Map<String, dynamic>>[];

  final uncovered = <String, List<int>>{};

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      final lineNum = int.parse(parts[0]);
      final hits = int.parse(parts[1]);
      if (hits == 0) {
        uncovered.putIfAbsent(currentFile, () => []).add(lineNum);
      }
    } else if (line.startsWith('LF:')) {
      lf = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      lh = int.parse(line.substring(3));
      final pct = lf > 0 ? (lh / lf) * 100 : 100.0;
      results.add({
        'file': currentFile,
        'lf': lf,
        'lh': lh,
        'pct': pct,
      });
    }
  }

  results.sort((a, b) => (a['pct'] as double).compareTo(b['pct'] as double));

  int totalLf = 0;
  int totalLh = 0;

  print('========================================================================');
  print('FILE COVERAGE SUMMARY');
  print('========================================================================');
  for (final r in results) {
    totalLf += r['lf'] as int;
    totalLh += r['lh'] as int;
    final pct = (r['pct'] as double).toStringAsFixed(1);
    final status = (r['pct'] as double) >= 85.0 ? 'PASS' : 'LOW ';
    final f = r['file'] as String;
    print('$status ${pct.padLeft(5)}% (${r['lh']}/${r['lf']}) - $f');
    if ((r['pct'] as double) < 85.0) {
      print('   -> Uncovered: ${uncovered[f]}');
    }
  }
  final totalPct = totalLf > 0 ? ((totalLh / totalLf) * 100).toStringAsFixed(1) : '100.0';
  print('========================================================================');
  print('TOTAL COVERAGE: $totalPct% ($totalLh/$totalLf)');
  print('========================================================================');
}
