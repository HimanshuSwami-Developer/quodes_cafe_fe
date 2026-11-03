import 'package:image_picker/image_picker.dart' show XFile;

import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../common/bloc/save_cubit.dart';

/// Add/edit game dialog. Server validation errors land in
/// `state.fieldErrors` (e.g. `hue: Use a colour like #2F6BFF.`,
/// `cover: Upload a PNG, JPG or WebP image.`).
class GameFormCubit extends SaveCubit<AdminGame> {
  /// Creates the form cubit.
  GameFormCubit(this._repo);

  final AdminRepository _repo;

  /// Id of a game this dialog already created. If the cover upload then
  /// fails, pressing Save again updates that game instead of adding a copy.
  int? _createdId;

  /// Creates or updates [draft], then uploads [cover] or, with
  /// [removeCover], removes the current one. Returns the saved game, or
  /// null on error.
  Future<AdminGame?> save(
    AdminGame draft, {
    XFile? cover,
    bool removeCover = false,
  }) {
    if (draft.name.trim().isEmpty) {
      invalid(const {'name': 'Enter the game name.'});
      return Future.value();
    }
    return run(() async {
      final id = _createdId;
      var game = await _repo.saveGame(
        draft.isNew && id != null ? draft.withId(id) : draft,
      );
      if (draft.isNew) _createdId = game.id;
      if (cover != null) {
        game = await _repo.uploadGameCover(game.id, cover);
      } else if (removeCover && game.coverUrl != null) {
        game = await _repo.removeGameCover(game.id);
      }
      return game;
    });
  }
}
