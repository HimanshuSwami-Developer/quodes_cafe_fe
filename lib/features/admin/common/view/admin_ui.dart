import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/admin_models.dart';
import '../../../../data/models/models.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/theme.dart';
import '../../../../theme/widgets.dart';
import '../bloc/save_cubit.dart';

// Shared building blocks for the staff admin panel (web, desktop-first).

/// `₹1,250` style amount.
String inr(double v) => '₹${rupees(v)}';

/// `03 Nov, 4:05 PM` (or `—`).
String adminDateTime(DateTime? t) =>
    t == null ? '—' : DateFormat('dd MMM, h:mm a').format(t);

/// `03 Nov 2026` (or `—`).
String adminDate(DateTime? t) =>
    t == null ? '—' : DateFormat('dd MMM yyyy').format(t);

/// `YYYY-MM-DD` for API date filters.
String apiDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// Opens [url] in a new browser tab.
Future<void> openUrl(String url) =>
    launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');

/// Page frame inside the admin shell: title row with actions, then content.
class AdminPage extends StatelessWidget {
  /// Creates a page; [child] fills the remaining height.
  const AdminPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: display(24, weight: FontWeight.w700)),
                    if (subtitle != null)
                      Text(subtitle!, style: body(13, color: Q.text3)),
                  ],
                ),
              ],
            ),
            if (actions.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(child: child),
      ],
    ),
  );
}

/// Surface card used for sections of admin pages.
class AdminCard extends StatelessWidget {
  /// Creates a card with an optional [title] row.
  const AdminCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Panel(
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  title!,
                  style: display(16, weight: FontWeight.w600),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
        ],
        child,
      ],
    ),
  );
}

/// Compact filled button for desktop admin screens.
class AdminButton extends StatelessWidget {
  /// Creates a filled button; [loading] shows a spinner and disables it.
  const AdminButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color = Q.primary,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: loading ? null : onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Q.surfaceLo,
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: body(14, weight: FontWeight.w800),
    ),
    icon: loading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : (icon == null ? const SizedBox.shrink() : Icon(icon, size: 18)),
    label: Text(label),
  );
}

/// Outlined secondary button.
class AdminOutlineButton extends StatelessWidget {
  /// Creates an outlined button.
  const AdminOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color = Q.text,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      side: const BorderSide(color: Q.borderHi),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: body(14, weight: FontWeight.w700),
    ),
    icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
    label: Text(label),
  );
}

/// Labelled text input that shows a server field error underneath.
class AdminField extends StatelessWidget {
  /// Creates a field bound to [controller].
  const AdminField({
    super.key,
    required this.label,
    required this.controller,
    this.error,
    this.hint,
    this.maxLines = 1,
    this.keyboard,
    this.mono = false,
    this.prefix,
    this.suffix,
    this.digitsOnly = false,
    this.decimal = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final String? error, hint, prefix;
  final Widget? suffix;
  final int maxLines;
  final TextInputType? keyboard;

  /// Monospace text (codes, UPI ids).
  final bool mono;

  /// Only 0-9 may be typed.
  final bool digitsOnly;

  /// Digits and one decimal point.
  final bool decimal;
  final bool enabled, autofocus;
  final ValueChanged<String>? onChanged, onSubmitted;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      FieldLabel(label),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        enabled: enabled,
        autofocus: autofocus,
        maxLines: maxLines,
        minLines: 1,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType:
            keyboard ??
            (digitsOnly
                ? TextInputType.number
                : decimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : null),
        inputFormatters: [
          if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
          if (decimal) FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        style: mono
            ? const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Q.text,
              )
            : body(14),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          errorText: error,
          errorMaxLines: 3,
          prefixText: prefix,
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    ],
  );
}

/// Red banner for a form-level error (no input shows it).
class FormErrorBanner extends StatelessWidget {
  /// Shows [message]; renders nothing when it is null.
  const FormErrorBanner(this.message, {super.key});
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Q.redBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Q.redBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Q.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message!, style: body(13, color: Q.redText)),
          ),
        ],
      ),
    );
  }
}

/// Dialog frame for admin forms: title, scrollable body, Cancel / Save.
class AdminFormDialog extends StatelessWidget {
  /// Creates a dialog; [onSave] null disables Save.
  const AdminFormDialog({
    super.key,
    required this.title,
    required this.child,
    required this.onSave,
    this.saving = false,
    this.saveLabel = 'Save',
    this.width = 560,
    this.error,
  });

  final String title;
  final Widget child;
  final VoidCallback? onSave;
  final bool saving;
  final String saveLabel;
  final double width;

