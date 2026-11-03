import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../common/bloc/admin_list_cubit.dart';
import '../../common/bloc/save_cubit.dart';

/// Policy list (admin): load and delete; edits come back via [upsert].
class AdminPoliciesCubit extends AdminListCubit<AdminPolicy> {
  /// Creates the cubit; call [load].
  AdminPoliciesCubit(this._repo);
  final AdminRepository _repo;

  @override
  Future<List<AdminPolicy>> fetch() => _repo.policies();

  @override
  int idOf(AdminPolicy item) => item.id;

  @override
  List<AdminPolicy> sort(List<AdminPolicy> items) => [...items]
    ..sort((a, b) {
      final s = a.sort.compareTo(b.sort);
      return s != 0 ? s : a.id.compareTo(b.id);
    });

  /// Deletes [p]; false (and an action error) on failure.
  Future<bool> delete(AdminPolicy p) => act(p, () => _repo.deletePolicy(p.id));
}

/// Editor for one policy and its ordered sections.
class PolicyFormCubit extends SaveCubit<AdminPolicy> {
  /// Creates the form cubit.
  PolicyFormCubit(this._repo);
  final AdminRepository _repo;

  static final _slug = RegExp(r'^[-a-zA-Z0-9_]+$');

  /// Validates and saves [p] (sections replace the server's); returns the
  /// saved policy or null.
  Future<AdminPolicy?> save(AdminPolicy p) async {
    final errors = <String, String>{
      if (p.title.trim().isEmpty) 'title': 'Enter a title.',
      if (p.key.trim().isEmpty)
        'key': 'Enter a key, e.g. house-rules.'
      else if (!_slug.hasMatch(p.key.trim()))
        'key': 'Use letters, numbers, - and _ only.',
      if (p.sections.any((s) => s.heading.trim().isEmpty))
        'sections': 'Every section needs a heading.'
      else if (p.sections.any((s) => s.body.trim().isEmpty))
        'sections': 'Every section needs a body.',
    };
    if (errors.isNotEmpty) {
      invalid(errors);
      return null;
    }
    return run(() => _repo.savePolicy(p));
  }
}
