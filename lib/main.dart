import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

import 'package:abonos_app/app/app.dart';

void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[flutter_error] ${details.exception}');
    if (details.stack != null) {
      debugPrintStack(stackTrace: details.stack);
    }
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    debugPrint('[platform_error] $error');
    debugPrintStack(stackTrace: stackTrace);
    return false;
  };

  runApp(const AbonosApp());
}