  /// Form-level error shown above the fields.
  final String? error;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Q.surface,
    insetPadding: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Q.border),
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: 760),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: display(20, weight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Q.text3),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [FormErrorBanner(error), child],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: body(14, color: Q.text2)),
                ),
                const SizedBox(width: 8),
                AdminButton(
                  label: saveLabel,
                  icon: Icons.check_rounded,
                  loading: saving,
                  onPressed: onSave,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Helper for form dialogs: the message of [state] that no field shows.
String? formError<T>(SaveState<T> state, Iterable<String> fields) =>
    state.status.isFailure ? state.formMessage(fields) : null;

/// Asks to confirm a (destructive) action. Resolves true on confirm.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  bool destructive = true,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: Q.surface,
      title: Text(title, style: display(20, weight: FontWeight.w700)),
      content: Text(message, style: body(14, color: Q.text2)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(c).pop(false),
          child: Text('Cancel', style: body(14, color: Q.text2)),
        ),
        AdminButton(
          label: confirmLabel,
          color: destructive ? const Color(0xFFD9364F) : Q.primary,
          onPressed: () => Navigator.of(c).pop(true),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Toasts [e]'s message (for row actions).
void showApiError(BuildContext context, ApiException? e) {
  if (e != null) showError(context, e);
}

/// Loading / error-with-retry / empty / content switch for lists.
class AdminAsync<T> extends StatelessWidget {
  /// Chooses what to show from [status] and [items].
  const AdminAsync({
    super.key,
    required this.status,
    required this.items,
    required this.error,
    required this.onRetry,
    required this.builder,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyText = 'Nothing here yet.',
  });

  final LoadStatus status;
  final List<T>? items;
  final ApiException? error;
  final VoidCallback onRetry;
  final Widget Function(List<T> items) builder;
  final IconData emptyIcon;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final list = items;
    if (list == null || (status.isLoading && list.isEmpty)) {
      if (status.isFailure) {
        return ErrorView(error: error ?? 'Failed to load', onRetry: onRetry);
      }
      return const LoadingView();
    }
    if (status.isFailure && error != null) {
      return ErrorView(error: error!, onRetry: onRetry);
    }
    if (list.isEmpty) return AdminEmpty(icon: emptyIcon, text: emptyText);
    return builder(list);
  }
}

/// Empty-state placeholder.
class AdminEmpty extends StatelessWidget {
  /// Creates an empty state with an icon and message.
  const AdminEmpty({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.text = 'Nothing here yet.',
  });
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Q.text3),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: body(14, color: Q.text3),
          ),
        ],
      ),
    ),
  );
}

/// Colour-coded booking status chip.
class StatusPill extends StatelessWidget {
  /// Creates a pill for booking/ticket [status] (label optional).
  const StatusPill(this.status, {super.key, this.label});
  final String status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, bd) = switch (status) {
      'confirmed' || 'resolved' => (Q.greenText, Q.greenBg, Q.greenBorder),
      'pending_human' ||
      'scanning' ||
      'in_review' => (Q.amberText, Q.amberBg, Q.amberBorder),
      'ai_failed' || 'rejected' => (Q.redText, Q.redBg, Q.redBorder),
      'locked' || 'open' => (Q.linkHi, Q.surfaceHi, Q.primaryMid),
      _ => (Q.text3, Q.surfaceLo, Q.border),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bd),
      ),
      child: Text(
        label ?? bookingStatusLabels[status] ?? ticketStatusLabel(status),
        style: body(12, color: fg, weight: FontWeight.w800),
      ),
    );
  }
}

/// Small rounded count badge (sidebar, tabs).
class CountBadge extends StatelessWidget {
  /// Hidden when [count] is 0.
  const CountBadge(this.count, {super.key, this.color = Q.pink});
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: body(12, color: Colors.white, weight: FontWeight.w800),
      ),
    );
  }
}

/// Live "minutes left until the verify deadline" (red under 30 min).
class VerifyCountdown extends StatefulWidget {
  /// Ticks every 15 seconds using the server-corrected clock.
  const VerifyCountdown(this.booking, {super.key, this.size = 13});
  final Booking booking;
  final double size;

  @override
  State<VerifyCountdown> createState() => _VerifyCountdownState();
}

