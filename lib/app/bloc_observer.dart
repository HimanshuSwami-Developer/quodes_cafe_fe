import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Logs bloc errors everywhere and transitions outside prod.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver({required this.verbose});
  final bool verbose;

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (verbose) {
      debugPrint('◆ ${bloc.runtimeType}: ${change.nextState.runtimeType}');
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    debugPrint('◆ ${bloc.runtimeType} error: $error\n$stackTrace');
    super.onError(bloc, error, stackTrace);
  }
}
