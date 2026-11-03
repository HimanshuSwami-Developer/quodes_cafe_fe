import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/theme.dart';
import '../../../../theme/widgets.dart';
import '../../common/bloc/admin_list_cubit.dart';
import '../../common/view/admin_ui.dart';
import '../bloc/admin_faqs_cubit.dart';

/// FAQs shown on the player Help tab: add, edit, delete, reorder.
class AdminFaqsPage extends StatelessWidget {
  /// Creates the page.
  const AdminFaqsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => AdminFaqsCubit(ctx.read<AdminRepository>())..load(),
    child: BlocListener<AdminFaqsCubit, AdminListState<AdminFaq>>(
      listenWhen: (a, b) => a.seq != b.seq,
      listener: (context, s) => showApiError(context, s.actionError),
      child: const _FaqsView(),
    ),
  );
}

class _FaqsView extends StatelessWidget {
  const _FaqsView();

  Future<void> _edit(BuildContext context, [AdminFaq? faq]) async {
    final cubit = context.read<AdminFaqsCubit>();
    final next = (cubit.state.items ?? const <AdminFaq>[]).fold<int>(
      0,
      (m, f) => f.sort >= m ? f.sort + 1 : m,
    );
    final saved = await showDialog<AdminFaq>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => FaqFormCubit(context.read<AdminRepository>()),
        child: _FaqDialog(faq: faq ?? AdminFaq(sort: next)),
      ),
    );
    if (saved == null || !context.mounted) return;
    cubit.upsert(saved);
    showToast(context, faq == null ? 'FAQ added' : 'FAQ saved');
  }

  Future<void> _delete(BuildContext context, AdminFaq f) async {
    final cubit = context.read<AdminFaqsCubit>();
    final ok = await confirmAction(
      context,
      title: 'Delete FAQ?',
      message: '"${f.question}" will no longer show on the Help tab.',
    );
    if (!ok) return;
    if (await cubit.delete(f) && context.mounted) {
      showToast(context, 'FAQ deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AdminFaqsCubit>().state;
    final cubit = context.read<AdminFaqsCubit>();
    return AdminPage(
      title: 'FAQs',
      subtitle: 'Shown to players on the Help tab, in this order.',
      actions: [
        AdminButton(
          label: 'Add FAQ',
          icon: Icons.add_rounded,
          onPressed: () => _edit(context),
        ),
      ],
      child: AdminAsync<AdminFaq>(
        status: s.status,
        items: s.items,
        error: s.error,
        onRetry: cubit.load,
        emptyIcon: Icons.quiz_outlined,
        emptyText: 'No FAQs yet. Add the first one.',
        builder: (items) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final f = items[i];
            final busy = s.busyIds.contains(f.id);
            return _FaqCard(
              faq: f,
              busy: busy,
              onUp: i == 0 || busy ? null : () => cubit.move(f, -1),
              onDown: i == items.length - 1 || busy
                  ? null
                  : () => cubit.move(f, 1),
              onEdit: () => _edit(context, f),
              onDelete: busy ? null : () => _delete(context, f),
            );
          },
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.faq,
    required this.busy,
    required this.onUp,
    required this.onDown,
    required this.onEdit,
    required this.onDelete,
  });
  final AdminFaq faq;
  final bool busy;
  final VoidCallback? onUp, onDown, onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, String tip, VoidCallback? f, [Color? c]) =>
        IconButton(
          tooltip: tip,
          visualDensity: VisualDensity.compact,
          onPressed: f,
          icon: Icon(icon, size: 20, color: f == null ? Q.border : c),
        );
    return Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Q.surfaceLo,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Q.border),
            ),
            child: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('${faq.sort}', style: label(12, color: Q.link)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onEdit,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(faq.question, style: body(15, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    faq.answer,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: body(13, color: Q.text3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            // Two rows of buttons on narrow screens.
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width < 600 ? 84 : 200,
            ),
            child: Wrap(
              children: [
                btn(Icons.arrow_upward_rounded, 'Move up', onUp, Q.text2),
                btn(Icons.arrow_downward_rounded, 'Move down', onDown, Q.text2),
                btn(Icons.edit_outlined, 'Edit', onEdit, Q.link),
                btn(Icons.delete_outline_rounded, 'Delete', onDelete, Q.red),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqDialog extends StatefulWidget {
  const _FaqDialog({required this.faq});
  final AdminFaq faq;

  @override
  State<_FaqDialog> createState() => _FaqDialogState();
}

class _FaqDialogState extends State<_FaqDialog> {
  late final _q = TextEditingController(text: widget.faq.question);
  late final _a = TextEditingController(text: widget.faq.answer);
  late final _sort = TextEditingController(text: '${widget.faq.sort}');

  static const _fields = ['question', 'answer', 'sort'];

  @override
  void dispose() {
    _q.dispose();
    _a.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await context.read<FaqFormCubit>().save(
      AdminFaq(
        id: widget.faq.id,
        question: _q.text.trim(),
        answer: _a.text.trim(),
        sort: int.tryParse(_sort.text) ?? 0,
      ),
    );
    if (saved != null && mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<FaqFormCubit>().state;
    return AdminFormDialog(
      title: widget.faq.isNew ? 'Add FAQ' : 'Edit FAQ',
      saving: s.status.isLoading,
      error: formError<AdminFaq>(s, _fields),
      onSave: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminField(
            label: 'Question',
            controller: _q,
            error: s.errorFor('question'),
            autofocus: true,
          ),
          const SizedBox(height: 14),
          AdminField(
            label: 'Answer',
            controller: _a,
            error: s.errorFor('answer'),
            maxLines: 6,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 160,
            child: AdminField(
              label: 'Sort',
              controller: _sort,
              error: s.errorFor('sort'),
              digitsOnly: true,
            ),
          ),
        ],
      ),
    );
  }
}
