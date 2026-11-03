import '../../data/models/models.dart';

/// Every path in the app. Use these, never string literals.
abstract final class Routes {
  static const splash = '/';

  // Public
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email'; // extra: CodeSent
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password'; // extra: CodeSent
  static const policies = '/policies';

  // Tabs (StatefulShellRoute branches, same order as NavTab)
  static const games = '/games';
  static const help = '/help';
  static const support = '/support'; // ?topic=Refund&booking=QG-XXXX
  static const profile = '/profile';

  // Booking flow (state lives in the app-wide BookingFlowCubit)
  static const station = '/book/station';
  static const availability = '/book/availability';
  static const slots = '/book/slots';

  // One booking: /bookings/:id/<step>   (extra: Booking, optional)
  static const bookingStep = '/bookings/:id/:step';
  static String booking(int id, BookingStep step) =>
      '/bookings/$id/${step.name}';

  // ---- Staff admin panel (web) ----
  static const admin = '/admin'; // dashboard
  static const adminLogin = '/admin/login'; // ?from=/admin/...  ?denied=1
  static const adminVerify = '/admin/verify';
  static const adminBookings = '/admin/bookings';
  static const adminBooking = '/admin/bookings/:id';
  static String adminBookingOf(int id) => '/admin/bookings/$id';
  static const adminTickets = '/admin/tickets';
  static const adminGames = '/admin/games';
  static const adminStations = '/admin/stations';
  static const adminPlayers = '/admin/players';
  static const adminFaqs = '/admin/faqs';
  static const adminPolicies = '/admin/policies';
  static const adminSettings = '/admin/settings';

  static bool isAdmin(String location) =>
      location == admin || location.startsWith('$admin/');

  static const publicPaths = {
    login,
    register,
    verifyEmail,
    forgotPassword,
    resetPassword,
    policies,
  };

  /// Signed-in players are bounced away from these.
  static const authOnlyEntry = {
    splash,
    login,
    register,
    verifyEmail,
    forgotPassword,
    resetPassword,
  };
}

/// Screens a single booking can be on.
enum BookingStep {
  hold,
  pay,
  upload,
  verifying,
  pending,
  approved,
  failed,
  released,
}

extension BookingRouting on Booking {
  /// The screen that matches the booking's server status (null = terminal,
  /// e.g. expired/cancelled/rejected: show a message and go to games).
  BookingStep? get defaultStep => switch (status) {
    'locked' => BookingStep.hold,
    'scanning' => BookingStep.verifying,
    'ai_failed' => BookingStep.failed,
    'pending_human' => BookingStep.pending,
    'confirmed' => BookingStep.approved,
    'released' => BookingStep.released,
    _ => null,
  };

  /// Steps that may legitimately show this status (pay/upload are reached
  /// manually from hold while still `locked`, upload also from `ai_failed`).
  bool allows(BookingStep step) => switch (step) {
    BookingStep.hold || BookingStep.pay => status == 'locked',
    BookingStep.upload => status == 'locked' || status == 'ai_failed',
    _ => defaultStep == step,
  };
}
