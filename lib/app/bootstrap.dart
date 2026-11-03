import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config/env.dart';
import 'app.dart';
import 'bloc_observer.dart';
import 'di.dart';

/// Shared startup for every flavor entrypoint.
Future<void> bootstrap(Flavor flavor) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Web: real paths (/admin/bookings) instead of /#/admin/bookings.
      usePathUrlStrategy();
      final config = AppConfig.of(flavor);
      Bloc.observer = AppBlocObserver(verbose: config.httpLogging);
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        // Hook a crash reporter (Crashlytics/Sentry) here for stage & prod.
      };
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
      // Fonts ship in assets/fonts; never download them at runtime.
      GoogleFonts.config.allowRuntimeFetching = false;
      LicenseRegistry.addLicense(() async* {
        for (final f in ['Fredoka', 'Nunito']) {
          yield LicenseEntryWithLineBreaks([
            f,
          ], await rootBundle.loadString('assets/fonts/OFL-$f.txt'));
        }
      });
      final deps = await AppDependencies.create(config);
      runApp(QuodesApp(deps: deps));
    },
    (error, stack) {
      debugPrint('Uncaught: $error\n$stack');
    },
  );
}
