import '../../../data/models/models.dart';
import 'booking_flow_cubit.dart';

extension BookingFlowRestore on BookingFlowCubit {
  /// Re-enter the flow at "pick a time" with the same game, station type and
  /// seats as [b] (e.g. after a released booking). No network needed: the
  /// booking already carries everything the slots step reads.
  void restoreFrom(Booking b) {
    final seats = [
      for (final s in b.seats)
        (
          seat: Seat.fromJson({'id': s.id, 'code': s.code, 'label': s.label}),
          station: s.station,
        ),
    ];
    restore(
      game: b.game,
      type: StationType.fromJson({
        'code': b.stationType,
        'name': b.stationTypeName,
        'hourly_rate': b.rate,
        'seats_per_station': seats.length > 1 ? 2 : 1,
      }),
      seats: seats,
    );
    if (b.date.isNotEmpty) selectDate(b.date, b.dateLabel);
  }
}
