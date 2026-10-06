import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/format_bytes.dart';

void main() {
  test('bytes e kilobytes', () {
    expect(formatBytes(0), '0 B');
    expect(formatBytes(512), '512 B');
    expect(formatBytes(1024), '1 KB');
    expect(formatBytes(163 * 1024), '163 KB');
  });

  test('megabytes: uma casa com vírgula abaixo de 10, inteiro a partir de 10',
      () {
    expect(formatBytes(1024 * 1024), '1,0 MB');
    expect(formatBytes((2.4 * 1024 * 1024).round()), '2,4 MB');
    expect(formatBytes(12 * 1024 * 1024), '12 MB');
    expect(formatBytes(30 * 1024 * 1024), '30 MB');
  });

  test('valor negativo não quebra', () {
    expect(formatBytes(-5), '0 B');
  });
}
