import 'package:bloc_test/bloc_test.dart';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' show XFile;
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
  setUpAll(() {
    registerFallbackValue(const AdminGame());
    registerFallbackValue(XFile.fromData(Uint8List(0)));
  });
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

  test('uploads the picked cover after saving', () async {
    final file = XFile.fromData(Uint8List(4), name: 'c.png');
    when(() => repo.saveGame(any())).thenAnswer(
      (_) async => AdminGame.fromJson({'id': 9, 'name': 'Valorant'}),
    );
    when(() => repo.uploadGameCover(9, file)).thenAnswer(
      (_) async =>
          AdminGame.fromJson({'id': 9, 'name': 'Valorant', 'cover_url': 'u'}),
    );
    final saved = await GameFormCubit(repo).save(draft, cover: file);
    expect(saved?.coverUrl, 'u');
  });

  test(
    'a failed cover upload then Save again updates, not duplicates',
    () async {
      final file = XFile.fromData(Uint8List(4), name: 'c.png');
      final saves = <AdminGame>[];
      when(() => repo.saveGame(any())).thenAnswer((i) async {
        saves.add(i.positionalArguments.first as AdminGame);
        return AdminGame.fromJson({'id': 9, 'name': 'Valorant'});
      });
      var fail = true;
      when(() => repo.uploadGameCover(9, file)).thenAnswer((_) async {
        if (fail) {
          throw const ApiException(
            ApiErrorType.validation,
            'Upload a PNG, JPG or WebP image.',
            statusCode: 400,
            data: {
              'cover': ['Upload a PNG, JPG or WebP image.'],
            },
          );
        }
        return AdminGame.fromJson({
          'id': 9,
          'name': 'Valorant',
          'cover_url': 'u',
        });
      });
      final cubit = GameFormCubit(repo);

      expect(await cubit.save(draft, cover: file), isNull);
      expect(cubit.state.errorFor('cover'), isNotNull);

      fail = false;
      expect((await cubit.save(draft, cover: file))?.coverUrl, 'u');
      expect(saves.map((g) => g.id), [0, 9]);
    },
  );

  test('removeCover only calls the API when there is a cover', () async {
    when(() => repo.saveGame(any())).thenAnswer(
      (_) async =>
          AdminGame.fromJson({'id': 9, 'name': 'Valorant', 'cover_url': 'u'}),
    );
    when(() => repo.removeGameCover(9)).thenAnswer(
      (_) async => AdminGame.fromJson({'id': 9, 'name': 'Valorant'}),
    );
    final saved = await GameFormCubit(
      repo,
    ).save(draft.withId(9), removeCover: true);
    expect(saved?.coverUrl, isNull);
    verify(() => repo.removeGameCover(9)).called(1);
  });
}