class _VerifyCountdownState extends State<VerifyCountdown> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    if (b.verifyDeadline == null) {
      return Text('—', style: body(widget.size, color: Q.text3));
    }
    final mins = b.verifyLeft.inMinutes;
    final overdue = b.verifyLeft == Duration.zero;
    final urgent = mins < 30;
    final text = overdue
        ? 'Overdue'
        : mins >= 60
        ? '${mins ~/ 60}h ${mins % 60}m left'
        : '$mins min left';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer_outlined,
          size: widget.size + 2,
          color: urgent ? Q.red : Q.text3,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: body(
            widget.size,
            color: urgent ? Q.red : Q.text2,
            weight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// AI screenshot checks with pass / fail / pending icons.
class AiChecksView extends StatelessWidget {
  /// Lists [checks] and the overall [message].
  const AiChecksView({super.key, required this.checks, this.message = ''});
  final List<AiCheck> checks;
  final String message;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (checks.isEmpty)
        Text('No AI checks recorded.', style: body(13, color: Q.text3)),
      for (final c in checks)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                switch (c.status) {
                  'pass' => Icons.check_circle_rounded,
                  'fail' => Icons.cancel_rounded,
                  _ => Icons.schedule_rounded,
                },
                size: 16,
                color: switch (c.status) {
                  'pass' => Q.green,
                  'fail' => Q.red,
                  _ => Q.amber,
                },
                semanticLabel: c.status,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: c.label.isEmpty ? c.key : c.label,
                        style: body(13, weight: FontWeight.w700),
                      ),
                      if (c.detail.isNotEmpty)
                        TextSpan(
                          text: '  ${c.detail}',
                          style: body(13, color: Q.text3),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      if (message.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(message, style: body(13, color: Q.text2)),
      ],
    ],
  );
}

/// Screenshot thumbnail; tap opens a zoomable viewer.
class ScreenshotThumb extends StatelessWidget {
  /// Shows [url] at [width] x [height]; a placeholder when null.
  const ScreenshotThumb(
    this.url, {
    super.key,
    this.width = 96,
    this.height = 128,
  });
  final String? url;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final u = url;
    final box = BoxDecoration(
      color: Q.surfaceLo,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Q.border),
    );
    if (u == null || u.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: box,
        alignment: Alignment.center,
        child: Text(
          'No\nscreenshot',
          textAlign: TextAlign.center,
          style: body(11, color: Q.text3),
        ),
      );
    }
    return Semantics(
      button: true,
      label: 'Open payment screenshot',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => showScreenshot(context, u),
        child: Container(
          width: width,
          height: height,
          decoration: box,
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            u,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.broken_image_outlined, color: Q.text3),
          ),
        ),
      ),
    );
  }
}

/// Full-size, pinch/scroll-zoomable screenshot viewer.
Future<void> showScreenshot(BuildContext context, String url) => showDialog(
  context: context,
  builder: (c) => Dialog(
    backgroundColor: Q.bg,
    insetPadding: const EdgeInsets.all(24),
    child: Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 6,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Text(
                  'Could not load the screenshot.',
                  style: body(14, color: Q.text3),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Open in new tab',
                onPressed: () => openUrl(url),
                icon: const Icon(Icons.open_in_new_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Close',
                onPressed: () => Navigator.of(c).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);

/// Asks for an optional rejection note. Resolves null when cancelled.
Future<String?> askRejectNote(BuildContext context, {String code = ''}) {
  final note = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: Q.surface,
      title: Text(
        code.isEmpty ? 'Reject payment' : 'Reject $code',
        style: display(20, weight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'The slot is released and the player is emailed. '
              'Leave the note empty to use the default message.',
              style: body(13, color: Q.text3),
            ),
            const SizedBox(height: 12),
            AdminField(
              label: 'Note to player (optional)',
              controller: note,
              hint: 'Payment not found in bank records',
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(c).pop(),
          child: Text('Cancel', style: body(14, color: Q.text2)),
        ),
        AdminButton(
          label: 'Reject',
          icon: Icons.block_rounded,
          color: const Color(0xFFD9364F),
          onPressed: () => Navigator.of(c).pop(note.text.trim()),
        ),
      ],
    ),
  ).whenComplete(note.dispose);
}

/// Horizontally scrollable, themed [DataTable].
class AdminTable extends StatelessWidget {
  /// Wraps a DataTable with the admin look.
  const AdminTable({super.key, required this.columns, required this.rows});
  final List<DataColumn> columns;
  final List<DataRow> rows;

  @override
  Widget build(BuildContext context) => Panel(
    padding: EdgeInsets.zero,
    child: LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: c.maxWidth),
          child: DataTable(
            showCheckboxColumn: false,
            headingRowHeight: 44,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 64,
            columnSpacing: 24,
            headingTextStyle: label(11),
            dataTextStyle: body(14),
            dividerThickness: 0.6,
            headingRowColor: const WidgetStatePropertyAll(Q.surfaceLo),
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    ),
  );
}

/// Tappable row for [AdminTable]: highlights on hover.
DataRow adminRow({
  required List<DataCell> cells,
  VoidCallback? onTap,
  LocalKey? key,
}) => DataRow(
  key: key,
  onSelectChanged: onTap == null ? null : (_) => onTap(),
  color: WidgetStateProperty.resolveWith(
    (s) => s.contains(WidgetState.hovered) ? Q.surfaceHi : null,
  ),
  cells: cells,
);
