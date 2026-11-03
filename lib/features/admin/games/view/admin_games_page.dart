import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/game_art.dart';
import '../../../../theme/theme.dart';
import '../../../../theme/widgets.dart';
import '../../common/bloc/admin_list_cubit.dart';
import '../../common/view/admin_ui.dart';
import '../bloc/admin_games_cubit.dart';
import '../bloc/game_form_cubit.dart';

/// Staff catalogue of games: grid with add / edit / delete.
class AdminGamesPage extends StatelessWidget {
  /// Creates the page.
  const AdminGamesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => AdminGamesCubit(ctx.read<AdminRepository>())..load(),
    child: BlocListener<AdminGamesCubit, AdminListState<AdminGame>>(
      listenWhen: (a, b) => a.seq != b.seq,
      listener: (context, s) => showApiError(context, s.actionError),
      child: const _GamesView(),
    ),
  );
}

class _GamesView extends StatelessWidget {
  const _GamesView();

  Future<void> _edit(BuildContext context, [AdminGame? game]) async {
    final cubit = context.read<AdminGamesCubit>();
    final saved = await showDialog<AdminGame>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => GameFormCubit(context.read<AdminRepository>()),
        child: _GameDialog(
          initial: game ?? const AdminGame(),
          platforms: cubit.platforms,
        ),
      ),
    );
    if (saved == null || !context.mounted) return;
    cubit.upsert(saved);
    showToast(context, game == null ? '${saved.name} added' : 'Saved');
  }

  Future<void> _delete(BuildContext context, AdminGame g) async {
    final cubit = context.read<AdminGamesCubit>();
    final ok = await confirmAction(
      context,
      title: 'Delete ${g.name}?',
      message:
          'Players will no longer see it. Past bookings keep their record. '
          'Consider unticking "Active" instead.',
    );
    if (!ok) return;
    if (await cubit.delete(g) && context.mounted) {
      showToast(context, '${g.name} deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AdminGamesCubit>().state;
    return AdminPage(
      title: 'Games',
      subtitle: 'What players can book, in display order',
      actions: [
        AdminOutlineButton(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: () => context.read<AdminGamesCubit>().load(silent: true),
        ),
        AdminButton(
          label: 'Add game',
          icon: Icons.add_rounded,
          onPressed: () => _edit(context),
        ),
      ],
      child: AdminAsync<AdminGame>(
        status: s.status,
        items: s.items,
        error: s.error,
        onRetry: () => context.read<AdminGamesCubit>().load(),
        emptyIcon: Icons.sports_esports_outlined,
        emptyText: 'No games yet. Add the first one.',
        builder: (games) => GridView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            mainAxisExtent: 286,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: games.length,
          itemBuilder: (_, i) => _GameTile(
            game: games[i],
            busy: s.busyIds.contains(games[i].id),
            onEdit: () => _edit(context, games[i]),
            onDelete: () => _delete(context, games[i]),
          ),
        ),
      ),
    );
  }
}

/// Tile art: the design export when one exists, else a hue→deep gradient.
class _Art extends StatelessWidget {
  const _Art({required this.mono, required this.hue, required this.deep});
  final String mono, hue, deep;

  @override
  Widget build(BuildContext context) {
    if (mono.isNotEmpty && GameArt.has(mono)) return GameArt(mono);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hexColor(hue), hexColor(deep, Q.surface)],
        ),
      ),
      child: Center(
        child: Text(
          mono.isEmpty ? '?' : mono.toUpperCase(),
          style: display(30, weight: FontWeight.w700, spacing: 0.08),
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.game,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });
  final AdminGame game;
  final bool busy;
  final VoidCallback onEdit, onDelete;

  @override
  Widget build(BuildContext context) => Panel(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 120,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: game.isActive ? 1 : 0.45,
                  child: _Art(mono: game.mono, hue: game.hue, deep: game.deep),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _Tag('#${game.sort}', Q.surface),
                ),
                if (!game.isActive)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: _Tag('INACTIVE', Color(0xFFD9364F)),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: body(15, weight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${game.mono} · ${game.genre}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: body(12, color: Q.text3, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final p in game.platforms) _Tag(p, Q.surfaceHi),
                    _Tag('${game.maxPlayers}P max', Q.surfaceLo),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (busy)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: busy ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined, color: Q.link),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: busy ? null : onDelete,
                      icon: const Icon(Icons.delete_outline, color: Q.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Q.borderHi),
    ),
    child: Text(text, style: body(11, weight: FontWeight.w800)),
  );
}

class _GameDialog extends StatefulWidget {
  const _GameDialog({required this.initial, required this.platforms});
  final AdminGame initial;
  final List<String> platforms;

  @override
  State<_GameDialog> createState() => _GameDialogState();
}

class _GameDialogState extends State<_GameDialog> {
  static const _fields = [
    'name',
    'mono',
    'genre',
    'hue',
    'deep',
    'platforms',
    'max_players',
    'is_active',
    'sort',
  ];

