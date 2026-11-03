import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../../data/repositories/support_repository.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/policies_cubit.dart';

/// Public (also reachable before login).
class PoliciesPage extends StatelessWidget {
  const PoliciesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => PoliciesCubit(ctx.read<SupportRepository>())..load(),
    child: const _PoliciesView(),
  );
}

class _PoliciesView extends StatelessWidget {
  const _PoliciesView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PoliciesCubit>();
    final state = context.watch<PoliciesCubit>().state;
    final ps = state.policies;
    final tab = state.tab;
    return QBackground(
      hero: const QHeroImage(QPhoto.streaks, height: 260, opacity: 0.7),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const QHeader(title: 'POLICIES'),
            const SizedBox(height: 14),
            if (state.error != null && ps == null)
              Expanded(
                child: ErrorView(error: state.error!, onRetry: cubit.load),
              )
            else if (ps == null)
              const Expanded(child: LoadingView())
            else ...[
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Q.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Q.border),
                ),
                child: Row(
                  children: List.generate(ps.length, (i) {
                    final on = i == tab;
                    return Expanded(
                      child: Semantics(
                        selected: on,
                        button: true,
                        child: GestureDetector(
                          onTap: () => cubit.selectTab(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: on ? Q.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: on
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x662F6BFF),
                                        blurRadius: 14,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              ps[i].title,
                              style: body(
                                13,
                                color: on ? Colors.white : Q.text2,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ps.isEmpty
                    ? const SizedBox()
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 20),
                        children: [
                          Text(
                            'Last updated ${ps[tab].updated}',
                            style: body(12, color: Q.text3),
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(ps[tab].sections.length, (i) {
                            final s = ps[tab].sections[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Panel(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (i + 1).toString().padLeft(2, '0'),
                                      style: display(13, color: Q.pinkSoft),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.heading,
                                            style: body(
                                              15,
                                              weight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            s.body,
                                            style: body(
                                              13,
                                              color: Q.text2,
                                              height: 1.55,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Questions?',
                                style: body(13, color: Q.text3),
                              ),
                              TextLink(
                                'Contact support',
                                size: 13,
                                onTap: () => context.goSupport(),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
