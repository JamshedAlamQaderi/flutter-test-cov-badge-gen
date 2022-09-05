import 'dart:io';

import 'package:cov_badge_gen/cov_badge_gen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Should read lcov.info file and validate coverage ratio to 90%',
      () async {
    final generator = CovBadgeGen.parseArguments([]);
    final coverageRatio = await generator.coverageRatio();
    expect(coverageRatio.toInt(), 90);
  });

  test('Generate a badge svg file & file should exists', () async {
    final generator = CovBadgeGen.parseArguments([]);
    generator.generateBadge();
    final file = File('./coverage/coverage_badge.svg');
    expect(file.existsSync(), isTrue);
  });

  test('Should validate error after reading file with coverage ratio 90%',
      () async {
    final generator = CovBadgeGen.parseArguments([]);
    final ratio = await generator.coverageRatio();
    generator.generateBadge();
    final file = File('./coverage/coverage_badge.svg');
    expect(file.readAsStringSync(), generator.generateBadgeSvg(ratio.toInt()));
  });
}
