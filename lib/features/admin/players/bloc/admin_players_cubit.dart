import 'dart:async';

import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../common/bloc/admin_list_cubit.dart';
import '../../common/bloc/save_cubit.dart';

/// Player list with debounced search and a staff-only filter.
class AdminPlayersCubit extends AdminListCubit<AdminUser> {
  /// [debounce] delays search requests while typing.
  AdminPlayersCubit(
    this._repo, {
    this.debounce = const Duration(milliseconds: 300),
  });

  final AdminRepository _repo;
  final Duration debounce;
  Timer? _debounce;

  /// Current search text.
  String query = '';

  /// Only show staff accounts.
  bool staffOnly = false;

  @override
  Future<List<AdminUser>> fetch() =>
      _repo.users(query: query, staffOnly: staffOnly);

  @override
  int idOf(AdminUser item) => item.id;

  /// Debounced search by email, gamertag, phone or name.
  void search(String q) {
    final t = q.trim();
    if (t == query) return;
    query = t;
    _debounce?.cancel();
    _debounce = Timer(debounce, load);
  }

  /// Toggles the staff-only filter and reloads.
  void setStaffOnly(bool v) {
    if (v == staffOnly) return;
    staffOnly = v;
    load(); // emits loading, so the chip redraws right away
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

/// Saves the editable fields of one user.
class AdminUserFormCubit extends SaveCubit<AdminUser> {
  /// Creates the form cubit.
  AdminUserFormCubit(this._repo);
  final AdminRepository _repo;

  /// PATCHes credit / active / verified / staff for user [id].
  Future<AdminUser?> save(
    int id, {
    required String credit,
    required bool isActive,
    required bool emailVerified,
    required bool isStaff,
  }) {
    final c = double.tryParse(credit.trim());
    if (c == null || c < 0) {
      invalid({'credit': 'Enter an amount like 150 or 99.50.'});
      return Future.value();
    }
    return run(
      () => _repo.updateUser(
        id,
        credit: c,
        isActive: isActive,
        emailVerified: emailVerified,
        isStaff: isStaff,
      ),
    );
  }
}
