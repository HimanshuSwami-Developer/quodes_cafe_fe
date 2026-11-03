/// Pure input rules shared by cubits and views.
abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _utr = RegExp(r'^\d{12}$');

  static bool isEmail(String v) => _email.hasMatch(v.trim());

  /// UPI reference (UTR) is optional; when given it must be 12 digits.
  static bool isValidUtr(String v) => v.isEmpty || _utr.hasMatch(v);

  static const maxScreenshotBytes = 5 * 1024 * 1024;
  static const otpLength = 6;

  /// Strength rules shown under "new password" (label, passed).
  static List<(String, bool)> passwordRules(String pw) => [
    ('8+ characters', pw.length >= 8),
    ('One uppercase', RegExp(r'[A-Z]').hasMatch(pw)),
    ('One number', RegExp(r'\d').hasMatch(pw)),
    ('One symbol', RegExp(r'[^A-Za-z0-9]').hasMatch(pw)),
  ];

  static int passwordScore(String pw) =>
      passwordRules(pw).where((r) => r.$2).length;
}
