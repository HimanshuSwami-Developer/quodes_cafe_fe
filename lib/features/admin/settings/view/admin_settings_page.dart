import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../theme/widgets.dart';
import '../../common/view/admin_ui.dart';
import '../bloc/admin_settings_cubit.dart';

/// Café-wide settings: hours, UPI details, timers, support contact.
class AdminSettingsPage extends StatelessWidget {
  /// Creates the page.
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => AdminSettingsCubit(ctx.read<AdminRepository>())..load(),
    child: const _SettingsView(),
  );
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();
  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  /// One controller per API key.
  final _c = {
    for (final k in const [
      'name',
      'support_phone',
      'maps_url',
      'open_hour',
      'close_hour',
      'booking_days_ahead',
      'upi_id',
      'upi_payee',
      'lock_minutes',
      'verify_hours',
      'reply_minutes',
    ])
      k: TextEditingController(),
  };

  CafeSettings? _filledFrom;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(CafeSettings s) {
    _filledFrom = s;
    final j = s.toJson();
    for (final e in _c.entries) {
      e.value.text = '${j[e.key] ?? ''}';
    }
  }

  int _int(String k) => int.tryParse(_c[k]!.text.trim()) ?? 0;
  String _str(String k) => _c[k]!.text.trim();

  void _save() => context.read<AdminSettingsCubit>().save(
    CafeSettings(
      name: _str('name'),
      openHour: _int('open_hour'),
      closeHour: _int('close_hour'),
      upiId: _str('upi_id'),
      upiPayee: _str('upi_payee'),
      lockMinutes: _int('lock_minutes'),
      verifyHours: _int('verify_hours'),
      supportPhone: _str('support_phone'),
      mapsUrl: _str('maps_url'),
      replyMinutes: _int('reply_minutes'),
      bookingDaysAhead: _int('booking_days_ahead'),
    ),
  );

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<AdminSettingsCubit, AdminSettingsState>(
        listenWhen: (a, b) =>
            a.settings != b.settings || a.saveStatus != b.saveStatus,
        listener: (context, s) {
          if (s.settings != null && s.settings != _filledFrom) {
            _fill(s.settings!);
          }
          if (s.saveStatus.isSuccess) {
            showToast(context, 'Settings saved');
          } else if (s.saveStatus.isFailure && s.saveError != null) {
            showError(context, s.saveError!);
          }
        },
        builder: (context, s) {
          final cubit = context.read<AdminSettingsCubit>();
          return AdminPage(
            title: 'Settings',
            subtitle: 'Café-wide settings players see and booking timers.',
            actions: [
              if (s.settings != null)
                AdminButton(
                  label: 'Save settings',
                  icon: Icons.save_outlined,
                  loading: s.saveStatus.isLoading,
                  onPressed: _save,
                ),
            ],
            child: switch (s.status) {
              LoadStatus.failure when s.settings == null => ErrorView(
                error: s.error ?? 'Failed to load',
                onRetry: cubit.load,
              ),
              _ when s.settings == null => const LoadingView(),
              _ => _form(s),
            },
          );
        },
      );

  Widget _field(
    AdminSettingsState s,
    String key,
    String label, {
    bool digits = false,
    bool mono = false,
    String? hint,
    String? suffix,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: AdminField(
      label: label,
      controller: _c[key]!,
      error: s.fieldErrors[key],
      digitsOnly: digits,
      mono: mono,
      hint: hint,
      suffix: suffix == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 12, top: 12),
              child: Text(suffix),
            ),
    ),
  );

  /// Two fields side by side on wide cards, stacked on narrow ones.
  Widget _pair(Widget a, Widget b) => LayoutBuilder(
    builder: (_, c) => c.maxWidth < 360
        ? Column(children: [a, b])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 12),
              Expanded(child: b),
            ],
          ),
  );

  Widget _form(AdminSettingsState s) {
    final cafe = AdminCard(
      title: 'Café',
      child: Column(
        children: [
          _field(s, 'name', 'Café name'),
          _field(s, 'support_phone', 'Support phone', hint: '+91 98765 43210'),
          _field(
            s,
            'maps_url',
            'Google Maps URL',
            hint: 'https://maps.app.goo.gl/...',
          ),
        ],
      ),
    );
    final hours = AdminCard(
      title: 'Hours',
      child: Column(
        children: [
          _pair(
            _field(s, 'open_hour', 'Open hour (0-23)', digits: true),
            _field(s, 'close_hour', 'Close hour (1-24)', digits: true),
          ),
          _field(
            s,
            'booking_days_ahead',
            'Booking days ahead',
            digits: true,
            suffix: 'days',
          ),
        ],
      ),
    );
    final payments = AdminCard(
      title: 'Payments',
      child: Column(
        children: [
          _field(s, 'upi_id', 'UPI ID', mono: true, hint: 'quodes@upi'),
          _field(s, 'upi_payee', 'Payee name'),
          _pair(
            _field(s, 'lock_minutes', 'Slot lock', digits: true, suffix: 'min'),
            _field(
              s,
              'verify_hours',
              'Verify within',
              digits: true,
              suffix: 'hours',
            ),
          ),
        ],
      ),
    );
    final support = AdminCard(
      title: 'Support',
      child: _field(
        s,
        'reply_minutes',
        'Typical reply time',
        digits: true,
        suffix: 'min',
      ),
    );
    final banner = FormErrorBanner(
      s.saveStatus.isFailure && s.fieldErrors.isEmpty
          ? s.saveError?.message
          : null,
    );

    return LayoutBuilder(
      builder: (context, c) {
        const gap = SizedBox(height: 16, width: 16);
        final wide = c.maxWidth >= 900;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              banner,
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(children: [cafe, gap, support])),
                    gap,
                    Expanded(child: Column(children: [hours, gap, payments])),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [cafe, gap, hours, gap, payments, gap, support],
                ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: AdminButton(
                  label: 'Save settings',
                  icon: Icons.save_outlined,
                  loading: s.saveStatus.isLoading,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
