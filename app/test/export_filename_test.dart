import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/settings/export_filename.dart';

void main() {
  final at = DateTime(2026, 7, 24, 17, 5, 9);

  test('the device name and the moment of export identify the file', () {
    expect(
      exportFileName('Entrance Tablet', at),
      'ks-backup_Entrance-Tablet_20260724_170509.json',
    );
  });

  test('a name a filesystem would object to is reduced to one it accepts', () {
    expect(
      exportNameSlug('KS / Echo Show 5 (kitchen)'),
      'KS-Echo-Show-5-kitchen',
    );
    expect(exportNameSlug('  ..Hall..  '), 'Hall');
  });

  test('accented letters keep their letter instead of losing it', () {
    expect(exportNameSlug('Küche'), 'Kuche');
    expect(exportNameSlug('Salón'), 'Salon');
    expect(exportNameSlug('Habitación Niños'), 'Habitacion-Ninos');
    expect(exportNameSlug('Straße'), 'Strasse');
  });

  test('characters with no plain form drop out rather than corrupt it', () {
    expect(exportNameSlug('Café ☕'), 'Cafe');
    expect(exportNameSlug('Tablet 📱 #1'), 'Tablet-1');
    // Nothing usable at all falls back to the timestamp alone.
    expect(exportFileName('北京', at), 'ks-backup_20260724_170509.json');
  });

  test('an unnamed device still gets a distinguishable file', () {
    expect(exportFileName('', at), 'ks-backup_20260724_170509.json');
    // A name made entirely of separators reduces to nothing, same as none.
    expect(exportFileName('---', at), 'ks-backup_20260724_170509.json');
  });

  test('a very long name is cut without leaving a trailing dash', () {
    final slug = exportNameSlug('${'a' * 39} bbbb');
    expect(slug.length, lessThanOrEqualTo(40));
    expect(slug.endsWith('-'), isFalse);
  });

  test('the timestamp is zero padded so a listing sorts by time', () {
    expect(exportTimestamp(DateTime(2026, 1, 2, 3, 4, 5)), '20260102_030405');
  });
}
