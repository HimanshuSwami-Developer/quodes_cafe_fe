import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/routes.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/availability_cubit.dart';
import '../bloc/booking_flow_cubit.dart';

class AvailabilityPage extends StatelessWidget {
  const AvailabilityPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => AvailabilityCubit(
      ctx.read<CatalogRepository>(),
      typeCode: ctx.read<BookingFlowCubit>().state.type?.code,
    )..load(),
    child: const _AvailabilityView(),
  );
}

class _AvailabilityView extends StatelessWidget {
  const _AvailabilityView();

  ({Color bg, Color border, Color fg, Color bar}) _level(int n) => n == 0
      ? (bg: Q.redBg, border: Q.redBorder, fg: Q.redText, bar: Q.red)
      : n <= 2
      ? (bg: Q.amberBg, border: Q.amberBorder, fg: Q.amberText, bar: Q.amber)
      : (bg: Q.greenBg, border: Q.greenBorder, fg: Q.greenText, bar: Q.green);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AvailabilityCubit>();
    final state = context.watch<AvailabilityCubit>().state;
    final data = state.data;
    final types = data?.types ?? const <AvailabilityType>[];
    final cur = state.current;
    final type = state.typeCode;
    return QBackground(
      hero: const QHeroImage(QPhoto.neonSetup, height: 280, opacity: 0.55),
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: cubit.load,
              color: Q.link,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                children: [
                  Row(
                    children: [
                      const SquareIconButton(semantic: 'Back to stations'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LIVE AVAILABILITY',
                              style: display(20, spacing: 0.03),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const BlinkDot(),
                                const SizedBox(width: 6),
                                Text(
                                  'LIVE · updated ${DateFormat('h:mm a').format(state.updatedAt ?? DateTime.now())}',
                                  style: body(
                                    12,
                                    color: Q.green,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(3, (i) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                          child: QChip(
                            label: state.dayName(i),
                            selected: state.day == i,
                            glow: false,
                            onTap: () => cubit.selectDay(i),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  if (state.error != null && data == null)
                    SizedBox(
                      height: 300,
                      child: ErrorView(
                        error: state.error!,
                        onRetry: cubit.load,
                      ),
                    )
                  else if (data == null)
                    const SizedBox(height: 300, child: LoadingView())
                  else ...[
                    Row(
                      children: types.map((t) {
                        final on = t.code == type;
                        final lv = _level(t.freeNow);
                        final pct = t.total == 0 ? 0.0 : t.freeNow / t.total;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: t == types.last ? 0 : 8,
                            ),
                            child: Semantics(
                              button: true,
                              selected: on,
                              label:
                                  '${t.name}, ${t.freeNow} of ${t.total} free right now',
                              excludeSemantics: true,
                              child: GestureDetector(
                                onTap: () => cubit.selectType(t.code),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: on ? Q.surfaceHi : Q.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: on ? Q.primary : Q.border,
                                      width: 1.5,
                                    ),
                                    boxShadow: on
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x732F6BFF),
                                              blurRadius: 18,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          t.name,
                                          maxLines: 1,
                                          style: display(
                                            15,
                                            color: on ? Q.link : Q.text2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '${t.freeNow}',
                                              style: display(26, spacing: 0),
                                            ),
                                            TextSpan(
                                              text: '/${t.total}',
                                              style: display(
                                                15,
                                                color: Q.text3,
                                                spacing: 0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0, end: pct),
                                          duration: const Duration(
                                            milliseconds: 900,
                                          ),
                                          curve: Curves.easeOut,
                                          builder: (_, v, _) =>
                                              LinearProgressIndicator(
                                                value: v,
                                                minHeight: 6,
                                                backgroundColor: Q.border,
                                                color: lv.bar,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'free right now',
                                        style: body(
                                          12,
                                          color: Q.text3,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'FREE STATIONS BY HOUR',
                            style: display(15, spacing: 0.06),
                          ),
                        ),
                        Text(
                          '${state.dayName(state.day)} · ${data.hours.isEmpty ? '' : '${data.hours.first.label} – ${data.hours.last.label}'}',
                          style: body(
                            12,
                            color: Q.text3,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Panel(
                      padding: EdgeInsets.zero,
                      radius: 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: [
                            Container(
                              color: Q.surfaceLo,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 76,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Text('TIME', style: label(11)),
                                    ),
                                  ),
                                  ...types.map(
                                    (t) => Expanded(
                                      child: Center(
                                        child: Text(
                                          t.name.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          style: label(
                                            11,
                                            color: t.code == type
                                                ? Q.link
                                                : Q.text2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (data.hours.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'No hours left today',
                                  style: body(13, color: Q.text3),
                                ),
                              ),
                            ...data.hours.map(
                              (h) => Container(
                                height: 36,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Color(0xFF1B2B5E)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 76,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
                                        child: Text(
                                          h.label,
                                          style: body(
                                            13,
                                            color: Q.text2,
                                            weight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    ...types.map((t) {
                                      final n = h.free[t.code] ?? 0;
                                      final lv = _level(n);
                                      return Expanded(
                                        child: Container(
                                          color: t.code == type
                                              ? const Color(0x1F2F6BFF)
                                              : Colors.transparent,
                                          alignment: Alignment.center,
                                          child: Container(
                                            constraints: const BoxConstraints(
                                              minWidth: 52,
                                            ),
                                            height: 24,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: lv.bg,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: lv.border,
                                              ),
                                            ),
                                            child: Text(
                                              n == 0 ? 'Full' : '$n free',
                                              style: body(
                                                12,
                                                color: lv.fg,
                                                weight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _legend(Q.green, '3+ free'),
                        const SizedBox(width: 14),
                        _legend(Q.amber, 'Filling fast'),
                        const SizedBox(width: 14),
                        _legend(Q.red, 'Full'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: PrimaryButton(
              label:
                  'PICK TIME · ${(cur?.name ?? type).toUpperCase()}${cur == null ? '' : ' (${cur.freeNow} FREE)'}',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                context.read<BookingFlowCubit>().selectDate(
                  state.isoDate,
                  state.dayName(state.day),
                );
                context.push(Routes.slots);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String t) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(3),
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
