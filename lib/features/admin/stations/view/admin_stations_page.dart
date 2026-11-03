import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/admin_models.dart';
import '../../../../data/models/models.dart' show rupees;
import '../../../../data/repositories/admin_repository.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/theme.dart';
import '../../../../theme/widgets.dart';
import '../../common/view/admin_ui.dart';
import '../bloc/admin_stations_cubit.dart';

/// Station types (pricing, seats) and the stations of each type.
class AdminStationsPage extends StatelessWidget {
  /// Creates the page.
  const AdminStationsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => AdminStationsCubit(ctx.read<AdminRepository>())..load(),
    child: BlocListener<AdminStationsCubit, AdminStationsState>(
      listenWhen: (a, b) => a.seq != b.seq,
      listener: (context, s) {
        if (s.actionError != null) {
          showApiError(context, s.actionError);
        } else if (s.message != null) {
          showToast(context, s.message!);
        }
      },
      child: const _StationsView(),
    ),
  );
}

class _StationsView extends StatelessWidget {
  const _StationsView();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AdminStationsCubit>().state;
    final cubit = context.read<AdminStationsCubit>();
    return AdminPage(
      title: 'Stations',
      subtitle: 'Station types, hourly rates and the stations of each type',
      actions: [
        AdminOutlineButton(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: cubit.load,
        ),
      ],
      child: AdminAsync<AdminStationType>(
        status: s.typesStatus,
        items: s.types,
        error: s.typesError,
        onRetry: cubit.load,
        emptyIcon: Icons.tv_off_outlined,
        emptyText: 'No station types configured.',
        builder: (types) => LayoutBuilder(
          builder: (context, c) {
            const typesPane = _TypesPane();
            const stationsPane = _StationsPane();
            if (c.maxWidth >= 1000) {
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _Scroll(typesPane)),
                  SizedBox(width: 16),
                  Expanded(flex: 2, child: _Scroll(stationsPane)),
                ],
              );
            }
            return const SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [typesPane, SizedBox(height: 16), stationsPane],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Scroll extends StatelessWidget {
  const _Scroll(this.child);
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    primary: false,
    padding: const EdgeInsets.only(bottom: 24),
    child: child,
  );
}

class _TypesPane extends StatelessWidget {
  const _TypesPane();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AdminStationsCubit>().state;
    final types = s.types ?? const <AdminStationType>[];
    return AdminCard(
      title: 'Station types',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final t in types)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: s.editingId == t.id
                  ? _TypeEditor(
                      key: ValueKey('edit-${t.id}'),
                      type: t,
                      errors: s.fieldErrors,
                      saving: s.saveStatus.isLoading,
                    )
                  : _TypeRow(type: t, selected: s.selected == t.code),
            ),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.type, required this.selected});
  final AdminStationType type;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminStationsCubit>();
    return Material(
      color: selected ? Q.surfaceHi : Q.surfaceLo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? Q.primary : Q.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => cubit.select(type.code),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          type.name,
                          style: body(15, weight: FontWeight.w800),
                        ),
                        Text(
                          type.code,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Q.link,
                          ),
                        ),
                      ],
                    ),
                    if (type.spec.isNotEmpty)
                      Text(type.spec, style: body(12, color: Q.text3)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        _Stat('Rate', '₹${rupees(type.hourlyRate)}/seat/h'),
                        _Stat('Seats/station', '${type.seatsPerStation}'),
                        _Stat('Stations', '${type.stationCount}'),
                        _Stat('Sort', '${type.sort}'),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit ${type.name}',
                onPressed: () => cubit.startEdit(type.id),
                icon: const Icon(Icons.edit_outlined, color: Q.link),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.k, this.v);
  final String k, v;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$k ',
          style: body(12, color: Q.text3),
        ),
        TextSpan(
          text: v,
          style: body(12, weight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _TypeEditor extends StatefulWidget {
  const _TypeEditor({
    super.key,
    required this.type,
    required this.errors,
    required this.saving,
  });
  final AdminStationType type;
  final Map<String, String> errors;
  final bool saving;

  @override
  State<_TypeEditor> createState() => _TypeEditorState();
}

class _TypeEditorState extends State<_TypeEditor> {
  late final t = widget.type;
  late final _name = TextEditingController(text: t.name);
  late final _spec = TextEditingController(text: t.spec);
  late final _seats = TextEditingController(text: '${t.seatsPerStation}');
  late final _rate = TextEditingController(text: rupees(t.hourlyRate));
  late final _sort = TextEditingController(text: '${t.sort}');

  static const _shown = {
    'name',
    'spec',
    'seats_per_station',
    'hourly_rate',
    'sort',
  };

  @override
  void dispose() {
    for (final c in [_name, _spec, _seats, _rate, _sort]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() => context.read<AdminStationsCubit>().saveType(
    t.copyWith(
      name: _name.text.trim(),
      spec: _spec.text.trim(),
      seatsPerStation: int.tryParse(_seats.text) ?? t.seatsPerStation,
      hourlyRate: double.tryParse(_rate.text) ?? t.hourlyRate,
      sort: int.tryParse(_sort.text) ?? t.sort,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final e = widget.errors;
    final other = e.entries.where((x) => !_shown.contains(x.key)).firstOrNull;
    Widget grid(List<Widget> children) => LayoutBuilder(
      builder: (_, c) {
        final cols = c.maxWidth >= 560 ? 3 : (c.maxWidth >= 340 ? 2 : 1);
        final w = (c.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final x in children) SizedBox(width: w, child: x)],
        );
      },
    );
    return Panel(
      color: Q.surfaceHi,
      borderColor: Q.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit ${t.code}', style: display(15, weight: FontWeight.w600)),
          const SizedBox(height: 10),
          FormErrorBanner(other?.value),
          grid([
            AdminField(label: 'Name', controller: _name, error: e['name']),
            AdminField(
              label: 'Hourly rate',
              controller: _rate,
              prefix: '₹ ',
              decimal: true,
              error: e['hourly_rate'],
            ),
            AdminField(
              label: 'Seats per station',
              controller: _seats,
              digitsOnly: true,
              error: e['seats_per_station'],
            ),
            AdminField(
              label: 'Sort',
              controller: _sort,
              digitsOnly: true,
              error: e['sort'],
            ),
          ]),
          const SizedBox(height: 12),
          AdminField(
            label: 'Spec',
            controller: _spec,
            hint: 'PS5 · 55" 4K TV · DualSense',
            error: e['spec'],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                onPressed: widget.saving
                    ? null
                    : context.read<AdminStationsCubit>().cancelEdit,
                child: Text('Cancel', style: body(14, color: Q.text2)),
              ),
              AdminButton(
                label: 'Save',
                icon: Icons.check_rounded,
                loading: widget.saving,
                onPressed: _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StationsPane extends StatelessWidget {
  const _StationsPane();

  Future<void> _delete(BuildContext context, AdminStation st) async {
    final cubit = context.read<AdminStationsCubit>();
    final ok = await confirmAction(
      context,
      title: 'Delete ${st.code}?',
      message:
          'Its ${st.seatCount} seats are removed too. To take it out of '
          'service for a while, switch it off instead.',
    );
    if (ok) await cubit.delete(st);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AdminStationsCubit>().state;
    final cubit = context.read<AdminStationsCubit>();
    final type = s.selectedType;
    final Widget content;
    if (type == null) {
      content = const AdminEmpty(text: 'Select a station type.');
    } else if (s.stations == null || s.stationsStatus.isFailure) {
      content = s.stationsStatus.isFailure
          ? ErrorView(
              error: s.stationsError ?? 'Failed to load',
              onRetry: cubit.reloadStations,
            )
          : const Padding(padding: EdgeInsets.all(24), child: LoadingView());
    } else if (s.stations!.isEmpty) {
      content = const AdminEmpty(
        icon: Icons.tv_off_outlined,
        text: 'No stations of this type yet.',
      );
    } else {
      content = Column(
        children: [
          for (final st in s.stations!)
            _StationRow(
              station: st,
              busy: s.busyIds.contains(st.id),
              onToggle: (v) => cubit.setActive(st, v),
              onDelete: () => _delete(context, st),
            ),
        ],
      );
    }
    return AdminCard(
      title: type == null ? 'Stations' : '${type.name} stations',
      trailing: type == null
          ? null
          : AdminButton(
              label: 'Add #${s.nextNumber.toString().padLeft(2, '0')}',
              icon: Icons.add_rounded,
              loading: s.adding,
              onPressed: s.stations == null ? null : cubit.addStation,
            ),
      child: content,
    );
  }
}

class _StationRow extends StatelessWidget {
  const _StationRow({
    required this.station,
    required this.busy,
    required this.onToggle,
    required this.onDelete,
  });
  final AdminStation station;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 4),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Q.border, width: 0.6)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                station.code,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: station.isActive ? Q.text : Q.text3,
                ),
              ),
              Text(
                '#${station.number} · ${station.seatCount} seats'
                '${station.isActive ? '' : ' · off'}',
                style: body(12, color: Q.text3),
              ),
            ],
          ),
        ),
        if (busy)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        Switch(value: station.isActive, onChanged: busy ? null : onToggle),
        IconButton(
          tooltip: 'Delete ${station.code}',
          onPressed: busy ? null : onDelete,
          icon: const Icon(Icons.delete_outline, color: Q.red),
        ),
      ],
    ),
  );
}
