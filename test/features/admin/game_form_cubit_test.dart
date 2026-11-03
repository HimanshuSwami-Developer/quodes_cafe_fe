import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quodes_gaming/core/bloc/load_status.dart';
import 'package:quodes_gaming/core/network/api_exception.dart';
import 'package:quodes_gaming/data/models/admin_models.dart';
import 'package:quodes_gaming/data/repositories/admin_repository.dart';
import 'package:quodes_gaming/features/admin/common/bloc/save_cubit.dart';
import 'package:quodes_gaming/features/admin/games/bloc/game_form_cubit.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late MockAdminRepository repo;
  setUpAll(() => registerFallbackValue(const AdminGame()));
  setUp(() => repo = MockAdminRepository());

  const draft = AdminGame(
    name: 'Valorant',
    mono: 'VAL',
    genre: 'SHOOTER',
    hue: 'red',
    platforms: ['PC'],
  );

  AdminGame? result;

  blocTest<GameFormCubit, SaveState<AdminGame>>(
    'server validation error lands in fieldErrors',
    build: () {
      when(() => repo.saveGame(any())).thenThrow(
        const ApiException(
          ApiErrorType.validation,
          'Use a colour like #2F6BFF.',
          statusCode: 400,
          data: {
            'hue': ['Use a colour like #2F6BFF.'],
          },
        ),
      );
      return GameFormCubit(repo);
    },
    act: (c) async => result = await c.save(draft),
    expect: () => [
      const SaveState<AdminGame>(status: LoadStatus.loading),
      isA<SaveState<AdminGame>>()
          .having((s) => s.status, 'status', LoadStatus.failure)
          .having((s) => s.fieldErrors, 'fieldErrors', {
            'hue': 'Use a colour like #2F6BFF.',
          })
          .having((s) => s.errorFor('hue'), 'hue', isNotNull)
          .having((s) => s.formMessage(['hue']), 'form message', isNull),
    ],
    verify: (_) {
      expect(result, isNull);
      verify(() => repo.saveGame(draft)).called(1);
    },
  );

  blocTest<GameFormCubit, SaveState<AdminGame>>(
    'success emits loading then the saved game',
    build: () {
      when(() => repo.saveGame(any())).thenAnswer(
        (_) async => AdminGame.fromJson({'id': 9, 'name': 'Valorant'}),
      );
      return GameFormCubit(repo);
    },
    act: (c) => c.save(draft),
    expect: () => [
      const SaveState<AdminGame>(status: LoadStatus.loading),
      isA<SaveState<AdminGame>>()
          .having((s) => s.status, 'status', LoadStatus.success)
          .having((s) => s.saved?.id, 'saved id', 9)
          .having((s) => s.fieldErrors, 'fieldErrors', isEmpty),
    ],
  );
}
