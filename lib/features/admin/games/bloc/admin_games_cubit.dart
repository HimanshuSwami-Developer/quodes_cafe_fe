import '../../../../core/network/api_exception.dart';
import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../common/bloc/admin_list_cubit.dart';

/// Games page: the catalogue (by sort, then name) plus the platform codes
/// the add/edit form offers.
class AdminGamesCubit extends AdminListCubit<AdminGame> {
  /// Creates the cubit; call `load()`.
  AdminGamesCubit(this._repo);

  final AdminRepository _repo;

  /// Station type codes shown as platform checkboxes.
  static const fallbackPlatforms = ['PS5', 'PS4', 'PC'];

  List<String> _platforms = fallbackPlatforms;

  /// Platform codes from the station types (fallback when unavailable).
  List<String> get platforms => _platforms;

  @override
  Future<List<AdminGame>> fetch() async {
    final games = _repo.games();
    try {
      final types = await _repo.stationTypes();
      if (types.isNotEmpty) _platforms = [for (final t in types) t.code];
    } on ApiException {
      // Keep the fallback codes; the games list still loads.
    }
    return games;
  }

  @override
  int idOf(AdminGame item) => item.id;

  @override
  List<AdminGame> sort(List<AdminGame> items) => [...items]
    ..sort((a, b) {
      final s = a.sort.compareTo(b.sort);
      return s != 0 ? s : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  /// Deletes [g]; false (with `actionError`) on failure.
  Future<bool> delete(AdminGame g) => act(g, () => _repo.deleteGame(g.id));
}
