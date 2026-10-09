import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/core/config/orientation_policy.dart';

void main() {
  test('Smartphone: nur Hochformat', () {
    expect(allowedOrientations(390), [DeviceOrientation.portraitUp]);
  });

  test('Tablet: Hochformat und Querformat', () {
    final orientations = allowedOrientations(820);
    expect(orientations, contains(DeviceOrientation.portraitUp));
    expect(orientations, contains(DeviceOrientation.landscapeLeft));
    expect(orientations, contains(DeviceOrientation.landscapeRight));
  });
}
