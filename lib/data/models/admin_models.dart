// Typed models for the staff API (`/api/admin/...`). See
// backend/staff/serializers.py for the source of truth.

import 'package:equatable/equatable.dart';

import 'models.dart';

double _d(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _i(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? ''}') ?? fallback;
}

DateTime? _dt(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};

List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
    (v as List? ?? const []).map((e) => f(_map(e))).toList();

/// Money as the API wants it on write (`"150.00"`).
String _money(double v) => v.toStringAsFixed(2);

/// The player summary attached to staff bookings.
class AdminPlayerRef extends Equatable {
  const AdminPlayerRef({
    required this.id,
    this.email = '',
    this.gamertag = '',
    this.fullName = '',
    this.phone = '',
    this.credit = 0,
  });

  AdminPlayerRef.fromJson(Map<String, dynamic> j)
    : id = _i(j['id']),
      email = j['email'] ?? '',
      gamertag = j['gamertag'] ?? '',
      fullName = j['full_name'] ?? '',
      phone = j['phone'] ?? '',
      credit = _d(j['credit']);

  final int id;
  final String email, gamertag, fullName, phone;
  final double credit;

  /// Best short name to show in tables.
  String get display =>
      gamertag.isNotEmpty ? gamertag : (fullName.isNotEmpty ? fullName : email);

  @override
  List<Object?> get props => [id, email, gamertag, fullName, phone, credit];
}

/// A player [Booking] plus the staff-only fields.
class StaffBooking extends Equatable {
  StaffBooking.fromJson(Map<String, dynamic> j)
    : booking = Booking.fromJson(j),
      player = AdminPlayerRef.fromJson(_map(j['player'])),
      screenshotUrl = j['screenshot_url'] as String?,
      aiRaw = j['ai_raw'] is Map ? _map(j['ai_raw']) : null,
      staffNote = j['staff_note'] ?? '',
      reviewedBy = j['reviewed_by'] as String?,
      rebookedFrom = j['rebooked_from'] == null ? null : _i(j['rebooked_from']);

  final Booking booking;
  final AdminPlayerRef player;

  /// Absolute URL of the payment screenshot, if one was uploaded.
  final String? screenshotUrl;

  /// What the AI read from the screenshot (free-form key/values).
  final Map<String, dynamic>? aiRaw;
  final String staffNote;

  /// Email of the staff member who approved/rejected it.
  final String? reviewedBy;

  /// Id of the booking this one was re-booked from.
  final int? rebookedFrom;

  int get id => booking.id;
  String get code => booking.code;
  String get status => booking.status;

  /// Staff can act on payments waiting for a human.
  bool get canReview =>
      const {'pending_human', 'ai_failed', 'scanning'}.contains(booking.status);

  @override
  List<Object?> get props => [
    booking.id,
    booking.status,
    booking.verifyDeadline,
    booking.utr,
    player,
    screenshotUrl,
    staffNote,
    reviewedBy,
  ];
}

/// Headline numbers on the dashboard (also drive the sidebar badges).
class DashboardKpis extends Equatable {
  const DashboardKpis({
    this.toVerify = 0,
    this.sessionsToday = 0,
    this.revenueToday = 0,
    this.liveLocks = 0,
    this.openTickets = 0,
    this.players = 0,
  });

  DashboardKpis.fromJson(Map<String, dynamic> j)
    : toVerify = _i(j['to_verify']),
      sessionsToday = _i(j['sessions_today']),
      revenueToday = _d(j['revenue_today']),
      liveLocks = _i(j['live_locks']),
      openTickets = _i(j['open_tickets']),
      players = _i(j['players']);

  final int toVerify, sessionsToday, liveLocks, openTickets, players;
  final double revenueToday;

  @override
  List<Object?> get props => [
    toVerify,
    sessionsToday,
    revenueToday,
    liveLocks,
    openTickets,
    players,
  ];
}

/// `GET admin/dashboard/`.
class AdminDashboard extends Equatable {
  AdminDashboard.fromJson(Map<String, dynamic> j)
    : kpis = DashboardKpis.fromJson(_map(j['kpis'])),
      queue = _list(j['queue'], StaffBooking.fromJson),
      today = _list(j['today'], StaffBooking.fromJson),
      serverTime = _dt(j['server_time']);

