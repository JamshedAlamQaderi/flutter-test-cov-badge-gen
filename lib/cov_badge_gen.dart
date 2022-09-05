library cov_badge_gen;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

class CovBadgeGen {
  final _log = Logger('CovBadgeGen');
  final String lcovPath;
  final String outputDir;
  late File _sourceFile;
  late File _outputFile;

  String subject = 'Coverage';

  String successColor = '#00e676';
  String warningColor = '#ff9100';
  String errorColor = '#ff3d00';

  int warningThreshold = 80; // 80 % and below
  int errorThreshold = 60; // 60% & below

  CovBadgeGen(this.lcovPath, this.outputDir) {
    _setupLogger();
    _createFile();
  }

  static CovBadgeGen parseArguments(List<String> args) {
    final parser = ArgParser();
    parser.addOption(
      'lcov_path',
      abbr: 'p',
      defaultsTo: './coverage/lcov.info',
      help: 'lcov.info file path of test coverage',
    );
    parser.addOption(
      'output_dir',
      abbr: 'o',
      defaultsTo: './coverage',
      help: 'Output dir of generated badge',
    );
    final results = parser.parse(args);
    return CovBadgeGen(
      results['lcov_path'],
      results['output_dir'],
    );
  }

  void _createFile() async {
    _sourceFile = File(lcovPath);
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      dir.createSync();
      _log.info('Created output dir: $outputDir');
    }
    _outputFile = File(p.join(dir.path, 'coverage_badge.svg'));
  }

  void generateBadge() async {
    final coverageValue = await coverage();
    _log.info('Coverage: $coverageValue');
    _generateBadgeSvg(coverageValue.toInt());
  }

  Future<double> coverage() {
    return _readAndGetCoverage();
  }

  Future<double> _readAndGetCoverage() {
    final completer = Completer<double>();
    if (_sourceFile.existsSync()) {
      _log.info('lcov file reading started...');
      double instrumentedLines = 0;
      double coveredLines = 0;
      _sourceFile
          .openRead()
          .map(utf8.decode)
          .transform(const LineSplitter())
          .forEach((line) {
        if (line.startsWith('LH:')) {
          coveredLines += double.parse(line.split(':')[1]);
        } else if (line.startsWith('LF:')) {
          instrumentedLines += double.parse(line.split(':')[1]);
        }
      }).whenComplete(() {
        if (instrumentedLines == 0) {
          completer.complete(0);
        } else {
          completer.complete((coveredLines / instrumentedLines) * 100.0);
        }
      });
    } else {
      _log.warning('File not exists. Returning 0.0');
      completer.complete(0.0);
    }
    return completer.future;
  }

  void generateBadgeSvg(int ratio) {
    return _generateBadgeSvg(ratio);
  }

  void _generateBadgeSvg(int ratio) {
    String selectedColor = '';
    if (ratio <= errorThreshold) {
      selectedColor = errorColor;
    } else if (ratio <= warningThreshold) {
      selectedColor = warningColor;
    } else {
      selectedColor = successColor;
    }
    final badgeSvgStr = """
            <svg xmlns="http://www.w3.org/2000/svg" width="100" height="18">
      <linearGradient id="smooth" x2="0" y2="100%">
        <stop offset="0"  stop-color="#fff" stop-opacity=".7"/>
        <stop offset=".1" stop-color="#aaa" stop-opacity=".1"/>
        <stop offset=".9" stop-color="#000" stop-opacity=".3"/>
        <stop offset="1"  stop-color="#000" stop-opacity=".5"/>
      </linearGradient>
      <rect rx="4" width="100" height="18" fill="#555"/>
      <rect rx="4" x="58" width="42" height="18" fill="$selectedColor"/>
      <rect x="58" width="4" height="18" fill="$selectedColor"/>
      <rect rx="4" width="100" height="18" fill="url(#smooth)"/>
      <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
        <text x="30" y="14" fill="#010101" fill-opacity=".3">$subject</text>
        <text x="30" y="13">$subject</text>
        <text x="80" y="14" fill="#010101" fill-opacity=".3">$ratio%</text>
        <text x="80" y="13">$ratio%</text>
      </g>
      </svg>
    """;
    _outputFile.writeAsStringSync(badgeSvgStr, flush: true);
    _log.info('Badge created successfully with Coverage ration of $ratio%');
  }
}

void _setupLogger() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print(
      '${record.level.name}: [COV_BADGE_GEN] : ${record.time}: ${record.message}',
    );
  });
}
