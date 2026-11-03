import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/support_repository.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/support_cubit.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key, this.topic, this.bookingCode});
  final String? topic;
  final String? bookingCode;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => SupportCubit(
      ctx.read<CatalogRepository>(),
      ctx.read<SupportRepository>(),
      topic: topic,
    )..load(),
    child: BlocListener<SupportCubit, SupportState>(
      listenWhen: (a, b) =>
          a.submitStatus != b.submitStatus ||
          (b.error != null && a.error != b.error),
      listener: (context, state) {
        if (state.submitStatus.isSuccess && state.created != null) {
          showToast(context, 'Ticket #${state.created!.number} raised');
        } else if (state.error != null) {
          showToast(context, state.error!.message);
        }
      },
      child: _SupportView(topic: topic, bookingCode: bookingCode),
    ),
  );
}

class _SupportView extends StatefulWidget {
  const _SupportView({this.topic, this.bookingCode});
  final String? topic;
  final String? bookingCode;
  @override
  State<_SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<_SupportView> {
  late final _bid = TextEditingController(text: widget.bookingCode ?? '');
  final _msg = TextEditingController();

  /// The tab stays alive; a later `goSupport(topic:, bookingCode:)` arrives
  /// as new widget params instead of a fresh page.
  @override
  void didUpdateWidget(covariant _SupportView old) {
    super.didUpdateWidget(old);
    if (widget.topic != old.topic) {
      context.read<SupportCubit>().prefill(topic: widget.topic);
    }
    if (widget.bookingCode != old.bookingCode && widget.bookingCode != null) {
      _bid.text = widget.bookingCode!;
    }
  }

  @override
  void dispose() {
    _bid.dispose();
    _msg.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null && mounted) {
      context.read<SupportCubit>().setAttachment(x);
    }
  }

  Future<void> _submit() async {
    final ok = await context.read<SupportCubit>().submit(
      message: _msg.text,
      bookingCode: _bid.text,
    );
    if (ok) _msg.clear();
  }

  Future<void> _open(Uri? u) async {
    if (u == null) return;
    final ok = await launchUrl(u, mode: LaunchMode.externalApplication);
    if (!ok && mounted) showToast(context, 'Couldn’t open that');
  }

  String _ago(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return DateFormat('d MMM').format(d);
  }

  Widget _quick(IconData i, String t, VoidCallback onTap) => Expanded(
    child: Material(
      color: Q.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Q.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(i, color: Q.link, size: 22),
              const SizedBox(height: 6),
              Text(t, style: body(13, weight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SupportCubit>();
    final state = context.watch<SupportCubit>().state;
    final cafe = state.cafe;
    final attach = state.attachment;
    final tickets = state.tickets;
    return QBackground(
      hero: const QHeroImage(
        QPhoto.neonSetup,
        height: 280,
        focus: (30, 50),
        opacity: 0.5,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        children: [
          Text('SUPPORT', style: display(20)),
          const SizedBox(height: 4),
          Row(
            children: [
              const BlinkDot(),
              const SizedBox(width: 6),
              Text(
                cafe == null
                    ? 'Desk online'
                    : 'Desk online · replies within ${cafe.replyMinutes} min',
                style: body(12, color: Q.green, weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _quick(Icons.chat_bubble_outline_rounded, 'Chat', () {
                final p =
                    cafe?.supportPhone.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                _open(p.isEmpty ? null : Uri.parse('https://wa.me/$p'));
              }),
              const SizedBox(width: 8),
              _quick(
                Icons.call_outlined,
                'Call desk',
                () => _open(
                  cafe == null || cafe.supportPhone.isEmpty
                      ? null
                      : Uri(scheme: 'tel', path: cafe.supportPhone),
                ),
              ),
              const SizedBox(width: 8),
              _quick(
                Icons.place_outlined,
                'Directions',
                () => _open(
                  cafe == null || cafe.mapsUrl.isEmpty
                      ? null
                      : Uri.parse(cafe.mapsUrl),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Panel(
            radius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('RAISE A TICKET', style: display(15, spacing: 0.06)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SupportState.topics
                      .map(
                        (t) => QChip(
                          label: t,
                          height: 40,
                          selected: t == state.topic,
                          selBg: Q.surfaceHi,
                          selFg: Q.link,
                          glow: false,
                          onTap: () => cubit.selectTopic(t),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                QField(
                  label: 'Booking ID',
                  controller: _bid,
                  hint: 'e.g. QG-7F3K2A',
                ),
                const SizedBox(height: 12),
                QField(
                  label: 'What happened?',
                  controller: _msg,
                  hint: 'Describe the issue',
                  maxLines: 3,
                ),
                if (attach != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 16,
                        color: Q.text3,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          attach.name,
                          overflow: TextOverflow.ellipsis,
                          style: body(12, color: Q.text3),
                        ),
                      ),
                      TextLink(
                        'Remove',
                        size: 12,
                        onTap: () => cubit.setAttachment(null),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Attach file',
                      excludeSemantics: true,
                      child: Material(
                        color: Q.bg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Q.borderHi),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _pick,
                          child: const SizedBox(
                            width: 54,
                            height: 54,
                            child: Icon(
                              Icons.attach_file_rounded,
                              color: Q.text2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: 'SUBMIT TICKET',
                        bob: false,
                        loading: state.submitStatus.isLoading,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (tickets == null)
            const SizedBox(height: 60, child: LoadingView())
          else
            ...tickets.take(3).map((t) {
              final (Color c, Color bg) = switch (t.status) {
                'resolved' => (Q.green, Q.greenBg),
                'in_review' => (Q.amber, Q.amberBg),
                _ => (Q.link, Q.surfaceHi),
              };
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Panel(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${t.number} · ${t.topic}',
                              style: body(14, weight: FontWeight.w800),
                            ),
                            Text(
                              'Updated ${_ago(t.updatedAt)}',
                              style: body(12, color: Q.text3),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t.statusLabel.toUpperCase(),
                          style: label(10, color: c),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