  final DashboardKpis kpis;

  /// Payments waiting for a human, oldest deadline first.
  final List<StaffBooking> queue;

  /// Confirmed + pending sessions for today, by start hour.
  final List<StaffBooking> today;
  final DateTime? serverTime;

  @override
  List<Object?> get props => [kpis, queue, today, serverTime];
}

/// Genres the backend accepts (catalog.models.Game.GENRES).
const adminGenres = [
  'SHOOTER',
  'SPORTS',
  'RACING',
  'FIGHTING',
  'OPEN WORLD',
  'ACTION',
];

/// A game as staff edit it.
class AdminGame extends Equatable {
  const AdminGame({
    this.id = 0,
    this.name = '',
    this.mono = '',
    this.genre = 'ACTION',
    this.hue = '#2F6BFF',
    this.deep = '#111C42',
    this.platforms = const [],
    this.maxPlayers = 4,
    this.isActive = true,
    this.sort = 0,
  });

  AdminGame.fromJson(Map<String, dynamic> j)
    : id = _i(j['id']),
      name = j['name'] ?? '',
      mono = j['mono'] ?? '',
      genre = j['genre'] ?? 'ACTION',
      hue = j['hue'] ?? '#2F6BFF',
      deep = j['deep'] ?? '#111C42',
      platforms = List<String>.from(j['platforms'] ?? const []),
      maxPlayers = _i(j['max_players'], 4),
      isActive = j['is_active'] ?? true,
      sort = _i(j['sort']);

  /// 0 for a game not saved yet.
  final int id;
  final String name, mono, genre, hue, deep;

  /// Station type codes (PS5 / PS4 / PC).
  final List<String> platforms;
  final int maxPlayers, sort;
  final bool isActive;

  bool get isNew => id == 0;

  Map<String, dynamic> toJson() => {
    'name': name,
    'mono': mono,
    'genre': genre,
    'hue': hue,
    'deep': deep,
    'platforms': platforms,
    'max_players': maxPlayers,
    'is_active': isActive,
    'sort': sort,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    mono,
    genre,
    hue,
    deep,
    platforms,
    maxPlayers,
    isActive,
    sort,
  ];
}

/// A station type (PS5 / PS4 / PC) with its pricing.
class AdminStationType extends Equatable {
  const AdminStationType({
    this.id = 0,
    this.code = '',
    this.name = '',
    this.spec = '',
    this.seatsPerStation = 2,
    this.hourlyRate = 100,
    this.seatPrefix = '',
    this.gridCols = 3,
    this.sort = 0,
    this.stationCount = 0,
  });

  AdminStationType.fromJson(Map<String, dynamic> j)
    : id = _i(j['id']),
      code = j['code'] ?? '',
      name = j['name'] ?? '',
      spec = j['spec'] ?? '',
      seatsPerStation = _i(j['seats_per_station'], 1),
      hourlyRate = _d(j['hourly_rate']),
      seatPrefix = j['seat_prefix'] ?? '',
      gridCols = _i(j['grid_cols'], 3),
      sort = _i(j['sort']),
      stationCount = _i(j['station_count']);

  final int id;
  final String code, name, spec, seatPrefix;
  final int seatsPerStation, gridCols, sort;

  /// ₹ per seat per hour.
  final double hourlyRate;

  /// Active stations of this type (read-only).
  final int stationCount;

  bool get isNew => id == 0;

  AdminStationType copyWith({
    String? name,
    String? spec,
    int? seatsPerStation,
    double? hourlyRate,
    int? sort,
    int? stationCount,
  }) => AdminStationType(
    id: id,
    code: code,
    name: name ?? this.name,
    spec: spec ?? this.spec,
    seatsPerStation: seatsPerStation ?? this.seatsPerStation,
    hourlyRate: hourlyRate ?? this.hourlyRate,
    seatPrefix: seatPrefix,
    gridCols: gridCols,
    sort: sort ?? this.sort,
    stationCount: stationCount ?? this.stationCount,
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'spec': spec,
    'seats_per_station': seatsPerStation,
    'hourly_rate': _money(hourlyRate),
    'seat_prefix': seatPrefix,
    'grid_cols': gridCols,
    'sort': sort,
  };

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    spec,
    seatsPerStation,
    hourlyRate,
    seatPrefix,
    gridCols,
    sort,
    stationCount,
  ];
}

