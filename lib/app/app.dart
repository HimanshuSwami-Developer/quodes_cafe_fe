import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/config/env.dart';
import '../core/router/app_router.dart';
import '../features/booking_flow/bloc/booking_flow_cubit.dart';
import '../theme/theme.dart';
import 'di.dart';

class QuodesApp extends StatefulWidget {
  const QuodesApp({super.key, required this.deps});
  final AppDependencies deps;

  @override
  State<QuodesApp> createState() => _QuodesAppState();
}

class _QuodesAppState extends State<QuodesApp> {
  late final GoRouter _router = buildRouter(widget.deps.authBloc);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.deps;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: d.config),
        RepositoryProvider.value(value: d.authRepository),
        RepositoryProvider.value(value: d.catalogRepository),
        RepositoryProvider.value(value: d.bookingRepository),
        RepositoryProvider.value(value: d.supportRepository),
        RepositoryProvider.value(value: d.adminRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: d.authBloc),
          BlocProvider(create: (_) => BookingFlowCubit(d.bookingRepository)),
        ],
        child: MaterialApp.router(
          title: d.config.appName,
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          routerConfig: _router,
          builder: (context, child) => d.config.isProd
              ? child!
              : Banner(
                  message: d.config.flavor.name.toUpperCase(),
                  location: BannerLocation.topEnd,
                  color: d.config.flavor == Flavor.stage
                      ? const Color(0xFFF5A524)
                      : const Color(0xFF2F6BFF),
                  child: child!,
                ),
        ),
      ),
    );
  }
}
