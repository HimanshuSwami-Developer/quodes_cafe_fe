import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/admin_models.dart';
import '../../../../data/models/models.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/theme.dart';
import '../../../../theme/widgets.dart';
import '../../common/bloc/admin_list_cubit.dart';
import '../../common/view/admin_ui.dart';
import '../bloc/admin_players_cubit.dart';

/// Player accounts: search, credit, verified / active / staff flags.
class AdminPlayersPage extends StatelessWidget {
  /// Creates the page.
  const AdminPlayersPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => AdminPlayersCubit(ctx.read<AdminRepository>())..load(),
    child: BlocListener<AdminPlayersCubit, AdminListState<AdminUser>>(
      listenWhen: (a, b) => a.seq != b.seq,
      listener: (context, s) => showApiError(context, s.actionError),
      child: const _PlayersView(),
    ),
  );
}

class _PlayersView extends StatefulWidget {
  const _PlayersView();
  @override
  State<_PlayersView> createState() => _PlayersViewState();
}

class _PlayersViewState extends State<_PlayersView> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _edit(AdminUser u) async {
    final cubit = context.read<AdminPlayersCubit>();
    final repo = context.read<AdminRepository>();
    final saved = await showDialog<AdminUser>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => AdminUserFormCubit(repo),
        child: _UserDialog(user: u),
      ),
    );
    if (saved != null && mounted) {
      cubit.upsert(saved);
      showToast(context, 'Saved ${saved.email}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminPlayersCubit>();
    final s = context.watch<AdminPlayersCubit>().state;
    return AdminPage(
      title: 'Players',
      subtitle: 'Newest first · up to 200 results',
      actions: [
        AdminOutlineButton(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: cubit.load,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _q,
                  onChanged: cubit.search,
                  style: body(14),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Search email, gamertag, phone, name',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                  ),
                ),
              ),
              QChip(
                label: 'Staff only',
                height: 36,
                glow: false,
                selected: cubit.staffOnly,
                onTap: () => cubit.setStaffOnly(!cubit.staffOnly),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: AdminAsync<AdminUser>(
              status: s.status,
              items: s.items,
              error: s.error,
              onRetry: cubit.load,
              emptyIcon: Icons.person_search_outlined,
              emptyText: 'No accounts match.',
              builder: (items) => SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: _table(items),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flag(bool on) => Icon(
    on ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
    size: 18,
    color: on ? Q.green : Q.text3,
    semanticLabel: on ? 'yes' : 'no',
  );

  Widget _table(List<AdminUser> items) => AdminTable(
    columns: const [
      DataColumn(label: Text('PLAYER')),
      DataColumn(label: Text('EMAIL')),
      DataColumn(label: Text('PHONE')),
      DataColumn(label: Text('CREDIT'), numeric: true),
      DataColumn(label: Text('VERIFIED')),
      DataColumn(label: Text('ACTIVE')),
      DataColumn(label: Text('STAFF')),
      DataColumn(label: Text('BOOKINGS'), numeric: true),
      DataColumn(label: Text('JOINED')),
      DataColumn(label: Text('')),
    ],
    rows: [
      for (final u in items)
        adminRow(
          key: ValueKey(u.id),
          onTap: () => _edit(u),
          cells: [
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.gamertag.isEmpty ? '—' : u.gamertag,
                    style: body(14, weight: FontWeight.w700),
                  ),
                  if (u.fullName.isNotEmpty)
                    Text(u.fullName, style: body(12, color: Q.text3)),
                ],
              ),
            ),
            DataCell(Text(u.email)),
            DataCell(Text(u.phone.isEmpty ? '—' : u.phone)),
            DataCell(Text(inr(u.credit))),
            DataCell(_flag(u.emailVerified)),
            DataCell(_flag(u.isActive)),
            DataCell(_flag(u.isStaff)),
            DataCell(Text('${u.bookings}')),
            DataCell(Text(adminDate(u.dateJoined))),
            DataCell(
              IconButton(
                tooltip: 'Edit ${u.email}',
                onPressed: () => _edit(u),
                icon: const Icon(Icons.edit_outlined, size: 18, color: Q.link),
              ),
            ),
          ],
        ),
    ],
  );
}

class _UserDialog extends StatefulWidget {
  const _UserDialog({required this.user});
  final AdminUser user;
  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  late final _credit = TextEditingController(text: rupees(widget.user.credit));
  late bool _active = widget.user.isActive;
  late bool _verified = widget.user.emailVerified;
  late bool _staff = widget.user.isStaff;

  static const _fields = ['credit', 'is_active', 'email_verified', 'is_staff'];

  @override
  void dispose() {
    _credit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await context.read<AdminUserFormCubit>().save(
      widget.user.id,
      credit: _credit.text,
      isActive: _active,
      emailVerified: _verified,
      isStaff: _staff,
    );
    if (saved != null && mounted) Navigator.of(context).pop(saved);
  }

  Widget _switch(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    String? help,
    String? error,
  }) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    value: value,
    onChanged: onChanged,
    title: Text(title, style: body(14, weight: FontWeight.w700)),
    subtitle: help == null && error == null
        ? null
        : Text(
            error ?? help!,
            style: body(12, color: error == null ? Q.text3 : Q.red),
          ),
  );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AdminUserFormCubit>().state;
    final u = widget.user;
    return AdminFormDialog(
      title: u.gamertag.isEmpty ? u.email : u.gamertag,
      saving: s.status.isLoading,
      error: formError<AdminUser>(s, _fields),
      onSave: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(u.email, style: body(13, color: Q.text3)),
          const SizedBox(height: 16),
          AdminField(
            label: 'Credit (₹)',
            controller: _credit,
            prefix: '₹ ',
            decimal: true,
            error: s.errorFor('credit'),
          ),
          const SizedBox(height: 8),
          _switch(
            'Active',
            _active,
            (v) => setState(() => _active = v),
            help: 'Inactive accounts cannot log in.',
            error: s.errorFor('is_active'),
          ),
          _switch(
            'Email verified',
            _verified,
            (v) => setState(() => _verified = v),
            error: s.errorFor('email_verified'),
          ),
          _switch(
            'Staff',
            _staff,
            (v) => setState(() => _staff = v),
            help:
                'Only superusers can change this; the server ignores it otherwise.',
            error: s.errorFor('is_staff'),
          ),
        ],
      ),
    );
  }
}
