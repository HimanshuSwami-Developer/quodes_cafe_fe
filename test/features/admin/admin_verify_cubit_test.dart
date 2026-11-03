import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quodes_gaming/core/bloc/load_status.dart';
import 'package:quodes_gaming/core/network/api_exception.dart';
import 'package:quodes_gaming/data/repositories/admin_repository.dart';
import 'package:quodes_gaming/features/admin/verify/bloc/admin_verify_cubit.dart';

import '../../helpers/admin_fixtures.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late MockAdminRepository repo;
  final a = staffBooking(id: 1);
  final b = staffBooking(id: 2);
  final c = staffBooking(id: 3);
  final queue = AdminVerifyState(status: LoadStatus.success, items: [a, b, c]);

  setUp(() => repo = MockAdminRepository());

  List<int>? ids(AdminVerifyState s) => s.items?.map((e) => e.id).toList();

  blocTest<AdminVerifyCubit, AdminVerifyState>(
    'load emits loading then the queue',
    build: () {
      when(() => repo.verifyQueue()).thenAnswer((_) async => [a, b]);
      return AdminVerifyCubit(repo);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const AdminVerifyState(status: LoadStatus.loading),
      isA<AdminVerifyState>()
          .having((s) => s.status, 'status', LoadStatus.success)
          .having(ids, 'ids', [1, 2]),
    ],
  );

  blocTest<AdminVerifyCubit, AdminVerifyState>(
    'approve success removes the item at once and reports it',
    build: () {
      when(
        () => repo.approve(2),
      ).thenAnswer((_) async => staffBooking(id: 2, status: 'confirmed'));
      return AdminVerifyCubit(repo);
    },
    seed: () => queue,
    act: (cubit) => cubit.approve(b),
    expect: () => [
      // Optimistic: gone before the server answers.
      isA<AdminVerifyState>().having(ids, 'ids', [1, 3]).having(
        (s) => s.busyIds,
        'busy',
        {2},
      ),
      isA<AdminVerifyState>()
          .having(ids, 'ids', [1, 3])
          .having((s) => s.busyIds, 'busy', isEmpty)
          .having((s) => s.done, 'done', 'QG-2 approved')
          .having((s) => s.actionError, 'error', isNull),
    ],
    verify: (_) => verify(() => repo.approve(2)).called(1),
  );

  const conflict = ApiException(
    ApiErrorType.validation,
    "Can't approve a booking that is payment rejected.",
    statusCode: 400,
  );

  blocTest<AdminVerifyCubit, AdminVerifyState>(
    'approve failure restores the item in place and emits the error',
    build: () {
      when(() => repo.approve(2)).thenThrow(conflict);
      return AdminVerifyCubit(repo);
    },
    seed: () => queue,
    act: (cubit) => cubit.approve(b),
    expect: () => [
      isA<AdminVerifyState>().having(ids, 'ids', [1, 3]),
      isA<AdminVerifyState>()
          .having(ids, 'ids', [1, 2, 3])
          .having((s) => s.busyIds, 'busy', isEmpty)
          .having((s) => s.actionError, 'error', conflict)
          .having((s) => s.done, 'done', isNull),
    ],
  );

  blocTest<AdminVerifyCubit, AdminVerifyState>(
    'reject sends the note and drops the item on success',
    build: () {
      when(
        () => repo.reject(1, note: any(named: 'note')),
      ).thenAnswer((_) async => staffBooking(id: 1, status: 'rejected'));
      return AdminVerifyCubit(repo);
    },
    seed: () => queue,
    act: (cubit) => cubit.reject(a, note: 'No such UTR'),
    expect: () => [
      isA<AdminVerifyState>().having(ids, 'ids', [1, 2, 3]).having(
        (s) => s.busyIds,
        'busy',
        {1},
      ),
      isA<AdminVerifyState>()
          .having(ids, 'ids', [2, 3])
          .having((s) => s.done, 'done', 'QG-1 rejected'),
    ],
    verify: (_) => verify(() => repo.reject(1, note: 'No such UTR')).called(1),
  );
}
