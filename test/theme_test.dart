import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jobzone/design_system/design_system.dart';

void main() {
  test('light/dark themes expose JzColors with the indigo primary', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    expect(light.extension<JzColors>(), isNotNull);
    expect(dark.extension<JzColors>(), isNotNull);
    expect(light.extension<JzColors>()!.primary, const Color(0xFF3A36DB));
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
  });
}