  late final g = widget.initial;
  late final _name = TextEditingController(text: g.name);
  late final _mono = TextEditingController(text: g.mono);
  late final _hue = TextEditingController(text: g.hue);
  late final _deep = TextEditingController(text: g.deep);
  late final _max = TextEditingController(text: '${g.maxPlayers}');
  late final _sort = TextEditingController(text: '${g.sort}');
  late String _genre = adminGenres.contains(g.genre)
      ? g.genre
      : adminGenres.first;
  late final Set<String> _platforms = {...g.platforms};
  late bool _active = g.isActive;

  @override
  void dispose() {
    for (final c in [_name, _mono, _hue, _deep, _max, _sort]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _platformOptions => [
    ...widget.platforms,
    for (final p in g.platforms)
      if (!widget.platforms.contains(p)) p,
  ];

  Future<void> _save() async {
    final draft = AdminGame(
      id: g.id,
      name: _name.text.trim(),
      mono: _mono.text.trim().toUpperCase(),
      genre: _genre,
      hue: _hue.text.trim(),
      deep: _deep.text.trim(),
      platforms: [
        for (final p in _platformOptions)
          if (_platforms.contains(p)) p,
      ],
      maxPlayers: int.tryParse(_max.text) ?? g.maxPlayers,
      isActive: _active,
      sort: int.tryParse(_sort.text) ?? 0,
    );
    final saved = await context.read<GameFormCubit>().save(draft);
    if (saved != null && mounted) Navigator.of(context).pop(saved);
  }

  Widget _colour(String label, TextEditingController c, String? error) =>
      AdminField(
        label: label,
        controller: c,
        mono: true,
        hint: '#2F6BFF',
        error: error,
        onChanged: (_) => setState(() {}),
        suffix: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: hexColor(c.text, Colors.transparent),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Q.borderHi),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameFormCubit>().state;
    final saving = s.status.isLoading;
    return AdminFormDialog(
      title: g.isNew ? 'Add game' : 'Edit ${g.name}',
      saving: saving,
      onSave: _save,
      error: formError<AdminGame>(s, _fields),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 200,
                height: 90,
                child: _Art(
                  mono: _mono.text.trim(),
                  hue: _hue.text.trim(),
                  deep: _deep.text.trim(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AdminField(
            label: 'Name',
            controller: _name,
            hint: 'EA Sports FC 25',
            error: s.errorFor('name'),
            autofocus: g.isNew,
          ),
          const SizedBox(height: 12),
          _pair(
            AdminField(
              label: 'Short code',
              controller: _mono,
              mono: true,
              hint: 'FC25',
              error: s.errorFor('mono'),
              onChanged: (_) => setState(() {}),
            ),
            _GenrePicker(
              value: _genre,
              error: s.errorFor('genre'),
              onChanged: (v) => setState(() => _genre = v),
            ),
          ),
          const SizedBox(height: 12),
          _pair(
            _colour('Hue colour', _hue, s.errorFor('hue')),
            _colour('Deep colour', _deep, s.errorFor('deep')),
          ),
          const SizedBox(height: 12),
          const FieldLabel('Platforms'),
          Wrap(
            spacing: 8,
            children: [
              for (final p in _platformOptions)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _platforms.contains(p),
                      onChanged: (v) => setState(
                        () => v == true
                            ? _platforms.add(p)
                            : _platforms.remove(p),
                      ),
                    ),
                    Text(p, style: body(14, weight: FontWeight.w700)),
                  ],
                ),
            ],
          ),
          if (s.errorFor('platforms') != null)
            Text(
              s.errorFor('platforms')!,
              style: body(12, color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 12),
          _pair(
            AdminField(
              label: 'Max players',
              controller: _max,
              digitsOnly: true,
              error: s.errorFor('max_players'),
            ),
            AdminField(
              label: 'Sort',
              controller: _sort,
              digitsOnly: true,
              error: s.errorFor('sort'),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            title: Text('Active', style: body(14, weight: FontWeight.w700)),
            subtitle: Text(
              s.errorFor('is_active') ??
                  'Inactive games are hidden from players',
              style: body(12, color: Q.text3),
            ),
          ),
        ],
      ),
    );
  }

  /// Two fields side by side, stacked on narrow dialogs.
  Widget _pair(Widget a, Widget b) => LayoutBuilder(
    builder: (_, c) => c.maxWidth < 420
        ? Column(children: [a, const SizedBox(height: 12), b])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 12),
              Expanded(child: b),
            ],
          ),
  );
}

class _GenrePicker extends StatelessWidget {
  const _GenrePicker({
    required this.value,
    required this.onChanged,
    this.error,
  });
  final String value;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      const FieldLabel('Genre'),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: value,
        isDense: true,
        dropdownColor: Q.surfaceHi,
        style: body(14),
        decoration: InputDecoration(
          isDense: true,
          errorText: error,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        items: [
          for (final g in adminGenres)
            DropdownMenuItem(value: g, child: Text(g)),
        ],
        onChanged: (v) => v == null ? null : onChanged(v),
      ),
    ],
  );
}
