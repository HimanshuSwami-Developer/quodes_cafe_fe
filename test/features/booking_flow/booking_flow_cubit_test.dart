import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quodes_gaming/core/network/api_exception.dart';
import 'package:quodes_gaming/data/models/models.dart';
import 'package:quodes_gaming/data/repositories/booking_repository.dart';
import 'package:quodes_gaming/features/booking_flow/bloc/booking_flow_cubit.dart';

import '../../helpers/fixtures.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

void main() {
  late MockBookingRepository repo;
  setUp(() => repo = MockBookingRepository());

  BookingFlowCubit ready() => BookingFlowCubit(repo)
    ..start(game())
    ..selectType(stationType('PS5'));

  test('seat cap: a 5th seat is refused', () {
    final c = ready();
    for (var i = 1; i <= 4; i++) {
      expect(c.toggleSeat(seat(i), 'S5-0$i'), isTrue);
    }
    expect(c.toggleSeat(seat(5), 'S5-05'), isFalse);
    expect(c.state.players, 4);
    // Toggling an already-selected seat removes it.
    expect(c.toggleSeat(seat(2), 'S5-02'), isTrue);
    expect(c.state.seatIds, [1, 3, 4]);
  });

  test('seat cap follows a smaller game limit', () {
    final c = BookingFlowCubit(repo)..start(game(maxPlayers: 1));
    expect(c.toggleSeat(seat(1), 'PC-01'), isTrue);
    expect(c.toggleSeat(seat(2), 'PC-02'), isFalse);
  });

  test('changing station type clears the seats', () {
    final c = ready()..toggleSeat(seat(1), 'S5-01');
    c.selectType(stationType('PS5')); // same type: kept
    expect(c.state.players, 1);
    c.selectType(stationType('PC', seats: 1));
    expect(c.state.seats, isEmpty);
    expect(c.state.type?.code, 'PC');
  });

  group('lock', () {
    BookingFlowCubit lockable() => ready()
      ..toggleSeat(seat(1), 'S5-01')
      ..selectDate('2026-10-31', 'Sat, 31 Oct')
      ..selectDuration(2)
      ..selectStart(16);

    When<Future<Booking>> stubCreate() => when(
      () => repo.create(
        gameId: any(named: 'gameId'),
        seatIds: any(named: 'seatIds'),
        date: any(named: 'date'),
        startHour: any(named: 'startHour'),
        durationHours: any(named: 'durationHours'),
      ),
    );

    blocTest<BookingFlowCubit, BookingFlowState>(
      'success returns the locked booking',
      build: () {
        stubCreate().thenAnswer((_) async => booking());
        return lockable();
      },
      act: (c) async {
        expect((await c.lock())?.id, 42);
      },
      expect: () => [
        isA<BookingFlowState>().having((s) => s.locking, 'locking', true),
        isA<BookingFlowState>()
            .having((s) => s.locking, 'locking', false)
            .having((s) => s.error, 'error', isNull),
      ],
      verify: (_) => verify(
        () => repo.create(
          gameId: 1,
          seatIds: [1],
          date: '2026-10-31',
          startHour: 16,
          durationHours: 2,
        ),
      ).called(1),
    );

    const taken = ApiException(
      ApiErrorType.conflict,
      'S5-01-1 is already taken at 4 PM.',
      statusCode: 409,
    );

    blocTest<BookingFlowCubit, BookingFlowState>(
      'conflict returns null and keeps the error',
      build: () {
        stubCreate().thenThrow(taken);
        return lockable();
      },
      act: (c) async {
        expect(await c.lock(), isNull);
      },
      expect: () => [
        isA<BookingFlowState>().having((s) => s.locking, 'locking', true),
        isA<BookingFlowState>()
            .having((s) => s.locking, 'locking', false)
            .having((s) => s.error, 'error', taken),
      ],
    );

    test('nothing to lock without a start time', () async {
      final c = ready()..toggleSeat(seat(1), 'S5-01');
      expect(await c.lock(), isNull);
      verifyZeroInteractions(repo);
    });
  });
}
