import 'dart:async';

/// Seconds-left countdown for "Resend code" buttons. Owned by a cubit.
class ResendCountdown {
  ResendCountdown(this._onTick);
  final void Function(int left) _onTick;
  Timer? _timer;

  void start(int seconds) {
    _timer?.cancel();
    var left = seconds;
    _onTick(left);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      left -= 1;
      _onTick(left < 0 ? 0 : left);
      if (left <= 0) t.cancel();
    });
  }

  void dispose() => _timer?.cancel();
}
