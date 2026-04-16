import 'dart:async';

import 'package:flutter/foundation.dart';

/// Silences all runtime logs (debugPrint + print) in the current isolate.
class LogSilencer {
  LogSilencer._();

  static void run(void Function() action) {
    debugPrint = (String? message, {int? wrapWidth}) {};
    runZonedGuarded(
      action,
      (error, stackTrace) {},
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {},
      ),
    );
  }

  static Future<void> runAsync(Future<void> Function() action) async {
    debugPrint = (String? message, {int? wrapWidth}) {};
    await runZonedGuarded(
      () async {
        await action();
      },
      (error, stackTrace) {},
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {},
      ),
    );
  }
}