/// One physical station (its seats are created by the server).
class AdminStation extends Equatable {
  const AdminStation({
    required this.id,
    required this.type,
    this.typeCode = '',
    this.typeName = '',
    required this.number,
    this.code = '',
    this.isActive = true,
    this.seatCount = 0,
  });

  AdminStation.fromJson(Map<String, dynamic> j)
    : id = _i(j['id']),
      type = _i(j['type']),
      typeCode = j['type_code'] ?? '',
      typeName = j['type_name'] ?? '',
      number = _i(j['number']),
      code = j['code'] ?? '',
      isActive = j['is_active'] ?? true,
      seatCount = _i(j['seat_count']);

  final int id;

  /// Station type id.
  final int type;
  final String typeCode, typeName, code;
  final int number, seatCount;
  final bool isActive;

  @override
  List<Object?> get props => [id, type, number, code, isActive, seatCount];
}

/// FAQ entry shown on the player Help tab.
class AdminFaq extends Equatable {
  const AdminFaq({
    this.id = 0,
    this.question = '',
    this.answer = '',
    this.sort = 0,
  });

  AdminFaq.fromJson(Map<String, dynamic> j)
    : id = _i(j['id']),
      question = j['question'] ?? '',
      answer = j['answer'] ?? '',
      sort = _i(j['sort']);

  final int id;
  final String question, answer;
  final int sort;

  bool get isNew => id == 0;

  Map<String, dynamic> toJson() => {
    'question': question,
    'answer': answer,
    'sort': sort,
  };

  @override
  List<Object?> get props => [id, question, answer, sort];
}

/// One heading + body inside a policy.
class AdminPolicySection extends Equatable {
  const AdminPolicySection({this.heading = '', this.body = '', this.sort = 0});

  AdminPolicySection.fromJson(Map<String, dynamic> j)
    : heading = j['heading'] ?? '',
      body = j['body'] ?? '',
      sort = _i(j['sort']);

  final String heading, body;
  final int sort;

  Map<String, dynamic> toJson() => {
    'heading': heading,
    'body': body,
    'sort': sort,
  };

  @override
  List<Object?> get props => [heading, body, sort];
}

/// A policy page (house rules, refunds, privacy...).
class AdminPolicy extends Equatable {
  const AdminPolicy({
    this.id = 0,
    this.key = '',
    this.title = '',
    this.sort = 0,
    this.updated = '',
    this.sections = const [],
  });

  AdminPolicy.fromJson(Map<String, dynamic> j)
    : id = _i(j['id']),
      key = j['key'] ?? '',
      title = j['title'] ?? '',
      sort = _i(j['sort']),
      updated = j['updated'] ?? '',
      sections = _list(j['sections'], AdminPolicySection.fromJson);

  final int id;
  final String key, title;
  final int sort;

  /// Last edit date (read-only, `YYYY-MM-DD`).
  final String updated;
  final List<AdminPolicySection> sections;

  bool get isNew => id == 0;

  /// Sections are sent in list order; the server replaces them all.
  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'sort': sort,
    'sections': [
      for (var i = 0; i < sections.length; i++)
        {'heading': sections[i].heading, 'body': sections[i].body, 'sort': i},
    ],
  };

  @override
  List<Object?> get props => [id, key, title, sort, updated, sections];
}

/// Ticket statuses, in tab order.
const ticketStatuses = ['open', 'in_review', 'resolved'];

/// Human label for a ticket status code.
String ticketStatusLabel(String s) => switch (s) {
  'open' => 'Open',
  'in_review' => 'In review',
  'resolved' => 'Resolved',
  _ => s,
};

/// A support ticket as staff see it.
class AdminTicket extends Equatable {
  AdminTicket.fromJson(Map<String, dynamic> j)
    : id = _i(j['id']),
      number = '${j['number'] ?? ''}',
      player = AdminPlayerRef.fromJson(_map(j['player'])),
      topic = j['topic'] ?? '',
      bookingCode = j['booking_code'] ?? '',
      message = j['message'] ?? '',
      attachmentUrl = j['attachment_url'] as String?,
      status = j['status'] ?? 'open',
      statusLabel = j['status_label'] ?? '',
      staffReply = j['staff_reply'] ?? '',
      createdAt = _dt(j['created_at']),
      updatedAt = _dt(j['updated_at']);

