import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/theme.dart';
import '../../../../theme/widgets.dart';
import '../../common/bloc/admin_list_cubit.dart';
import '../../common/view/admin_ui.dart';
import '../bloc/admin_policies_cubit.dart';

/// Policy pages (house rules, refunds, privacy) and their sections.
class AdminPoliciesPage extends StatelessWidget {
  /// Creates the page.
  const AdminPoliciesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => AdminPoliciesCubit(ctx.read<AdminRepository>())..load(),
    child: BlocListener<AdminPoliciesCubit, AdminListState<AdminPolicy>>(
      listenWhen: (a, b) => a.seq != b.seq,
      listener: (context, s) => showApiError(context, s.actionError),
      child: const _PoliciesView(),
    ),
  );
}

class _PoliciesView extends StatelessWidget {
  const _PoliciesView();

  Future<void> _edit(BuildContext context, [AdminPolicy? p]) async {
    final cubit = context.read<AdminPoliciesCubit>();
    final next = (cubit.state.items ?? const <AdminPolicy>[]).fold<int>(
      0,
      (m, e) => e.sort >= m ? e.sort + 1 : m,
    );
    final saved = await showDialog<AdminPolicy>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => PolicyFormCubit(context.read<AdminRepository>()),
        child: _PolicyDialog(
          policy:
              p ??
              AdminPolicy(sort: next, sections: const [AdminPolicySection()]),
        ),
      ),
    );
    if (saved == null || !context.mounted) return;
    cubit.upsert(saved);
    showToast(context, p == null ? 'Policy added' : 'Policy saved');
  }

  Future<void> _delete(BuildContext context, AdminPolicy p) async {
    final cubit = context.read<AdminPoliciesCubit>();
    final ok = await confirmAction(
      context,
      title: 'Delete policy?',
      message:
          '"${p.title}" and its ${p.sections.length} sections will be '
          'removed for players.',
    );
    if (!ok) return;
    if (await cubit.delete(p) && context.mounted) {
      showToast(context, 'Policy deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AdminPoliciesCubit>().state;
    return AdminPage(
      title: 'Policies',
      subtitle: 'House rules, refunds and privacy, as players read them.',
      actions: [
        AdminButton(
          label: 'Add policy',
          icon: Icons.add_rounded,
          onPressed: () => _edit(context),
        ),
      ],
      child: AdminAsync<AdminPolicy>(
        status: s.status,
        items: s.items,
        error: s.error,
        onRetry: context.read<AdminPoliciesCubit>().load,
        emptyIcon: Icons.gavel_outlined,
        emptyText: 'No policies yet.',
        builder: (items) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final p = items[i];
            final busy = s.busyIds.contains(p.id);
            return Panel(
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                onTap: () => _edit(context, p),
                leading: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Q.surfaceLo,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Q.border),
                  ),
                  child: Text('${p.sort}', style: label(12, color: Q.link)),
                ),
                title: Text(p.title, style: body(15, weight: FontWeight.w800)),
                subtitle: Text(
                  '${p.key} · ${p.sections.length} '
                  'section${p.sections.length == 1 ? '' : 's'}'
                  '${p.updated.isEmpty ? '' : ' · updated ${p.updated}'}',
                  style: body(13, color: Q.text3),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _edit(context, p),
                      icon: const Icon(Icons.edit_outlined, color: Q.link),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: busy ? null : () => _delete(context, p),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Q.red,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Controllers for one section row, with a stable id for reordering.
class _SectionDraft {
  _SectionDraft(this.id, AdminPolicySection s)
    : heading = TextEditingController(text: s.heading),
      body = TextEditingController(text: s.body);
  final int id;
  final TextEditingController heading, body;

  void dispose() {
    heading.dispose();
    body.dispose();
  }
}

class _PolicyDialog extends StatefulWidget {
  const _PolicyDialog({required this.policy});
  final AdminPolicy policy;

  @override
  State<_PolicyDialog> createState() => _PolicyDialogState();
}

class _PolicyDialogState extends State<_PolicyDialog> {
  late final _title = TextEditingController(text: widget.policy.title);
  late final _key = TextEditingController(text: widget.policy.key);
  late final _sort = TextEditingController(text: '${widget.policy.sort}');
  int _nextId = 0;
  late final List<_SectionDraft> _sections = [
    for (final s in widget.policy.sections) _SectionDraft(_nextId++, s),
  ];

  /// Errors shown next to a field; anything else goes to the banner.
  static const _fields = ['title', 'key', 'sort'];

  @override
  void dispose() {
    _title.dispose();
    _key.dispose();
    _sort.dispose();
    for (final s in _sections) {
      s.dispose();
    }
    super.dispose();
  }

  /// DRF reports nested errors as a list with one map per section
  /// (`[{}, {"body": ["This field may not be blank."]}]`).
  static String? _sectionsError(Object? raw) {
    if (raw is! List) return null;
    for (var i = 0; i < raw.length; i++) {
      final e = raw[i];
      if (e is Map && e.isNotEmpty) {
        final first = e.entries.first;
        final msg = first.value is List && (first.value as List).isNotEmpty
            ? (first.value as List).first
            : first.value;
        return 'Section ${i + 1} ${first.key}: $msg';
      }
      if (e is String) return 'Sections: $e';
    }
    return null;
  }

  void _add() => setState(
    () => _sections.add(_SectionDraft(_nextId++, const AdminPolicySection())),
  );

  void _remove(_SectionDraft d) {
    setState(() => _sections.remove(d));
    // Dispose after the row has left the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) => d.dispose());
  }

  void _reorder(int from, int to) => setState(() {
    _sections.insert(to, _sections.removeAt(from));
  });

  Future<void> _save() async {
    final saved = await context.read<PolicyFormCubit>().save(
      AdminPolicy(
        id: widget.policy.id,
        title: _title.text.trim(),
        key: _key.text.trim(),
        sort: int.tryParse(_sort.text) ?? 0,
        sections: [
          for (var i = 0; i < _sections.length; i++)
            AdminPolicySection(
              heading: _sections[i].heading.text.trim(),
              body: _sections[i].body.text.trim(),
              sort: i,
            ),
        ],
      ),
    );
    if (saved != null && mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PolicyFormCubit>().state;
    final narrow = MediaQuery.sizeOf(context).width < 640;
    final title = AdminField(
      label: 'Title',
      controller: _title,
      error: s.errorFor('title'),
      autofocus: widget.policy.isNew,
    );
    final key = AdminField(
      label: 'Key',
      controller: _key,
      error: s.errorFor('key'),
      hint: 'house-rules',
      mono: true,
    );
    final sort = AdminField(
      label: 'Sort',
      controller: _sort,
      error: s.errorFor('sort'),
      digitsOnly: true,
    );
    return AdminFormDialog(
      title: widget.policy.isNew ? 'Add policy' : 'Edit ${widget.policy.title}',
      width: 820,
      saving: s.status.isLoading,
      error: _sectionsError(s.error?.data['sections']) ?? formError(s, _fields),
      onSave: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (narrow) ...[
            title,
            const SizedBox(height: 12),
            key,
            const SizedBox(height: 12),
            SizedBox(width: 140, child: sort),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: title),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: key),
                const SizedBox(width: 12),
                SizedBox(width: 100, child: sort),
              ],
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sections (${_sections.length})',
                  style: display(16, weight: FontWeight.w600),
                ),
              ),
              Text('Drag to reorder', style: body(12, color: Q.text3)),
            ],
          ),
          const SizedBox(height: 10),
          if (_sections.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No sections. Add one below.',
                style: body(13, color: Q.text3),
              ),
            ),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: _reorder,
            children: [
              for (var i = 0; i < _sections.length; i++)
                _SectionRow(
                  key: ValueKey(_sections[i].id),
                  index: i,
                  draft: _sections[i],
                  onRemove: () => _remove(_sections[i]),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: AdminOutlineButton(
              label: 'Add section',
              icon: Icons.add_rounded,
              onPressed: _add,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    super.key,
    required this.index,
    required this.draft,
    required this.onRemove,
  });
  final int index;
  final _SectionDraft draft;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Panel(
      color: Q.surfaceLo,
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Padding(
                padding: EdgeInsets.fromLTRB(4, 26, 6, 8),
                child: Icon(Icons.drag_indicator_rounded, color: Q.text3),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminField(
                  label: 'Heading ${index + 1}',
                  controller: draft.heading,
                ),
                const SizedBox(height: 10),
                AdminField(label: 'Body', controller: draft.body, maxLines: 6),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove section',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded, color: Q.red),
          ),
        ],
      ),
    ),
  );
}
