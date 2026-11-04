// Plain data models mirroring docs/API.md.

double _d(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

DateTime? _dt(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

String rupees(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

class User {
  final int id;
  final String email, gamertag, fullName, phone, initials;
  final bool emailVerified;
  final double credit;
  final double hoursPlayed;
  final int sessions;

  /// Desk staff: may open the /admin web panel.
  final bool isStaff;

  User.fromJson(Map<String, dynamic> j)
    : id = j['id'] ?? 0,
      email = j['email'] ?? '',
      gamertag = j['gamertag'] ?? '',
      fullName = j['full_name'] ?? '',
      phone = j['phone'] ?? '',
      initials = (j['initials'] ?? '').toString(),
      emailVerified = j['email_verified'] ?? true,
      credit = _d(j['credit']),
      hoursPlayed = _d(j['hours_played']),
      sessions = j['sessions'] ?? 0,
      isStaff = j['is_staff'] ?? false;

  /// Stand-in while offline at launch; replaced by the real profile on refresh.
  User.placeholder()
    : id = 0,
      email = '',
      gamertag = '',
      fullName = '',
      phone = '',
      initials = '',
      emailVerified = true,
      credit = 0,
      hoursPlayed = 0,
      sessions = 0,
      isStaff = false;
}

class Cafe {
  final String name, opensAt, closesAt, upiId, upiPayee, supportPhone, mapsUrl;
  final bool openNow;
  final int lockMinutes, verifyHours, replyMinutes, openHour, closeHour;

  Cafe.fromJson(Map<String, dynamic> j)
    : name = j['name'] ?? 'Quodes',
      opensAt = j['opens_at'] ?? '',
      closesAt = j['closes_at'] ?? '',
      upiId = j['upi_id'] ?? '',
      upiPayee = j['upi_payee'] ?? '',
      supportPhone = j['support_phone'] ?? '',
      mapsUrl = j['maps_url'] ?? '',
      openNow = j['open_now'] ?? false,
      lockMinutes = j['lock_minutes'] ?? 10,
      verifyHours = j['verify_hours'] ?? 2,
      replyMinutes = j['reply_minutes'] ?? 5,
      openHour = j['open_hour'] ?? 10,
      closeHour = j['close_hour'] ?? 24;
}

class Game {
  final int id;
  final String name, mono, genre, hue, deep;

  /// Internal codes (PS5 / PS4 / PC), used for logic only.
  final List<String> platforms;

  /// What players see, same order as [platforms] (e.g. "Station 5").
  final List<String> platformNames;
  final int maxPlayers;

  /// Portrait poster for the Games grid (admin upload), or null.
  final String? coverUrl;

  /// Landscape image for the booking screen (admin upload), or null.
  final String? bannerUrl;

  Game.fromJson(Map<String, dynamic> j)
    : id = j['id'] ?? 0,
      name = j['name'] ?? '',
      mono = j['mono'] ?? '',
      genre = j['genre'] ?? '',
      hue = j['hue'] ?? '#2F6BFF',
      deep = j['deep'] ?? '#111C42',
      platforms = List<String>.from(j['platforms'] ?? const []),
      platformNames = List<String>.from(
        j['platform_names'] ?? j['platforms'] ?? const [],
      ),
      maxPlayers = j['max_players'] ?? 4,
      coverUrl = _url(j['cover_url']),
      bannerUrl = _url(j['banner_url']);
}

/// Non-empty string or null.
String? _url(Object? v) {
  final s = v?.toString().trim() ?? '';
  return s.isEmpty ? null : s;
}

class StationType {
  final String code, name, spec;
  final int seatsPerStation, maxPlayers, freeSeats, totalSeats;
  final double hourlyRate;
  final bool enabled;

  StationType.fromJson(Map<String, dynamic> j)
    : code = j['code'] ?? '',
      name = j['name'] ?? j['code'] ?? '',
      spec = j['spec'] ?? '',
      seatsPerStation = j['seats_per_station'] ?? 1,
      maxPlayers = j['max_players'] ?? 4,
      freeSeats = j['free_seats'] ?? 0,
      totalSeats = j['total_seats'] ?? 0,
      hourlyRate = _d(j['hourly_rate']),
      enabled = j['enabled'] ?? true;
}

class Seat {
  final int id;
  final String code, label;
  final bool busy;
  Seat.fromJson(Map<String, dynamic> j)
    : id = j['id'] ?? 0,
      code = j['code'] ?? '',
      label = j['label'] ?? '',
      busy = j['busy'] ?? false;
}

class StationPod {
  final int id;
  final String code;
  final List<Seat> seats;
  StationPod.fromJson(Map<String, dynamic> j)
    : id = j['id'] ?? 0,
      code = j['code'] ?? '',
      seats = (j['seats'] as List? ?? const [])
          .map((e) => Seat.fromJson(e))
          .toList();
}

class SeatMap {
  final String type;
  final int seatsPerStation, cols;
  final List<StationPod> stations;
  SeatMap.fromJson(Map<String, dynamic> j)
    : type = j['type'] ?? '',
      seatsPerStation = j['seats_per_station'] ?? 1,
      cols = j['cols'] ?? 3,
      stations = (j['stations'] as List? ?? const [])
          .map((e) => StationPod.fromJson(e))
          .toList();
}

class AvailabilityType {
  final String code, name;
  final int total, freeNow;
  AvailabilityType.fromJson(Map<String, dynamic> j)
    : code = j['code'] ?? '',
      name = j['name'] ?? j['code'] ?? '',
      total = j['total'] ?? 0,
      freeNow = j['free_now'] ?? 0;
}

class AvailabilityHour {
  final int hour;
  final String label;
  final Map<String, int> free;
  AvailabilityHour.fromJson(Map<String, dynamic> j)
    : hour = j['hour'] ?? 0,
      label = j['label'] ?? '',
      free = (j['free'] as Map? ?? const {}).map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      );
}

class Availability {
  final String date;
  final List<AvailabilityType> types;
  final List<AvailabilityHour> hours;
  Availability.fromJson(Map<String, dynamic> j)
    : date = j['date'] ?? '',
      types = (j['types'] as List? ?? const [])
          .map((e) => AvailabilityType.fromJson(e))
          .toList(),
      hours = (j['hours'] as List? ?? const [])
          .map((e) => AvailabilityHour.fromJson(e))
          .toList();
}

class SlotHour {
  final int hour;
  final String label, status; // open | hold | booked | past
  SlotHour.fromJson(Map<String, dynamic> j)
    : hour = j['hour'] ?? 0,
      label = j['label'] ?? '',
      status = j['status'] ?? 'open';
}

class DayOption {
  final String date, dow, mon;
  final int num;
  DayOption.fromJson(Map<String, dynamic> j)
    : date = j['date'] ?? '',
      dow = j['dow'] ?? '',
      mon = j['mon'] ?? '',
      num = j['num'] ?? 0;
}

class AiCheck {
  final String key, label, detail, status; // pass | fail | pending
  AiCheck.fromJson(Map<String, dynamic> j)
    : key = j['key'] ?? '',
      label = j['label'] ?? '',
      detail = j['detail'] ?? '',
      status = j['status'] ?? 'pending';
}

class BookingSeat {
  final int id;
  final String code, label, station;
  BookingSeat.fromJson(Map<String, dynamic> j)
    : id = j['id'] ?? 0,
      code = j['code'] ?? '',
      label = j['label'] ?? '',
      station = j['station'] ?? '';
}

class Booking {
  final int id;
  final String code, status, statusLabel, stationType, stationTypeName;
  final String stationLabel;
  final Game? game;
  final List<BookingSeat> seats;
  final int players, startHour, durationHours;
  final String date, dateLabel, timeLabel;
  final double rate, subtotal, total, creditApplied, amountDue;
  final String upiId, upiPayee, upiUri, utr, aiMessage;
  final DateTime? lockExpiresAt,
      verifyDeadline,
      createdAt,
      submittedAt,
      aiCheckedAt,
      confirmedAt,
      releasedAt,
      serverTime;
  final List<AiCheck> aiChecks;

  /// Local clock reading when this payload arrived; used with [serverTime]
  /// to compute countdowns without trusting the phone clock.
  final DateTime receivedAt;

  Booking.fromJson(Map<String, dynamic> j)
    : id = j['id'] ?? 0,
      code = j['code'] ?? '',
      status = j['status'] ?? '',
      statusLabel = j['status_label'] ?? '',
      stationType = j['station_type'] ?? '',
      stationTypeName = j['station_type_name'] ?? j['station_type'] ?? '',
      stationLabel = j['station_label'] ?? '',
      game = j['game'] is Map<String, dynamic>
          ? Game.fromJson(j['game'])
          : null,
      seats = (j['seats'] as List? ?? const [])
          .map((e) => BookingSeat.fromJson(e))
          .toList(),
      players = j['players'] ?? 0,
      startHour = j['start_hour'] ?? 0,
      durationHours = j['duration_hours'] ?? 1,
      date = j['date'] ?? '',
      dateLabel = j['date_label'] ?? '',
      timeLabel = j['time_label'] ?? '',
      rate = _d(j['rate']),
      subtotal = _d(j['subtotal']),
      total = _d(j['total']),
      creditApplied = _d(j['credit_applied']),
      amountDue = _d(j['amount_due']),
      upiId = j['upi_id'] ?? '',
      upiPayee = j['upi_payee'] ?? '',
      upiUri = j['upi_uri'] ?? '',
      utr = j['utr'] ?? '',
      aiMessage = j['ai_message'] ?? '',
      lockExpiresAt = _dt(j['lock_expires_at']),
      verifyDeadline = _dt(j['verify_deadline']),
      createdAt = _dt(j['created_at']),
      submittedAt = _dt(j['submitted_at']),
      aiCheckedAt = _dt(j['ai_checked_at']),
      confirmedAt = _dt(j['confirmed_at']),
      releasedAt = _dt(j['released_at']),
      serverTime = _dt(j['server_time']),
      aiChecks = (j['ai_checks'] as List? ?? const [])
          .map((e) => AiCheck.fromJson(e))
          .toList(),
      receivedAt = DateTime.now();

  /// Server-corrected "now".
  DateTime get now {
    if (serverTime == null) return DateTime.now();
    return serverTime!.add(DateTime.now().difference(receivedAt));
  }

  Duration remainingUntil(DateTime? t) {
    if (t == null) return Duration.zero;
    final d = t.difference(now);
    return d.isNegative ? Duration.zero : d;
  }

  Duration get lockLeft => remainingUntil(lockExpiresAt);
  Duration get verifyLeft => remainingUntil(verifyDeadline);

  String get shortGame => game?.mono ?? '';
}

class Ticket {
  final int id;
  final String number, topic, bookingCode, message, status, statusLabel;
  final DateTime? updatedAt;
  Ticket.fromJson(Map<String, dynamic> j)
    : id = j['id'] ?? 0,
      number = (j['number'] ?? '').toString(),
      topic = j['topic'] ?? '',
      bookingCode = j['booking_code'] ?? '',
      message = j['message'] ?? '',
      status = j['status'] ?? '',
      statusLabel = j['status_label'] ?? '',
      updatedAt = _dt(j['updated_at']);
}

class Faq {
  final int id;
  final String question, answer;
  Faq.fromJson(Map<String, dynamic> j)
    : id = j['id'] ?? 0,
      question = j['question'] ?? '',
      answer = j['answer'] ?? '';
}

class PolicySection {
  final String heading, body;
  PolicySection.fromJson(Map<String, dynamic> j)
    : heading = j['heading'] ?? '',
      body = j['body'] ?? '';
}

class Policy {
  final String key, title, updated;
  final List<PolicySection> sections;
  Policy.fromJson(Map<String, dynamic> j)
    : key = j['key'] ?? '',
      title = j['title'] ?? '',
      updated = j['updated'] ?? '',
      sections = (j['sections'] as List? ?? const [])
          .map((e) => PolicySection.fromJson(e))
          .toList();
}