  final int id;
  final String number, topic, bookingCode, message, status, statusLabel;
  final String staffReply;
  final AdminPlayerRef player;
  final String? attachmentUrl;
  final DateTime? createdAt, updatedAt;

  @override
  List<Object?> get props => [id, status, staffReply, updatedAt];
}

/// A user account (player or staff).
class AdminUser extends Equatable {
  const AdminUser({
    required this.id,
    this.email = '',
    this.gamertag = '',
    this.fullName = '',
    this.phone = '',
    this.credit = 0,
    this.emailVerified = false,
    this.isActive = true,
    this.isStaff = false,
    this.dateJoined,
    this.lastLogin,
    this.bookings = 0,
  });

  AdminUser.fromJson(Map<String, dynamic> j)
    : id = _i(j['id']),
      email = j['email'] ?? '',
      gamertag = j['gamertag'] ?? '',
      fullName = j['full_name'] ?? '',
      phone = j['phone'] ?? '',
      credit = _d(j['credit']),
      emailVerified = j['email_verified'] ?? false,
      isActive = j['is_active'] ?? true,
      isStaff = j['is_staff'] ?? false,
      dateJoined = _dt(j['date_joined']),
      lastLogin = _dt(j['last_login']),
      bookings = _i(j['bookings']);

  final int id;
  final String email, gamertag, fullName, phone;

  /// Wallet credit in ₹.
  final double credit;
  final bool emailVerified, isActive, isStaff;
  final DateTime? dateJoined, lastLogin;
  final int bookings;

  @override
  List<Object?> get props => [
    id,
    email,
    gamertag,
    fullName,
    phone,
    credit,
    emailVerified,
    isActive,
    isStaff,
    bookings,
  ];
}

/// The café-wide settings singleton (`admin/cafe/`).
class CafeSettings extends Equatable {
  const CafeSettings({
    this.name = 'Quodes Gaming',
    this.openHour = 10,
    this.closeHour = 24,
    this.upiId = '',
    this.upiPayee = '',
    this.lockMinutes = 10,
    this.verifyHours = 2,
    this.supportPhone = '',
    this.mapsUrl = '',
    this.replyMinutes = 10,
    this.bookingDaysAhead = 7,
  });

  CafeSettings.fromJson(Map<String, dynamic> j)
    : name = j['name'] ?? '',
      openHour = _i(j['open_hour'], 10),
      closeHour = _i(j['close_hour'], 24),
      upiId = j['upi_id'] ?? '',
      upiPayee = j['upi_payee'] ?? '',
      lockMinutes = _i(j['lock_minutes'], 10),
      verifyHours = _i(j['verify_hours'], 2),
      supportPhone = j['support_phone'] ?? '',
      mapsUrl = j['maps_url'] ?? '',
      replyMinutes = _i(j['reply_minutes'], 10),
      bookingDaysAhead = _i(j['booking_days_ahead'], 7);

  final String name, upiId, upiPayee, supportPhone, mapsUrl;
  final int openHour, closeHour, lockMinutes, verifyHours, replyMinutes;
  final int bookingDaysAhead;

  Map<String, dynamic> toJson() => {
    'name': name,
    'open_hour': openHour,
    'close_hour': closeHour,
    'upi_id': upiId,
    'upi_payee': upiPayee,
    'lock_minutes': lockMinutes,
    'verify_hours': verifyHours,
    'support_phone': supportPhone,
    'maps_url': mapsUrl,
    'reply_minutes': replyMinutes,
    'booking_days_ahead': bookingDaysAhead,
  };

  @override
  List<Object?> get props => [...toJson().values];
}

/// Booking statuses staff can filter by, with labels.
const bookingStatusLabels = {
  'locked': 'Locked',
  'scanning': 'AI scanning',
  'ai_failed': 'AI failed',
  'pending_human': 'To verify',
  'confirmed': 'Confirmed',
  'expired': 'Expired',
  'released': 'Released',
  'rejected': 'Rejected',
  'cancelled': 'Cancelled',
};
