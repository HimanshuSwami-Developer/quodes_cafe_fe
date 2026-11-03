import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/routes.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/booking_flow_cubit.dart';
import '../bloc/slots_cubit.dart';

class SlotsPage extends StatelessWidget {
  const SlotsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) =>
        SlotsCubit(ctx.read<CatalogRepository>(), ctx.read<BookingFlowCubit>())
          ..load(),
    child: MultiBlocListener(
      listeners: [
        BlocListener<BookingFlowCubit, BookingFlowState>(
          listenWhen: (a, b) => b.error != null && a.error != b.error,
          listener: (context, state) {
            showToast(context, state.error!.message);
            // The slot was probably taken meanwhile: refresh the grid.
            context.read<SlotsCubit>().loadHours();
          },
        ),
        BlocListener<SlotsCubit, SlotsState>(
          listenWhen: (a, b) =>
              b.error != null && a.error != b.error && b.days != null,
          listener: (context, state) =>
              showToast(context, state.error!.message),
        ),
      ],
      child: const _SlotsView(),
    ),
  );
}

class _SlotsView extends StatelessWidget {
  const _SlotsView();

  Future<void> _lock(BuildContext context) async {
    final booking = await context.read<BookingFlowCubit>().lock();
    if (booking != null && context.mounted) {
      context.pushBooking(booking, BookingStep.hold);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SlotsCubit>();
    final state = context.watch<SlotsCubit>().state;
    final d = context.watch<BookingFlowCubit>().state;
    final days = state.days;
    final hours = state.hours;
    final dur = d.duration;
    final start = state.startIndex(d.startHour);
    if (state.error != null && days == null) {
      return QBackground(
        hero: const QHeroImage(
          QPhoto.synthwave,
          height: 300,
          focus: (50, 60),
          opacity: 0.55,
        ),
        child: ErrorView(error: state.error!, onRetry: cubit.load),
      );
    }
    if (days == null) {
      return const QBackground(
        hero: QHeroImage(
          QPhoto.synthwave,
          height: 300,
          focus: (50, 60),
          opacity: 0.55,
        ),
        child: LoadingView(),
      );
    }
    final rate = d.type?.hourlyRate ?? 0;
    final clash = hours == null ? null : slotClash(hours, start, dur);
    if (days.isEmpty) {
      return QBackground(
        hero: const QHeroImage(
          QPhoto.synthwave,
          height: 300,
          focus: (50, 60),
          opacity: 0.55,
        ),
        child: Center(
          child: Text(
            'No dates open for booking',
            style: body(14, color: Q.text3),
          ),
        ),
      );
    }
    final day = days[state.day];
    return QBackground(
      hero: const QHeroImage(
        QPhoto.synthwave,
        height: 300,
        focus: (50, 60),
        opacity: 0.55,
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              children: [
                const Row(
                  children: [
                    SquareIconButton(semantic: 'Back to availability'),
                    Spacer(),
                    StepDots(step: 3),
                  ],
                ),
                const SizedBox(height: 14),
                Text('LOCK YOUR TIME', style: display(24)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _tag(d.game?.mono ?? '', Q.pinkBg, Q.pinkText, Q.pink),
                    _tag(d.stationSummary, Q.surfaceHi, Q.link, Q.primary),
                    _tag(
                      '${d.players} ${d.players == 1 ? 'player' : 'players'}',
                      Q.surface,
                      Q.text2,
                      Q.borderHi,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 66,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final x = days[i];
                      final on = i == state.day;
                      return Semantics(
                        button: true,
                        selected: on,
                        label: '${x.dow} ${x.num} ${x.mon}',
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () {
                            cubit.selectDay(i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 52,
                            decoration: BoxDecoration(
                              color: on ? Q.primary : Q.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: on ? Q.primary : Q.border,
                              ),
                              boxShadow: on
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x732F6BFF),
                                        blurRadius: 16,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  x.dow,
                                  style: label(
                                    10,
                                    color: on ? Colors.white : Q.text3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${x.num}',
                                  style: display(
                                    20,
                                    color: on ? Colors.white : Q.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('DURATION', style: label(12)),
                    const SizedBox(width: 12),
                    ...[1, 2, 3, 4].map(
                      (n) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: n < 4 ? 6 : 0),
                          child: QChip(
                            label: '${n}h',
                            selected: n == dur,
                            selBg: Q.pinkBg,
                            selFg: Q.pinkText,
                            selBorder: Q.pink,
                            glow: false,
                            onTap: () => context
                                .read<BookingFlowCubit>()
                                .selectDuration(n),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('START TIME', style: display(15, spacing: 0.06)),
                const SizedBox(height: 10),
                if (hours == null)
                  const SizedBox(height: 160, child: LoadingView())
                else if (hours.isEmpty)
                  Text('Closed on this day', style: body(14, color: Q.text3))
                else
                  LayoutBuilder(
                    builder: (context, c) {
                      final w = (c.maxWidth - 8 * 3) / 4;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          hours.length,
                          (k) => _slot(context, hours, start, dur, k, w),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _legend(Q.surface, Q.borderHi, 'Free'),
                    _legend(Q.primary, Q.primary, 'Your session'),
                    _legend(Q.amberBg, Q.amber, 'Locked by player'),
                    _legend(Q.bg, Q.surfaceLo, 'Booked'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: Color(0xF00A1330),
              border: Border(top: BorderSide(color: Q.border)),
            ),
            child: start == null || hours == null
                ? SizedBox(
                    height: 54,
                    child: Center(
                      child: Text(
                        'Pick a start time',
                        style: body(
                          14,
                          color: Q.text3,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : clash != null
                ? Semantics(
                    liveRegion: true,
                    child: Container(
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Q.redBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Q.redBorder),
                      ),
                      child: Text(
                        clash,
                        style: body(
                          14,
                          color: Q.redText,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${day.dow[0]}${day.dow.substring(1).toLowerCase()}, ${day.num} ${day.mon} · ₹${rupees(rate)} × ${d.players} × $dur hr',
                              style: body(
                                12,
                                color: Q.text3,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${hourLabel(hours[start].hour)} – ${hourLabel(hours[start].hour + dur)}',
                              style: display(18),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: PrimaryButton(
                          label: 'LOCK SLOT',
                          loading: d.locking,
                          onPressed: () => _lock(context),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _slot(
    BuildContext context,
    List<SlotHour> hours,
    int? s,
    int dur,
    int k,
    double w,
  ) {
    final h = hours[k];
    final inRange = s != null && k >= s && k < s + dur;
    late Color bg, fg, border;
    var dashed = false, strike = false;
    String aria;
    switch (h.status) {
      case 'booked':
      case 'past':
        bg = Q.bg;
        fg = Q.muted;
        border = Q.surfaceLo;
        strike = true;
        aria = h.status == 'past' ? 'past' : 'booked';
      case 'hold':
        bg = Q.amberBg;
        fg = Q.amber;
        border = const Color(0xFFF5A524);
        dashed = true;
        aria = 'locked by another player';
      default:
        if (k == s) {
          bg = Q.primary;
          fg = Colors.white;
          border = Q.primary;
          aria = 'start time selected';
        } else if (inRange) {
          bg = Q.primaryMid;
          fg = Q.linkHi;
          border = Q.primary;
          aria = 'part of your session';
        } else {
          bg = Q.surface;
          fg = Q.text;
          border = Q.borderHi;
          aria = 'free';
        }
    }
    final enabled = h.status == 'open';
    return Semantics(
      button: true,
      enabled: enabled,
      label: '${hourLabel(h.hour)}, $aria',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: enabled
            ? () => context.read<BookingFlowCubit>().selectStart(h.hour)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: w,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: dashed ? 1.5 : 1),
            boxShadow: k == s
                ? const [BoxShadow(color: Color(0x8C2F6BFF), blurRadius: 16)]
                : null,
          ),
          child: Text(
            hourLabel(h.hour).replaceAll(' ', ''),
            style: body(13, color: fg, weight: FontWeight.w800).copyWith(
              decoration: strike ? TextDecoration.lineThrough : null,
              decorationColor: fg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String t, Color bg, Color fg, Color border) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: border),
    ),
    child: Text(
      t,
      style: body(12, color: fg, weight: FontWeight.w800),
    ),
  );

  Widget _legend(Color bg, Color border, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: border),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        t,
        style: body(12, color: Q.text3, weight: FontWeight.w700),
      ),
    ],
  );
}
