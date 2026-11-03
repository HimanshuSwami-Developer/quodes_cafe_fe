import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../common/bloc/save_cubit.dart';

/// Add/edit game dialog. Server validation errors land in
/// `state.fieldErrors` (e.g. `hue: Use a colour like #2F6BFF.`).
class GameFormCubit extends SaveCubit<AdminGame> {
  /// Creates the form cubit.
  GameFormCubit(this._repo);

  final AdminRepository _repo;

  /// Creates or updates [draft]; returns the saved game, or null on error.
  Future<AdminGame?> save(AdminGame draft) {
    if (draft.name.trim().isEmpty) {
      invalid(const {'name': 'Enter the game name.'});
      return Future.value();
    }
    return run(() => _repo.saveGame(draft));
  }
}
