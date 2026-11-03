import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:mocktail/mocktail.dart';
import 'package:quodes_gaming/core/network/api_exception.dart';
import 'package:quodes_gaming/data/repositories/booking_repository.dart';
import 'package:quodes_gaming/features/booking/bloc/booking_cubit.dart';

import '../../helpers/fixtures.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

void main() {
  late MockBookingRepository repo;

  setUpAll(() => registerFallbackValue(XFile('x.png')));

  setUp(() {
    repo = MockBookingRepository();
    when(() => repo.byId(42)).thenAnswer((_) async => booking());
  });

  test('loads the booking when opened without one', () async {
    final c = BookingCubit(repo, bookingId: 42);
    expect(c.state.loading, isTrue);
    await pumpEventQueue();
    expect(c.state.booking?.status, 'locked');
    expect(c.state.loading, isFalse);
    await c.close();
  });

  test('cancel success swaps in the updated booking', () async {
    when(
      () => repo.cancel(42),
    ).thenAnswer((_) async => booking(status: 'cancelled'));
    final c = BookingCubit(repo, bookingId: 42, initial: booking());
    final states = <BookingState>[];
    final sub = c.stream.listen(states.add);

    expect(await c.cancel(), isTrue);
    expect(c.state.booking?.status, 'cancelled');
    expect(c.state.action, BookingAction.none);
    expect(c.state.error, isNull);
    expect(states.any((s) => s.action == BookingAction.cancelling), isTrue);
    await sub.cancel();
    await c.close();
  });

  test('upload error is surfaced once and the booking is kept', () async {
    const err = ApiException(
      ApiErrorType.validation,
      'Slot lock expired. Book again.',
      statusCode: 400,
    );
    when(
      () => repo.uploadProof(
        42,
        screenshot: any(named: 'screenshot'),
        utr: any(named: 'utr'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenThrow(err);
    final c = BookingCubit(repo, bookingId: 42, initial: booking());
    await pumpEventQueue(); // let the constructor's silent refresh land
    final states = <BookingState>[];
    final sub = c.stream.listen(states.add);

    expect(
      await c.uploadProof(XFile('shot.png'), utr: '123456789012'),
      isFalse,
    );
    await pumpEventQueue();

    // One-shot: emitted exactly once, together with the idle action.
    final withError = states.where((s) => s.error != null).toList();
    expect(withError, hasLength(1));
    expect(withError.single.error, err);
    expect(withError.single.action, BookingAction.none);
    expect(c.state.booking?.status, 'locked');
    await sub.cancel();
    await c.close();
  });

  test('rebook returns the new booking', () async {
    when(
      () => repo.rebookWithCredit(42),
    ).thenAnswer((_) async => booking(id: 43, status: 'confirmed'));
    final c = BookingCubit(
      repo,
      bookingId: 42,
      initial: booking(status: 'released'),
    );
    final nb = await c.rebookWithCredit();
    expect(nb?.id, 43);
    expect(c.state.action, BookingAction.none);
    await c.close();
  });
}
