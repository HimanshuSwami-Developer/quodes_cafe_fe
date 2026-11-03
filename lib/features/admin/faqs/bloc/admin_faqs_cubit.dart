import '../../../../core/network/api_exception.dart';
import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../common/bloc/admin_list_cubit.dart';
import '../../common/bloc/save_cubit.dart';

/// FAQ list (admin): load, delete and reorder.
class AdminFaqsCubit extends AdminListCubit<AdminFaq> {
  /// Creates the cubit; call [load].
  AdminFaqsCubit(this._repo);
  final AdminRepository _repo;

  @override
  Future<List<AdminFaq>> fetch() => _repo.faqs();

  @override
  int idOf(AdminFaq item) => item.id;

  @override
  List<AdminFaq> sort(List<AdminFaq> items) => [...items]
    ..sort((a, b) {
      final s = a.sort.compareTo(b.sort);
      return s != 0 ? s : a.id.compareTo(b.id);
    });

  /// Deletes [f]; false (and an action error) on failure.
  Future<bool> delete(AdminFaq f) => act(f, () => _repo.deleteFaq(f.id));

  /// Moves [f] one place up ([delta] -1) or down (+1) by swapping its sort
  /// value with the neighbour. On failure the list is reloaded.
  Future<void> move(AdminFaq f, int delta) async {
    final items = state.items ?? const <AdminFaq>[];
    final i = items.indexWhere((e) => e.id == f.id);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= items.length) return;
    if (state.busyIds.contains(f.id)) return;
    final other = items[j];
    var a = other.sort, b = f.sort;
    if (a == b) {
      // Equal sorts: make the order explicit.
      a = delta < 0 ? f.sort : f.sort + 1;
      b = delta < 0 ? f.sort + 1 : f.sort;
    }
    emit(state.copyWith(busyIds: {...state.busyIds, f.id, other.id}));
    try {
      final saved = await Future.wait([
        _repo.saveFaq(_withSort(f, a)),
        _repo.saveFaq(_withSort(other, b)),
      ]);
      if (isClosed) return;
      final list = [...items];
      for (final s in saved) {
        final k = list.indexWhere((e) => e.id == s.id);
        if (k >= 0) list[k] = s;
      }
      emit(state.copyWith(items: sort(list), busyIds: const {}));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(actionError: e, seq: state.seq + 1, busyIds: const {}),
      );
      await load(silent: true);
    }
  }

  static AdminFaq _withSort(AdminFaq f, int sort) =>
      AdminFaq(id: f.id, question: f.question, answer: f.answer, sort: sort);
}

/// Add / edit form for one FAQ.
class FaqFormCubit extends SaveCubit<AdminFaq> {
  /// Creates the form cubit.
  FaqFormCubit(this._repo);
  final AdminRepository _repo;

  /// Validates and saves [f]; returns the saved FAQ or null.
  Future<AdminFaq?> save(AdminFaq f) async {
    final errors = <String, String>{
      if (f.question.trim().isEmpty) 'question': 'Enter the question.',
      if (f.answer.trim().isEmpty) 'answer': 'Enter the answer.',
    };
    if (errors.isNotEmpty) {
      invalid(errors);
      return null;
    }
    return run(() => _repo.saveFaq(f));
  }
}
