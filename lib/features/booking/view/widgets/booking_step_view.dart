import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../data/models/models.dart';
import '../../../../theme/widgets.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../bloc/booking_cubit.dart';

/// Statuses after which the player's credit / stats may have changed.
const _userChanging = {'confirmed', 'released', 'cancelled', 'expired'};

/// Shared shell for every booking-status page:
/// * shows a loader / retry until the booking is known,
/// * routes away when the status no longer belongs on [step]
///   (unless it is listed in [stayOn], e.g. Verifying plays out its result),
/// * surfaces one-shot errors as a SnackBar,
/// * refreshes the signed-in user when credit may have changed.
class BookingStepView extends StatefulWidget {
  const BookingStepView({
    super.key,
    required this.step,
    required this.builder,
    this.stayOn = const {},
  });

  final BookingStep step;
  final Set<String> stayOn;
  final Widget Function(BuildContext context, Booking booking, BookingState s)
  builder;

  @override
  State<BookingStepView> createState() => _BookingStepViewState();
}

class _BookingStepViewState extends State<BookingStepView> {
  bool _left = false;

  @override
  void initState() {
    super.initState();
    // Deep links / stale `extra`: the first known status may not fit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = context.read<BookingCubit>().state.booking;
      if (b != null) _route(b);
    });
  }

  void _route(Booking b) {
    if (_left || !mounted) return;
    if (b.allows(widget.step) || widget.stayOn.contains(b.status)) return;
    _left = true;
    context.goBooking(b);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingCubit, BookingState>(
      listenWhen: (a, b) =>
          a.booking?.status != b.booking?.status ||
          (b.error != null && a.error != b.error),
      listener: (context, s) {
        if (s.error != null) showToast(context, s.error!.message);
        final b = s.booking;
        if (b == null) return;
        if (_userChanging.contains(b.status)) {
          context.read<AuthBloc>().add(const AuthUserRefreshRequested());
        }
        _route(b);
      },
      buildWhen: (a, b) => a != b,
      builder: (context, s) {
        final b = s.booking;
        if (b == null) {
          return QBackground(
            child: s.loading || s.error == null
                ? const LoadingView()
                : ErrorView(
                    error: s.error!,
                    onRetry: context.read<BookingCubit>().refresh,
                  ),
          );
        }
        return widget.builder(context, b, s);
      },
    );
  }
}
