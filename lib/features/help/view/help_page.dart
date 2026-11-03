import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/repositories/support_repository.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/help_cubit.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => HelpCubit(ctx.read<SupportRepository>())..load(),
    child: const _HelpView(),
  );
}

class _HelpView extends StatelessWidget {
  const _HelpView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HelpCubit>();
    final state = context.watch<HelpCubit>().state;
    final list = state.visible;
    return QBackground(
      hero: const QHeroImage(QPhoto.streaks, height: 280, opacity: 0.7),
      child: state.error != null && state.faqs == null
          ? ErrorView(error: state.error!, onRetry: cubit.load)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              children: [
                Text('HELP & FAQ', style: display(20)),
                const SizedBox(height: 14),
                Semantics(
                  label: 'Search help',
                  child: TextField(
                    onChanged: cubit.search,
                    style: body(15),
                    decoration: const InputDecoration(
                      hintText: 'Search questions',
                      prefixIcon: Icon(Icons.search_rounded, color: Q.text3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (state.faqs == null)
                  const SizedBox(height: 200, child: LoadingView())
                else if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No answers match “${state.query}”',
                      textAlign: TextAlign.center,
                      style: body(14, color: Q.text3),
                    ),
                  ),
                ...List.generate(list.length, (i) {
                  final f = list[i];
                  final o = f.id == state.openId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Q.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: o ? Q.primary : Q.border),
                        boxShadow: o
                            ? const [
                                BoxShadow(
                                  color: Color(0x332F6BFF),
                                  blurRadius: 16,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            button: true,
                            expanded: o,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => cubit.toggle(f.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      child: Text(
                                        (i + 1).toString().padLeft(2, '0'),
                                        style: display(
                                          11,
                                          color: o ? Q.link : Q.muted,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        f.question,
                                        style: body(
                                          14,
                                          weight: FontWeight.w700,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    AnimatedRotation(
                                      turns: o ? 0.5 : 0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: const Icon(
                                        Icons.expand_more_rounded,
                                        color: Q.text3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (o)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(42, 0, 14, 14),
                              child: Text(
                                f.answer,
                                style: body(13, color: Q.text2, height: 1.55),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 6),
                Material(
                  color: Q.surfaceHi,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Q.primaryMid),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.go(Routes.support),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Q.link,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Still stuck? Talk to the desk',
                              style: body(
                                14,
                                color: Q.link,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Q.link,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
