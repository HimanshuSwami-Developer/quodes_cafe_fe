import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/theme.dart';
import '../../../../theme/widgets.dart';
import '../../common/view/admin_ui.dart';
import '../../shell/admin_badges_cubit.dart';
import '../bloc/admin_tickets_cubit.dart';

/// Support tickets by status, with reply + status editing.
class AdminTicketsPage extends StatelessWidget {
  /// Creates the page.
  const AdminTicketsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => AdminTicketsCubit(ctx.read<AdminRepository>())..load(),
    child: BlocListener<AdminTicketsCubit, AdminTicketsState>(
      listenWhen: (a, b) => a.seq != b.seq,
      listener: (context, s) {
        if (s.saved != null) {
          showToast(
            context,
            'Ticket #${s.saved!.number} saved · player emailed',
          );
          try {
            context.read<AdminBadgesCubit>().refresh();
          } catch (_) {
            // Outside the admin shell (tests).
          }
        } else if (s.saveError != null) {
          showApiError(context, s.saveError);
        }
      },
      child: const _TicketsView(),
    ),
  );
}

class _TicketsView extends StatelessWidget {
  const _TicketsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminTicketsCubit>();
    final s = context.watch<AdminTicketsCubit>().state;
    return AdminPage(
      title: 'Tickets',
      subtitle: 'Replies and status changes are emailed to the player',
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
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in ticketStatuses)
                QChip(
                  label: ticketStatusLabel(t),
                  height: 36,
                  glow: false,
                  selected: s.tab == t,
                  onTap: () => cubit.selectTab(t),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: AdminAsync<AdminTicket>(
              status: s.status,
              items: s.items,
              error: s.error,
              onRetry: cubit.load,
              emptyIcon: Icons.mark_email_read_outlined,
              emptyText:
                  'No ${ticketStatusLabel(s.tab).toLowerCase()} tickets.',
              builder: (items) => ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _TicketCard(
                  key: ValueKey('${items[i].id}@${items[i].updatedAt}'),
                  ticket: items[i],
                  saving: s.savingIds.contains(items[i].id),
                  errors: s.fieldErrors[items[i].id] ?? const {},
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatefulWidget {
  const _TicketCard({
    super.key,
    required this.ticket,
    required this.saving,
    required this.errors,
  });
  final AdminTicket ticket;
  final bool saving;
  final Map<String, String> errors;

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  late final _reply = TextEditingController(text: widget.ticket.staffReply);
  late String _status = widget.ticket.status;

  @override
  void didUpdateWidget(covariant _TicketCard old) {
    super.didUpdateWidget(old);
    if (old.ticket.updatedAt != widget.ticket.updatedAt) {
      _reply.text = widget.ticket.staffReply;
      _status = widget.ticket.status;
    }
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('#${t.number}', style: display(16, weight: FontWeight.w700)),
              Text(t.topic, style: body(14, weight: FontWeight.w800)),
              StatusPill(t.status, label: ticketStatusLabel(t.status)),
              Text(
                '${t.player.display} · ${t.player.email}',
                style: body(13, color: Q.text2),
              ),
              if (t.bookingCode.isNotEmpty)
                SelectableText(
                  'Booking ${t.bookingCode}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Q.link,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Opened ${adminDateTime(t.createdAt)} · updated ${adminDateTime(t.updatedAt)}',
            style: body(12, color: Q.text3),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Q.surfaceLo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(t.message, style: body(14, height: 1.4)),
          ),
          if (t.attachmentUrl != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => openUrl(t.attachmentUrl!),
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                label: Text(
                  'Open attachment',
                  style: body(13, color: Q.link, weight: FontWeight.w700),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          AdminField(
            label: 'Staff reply',
            controller: _reply,
            hint: 'Write a reply to the player…',
            maxLines: 4,
            error: widget.errors['staff_reply'],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  isDense: true,
                  dropdownColor: Q.surfaceHi,
                  style: body(14),
                  decoration: InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                    errorText: widget.errors['status'],
                  ),
                  items: [
                    for (final st in ticketStatuses)
                      DropdownMenuItem(
                        value: st,
                        child: Text(ticketStatusLabel(st)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? _status),
                ),
              ),
              AdminButton(
                label: 'Save',
                icon: Icons.send_rounded,
                loading: widget.saving,
                onPressed: () => context.read<AdminTicketsCubit>().save(
                  t,
                  status: _status,
                  reply: _reply.text.trim(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
