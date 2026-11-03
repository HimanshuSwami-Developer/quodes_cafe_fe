import '../../core/network/api_client.dart';
import '../models/admin_models.dart';

/// Staff-only API (`/api/admin/...`) behind the web admin panel.
///
/// Every call throws `ApiException` on failure (via [ApiClient]).
class AdminRepository {
  /// Creates the repository on top of the shared [ApiClient].
  AdminRepository(this._api);
  final ApiClient _api;

  static const _base = 'admin/';

  Future<List<T>> _list<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? query,
  }) async {
    final l = await _api.get<List<dynamic>>('$_base$path', query: query);
    return l.map((e) => parse(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<T> _one<T>(
    Future<Map<String, dynamic>> call,
    T Function(Map<String, dynamic>) parse,
  ) async => parse(await call);

  // ---- Dashboard ----

  /// KPIs, the verify queue and today's sessions.
  Future<AdminDashboard> dashboard() => _one(
    _api.get<Map<String, dynamic>>('${_base}dashboard/'),
    AdminDashboard.fromJson,
  );

  // ---- Bookings ----

  /// Bookings, newest first (max 200). [statuses] are OR-ed; [date] is
  /// `YYYY-MM-DD`; [query] matches code / UTR / email / gamertag / phone.
  Future<List<StaffBooking>> bookings({
    List<String> statuses = const [],
    String? date,
    String? query,
  }) => _list(
    'bookings/',
    StaffBooking.fromJson,
    query: {
      if (statuses.isNotEmpty) 'status': statuses.join(','),
      if (date != null && date.isNotEmpty) 'date': date,
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
    },
  );

  /// Payments waiting for a human, oldest deadline first.
  Future<List<StaffBooking>> verifyQueue() =>
      _list('bookings/', StaffBooking.fromJson, query: {'queue': 'verify'});

  Future<StaffBooking> booking(int id) => _one(
    _api.get<Map<String, dynamic>>('${_base}bookings/$id/'),
    StaffBooking.fromJson,
  );

  /// Marks the payment as received; returns the confirmed booking.
  Future<StaffBooking> approve(int id) => _one(
    _api.post<Map<String, dynamic>>('${_base}bookings/$id/approve/'),
    StaffBooking.fromJson,
  );

  /// Rejects the payment and frees the slot. An empty [note] uses the
  /// server's default message.
  Future<StaffBooking> reject(int id, {String note = ''}) => _one(
    _api.post<Map<String, dynamic>>(
      '${_base}bookings/$id/reject/',
      data: {'note': note.trim()},
    ),
    StaffBooking.fromJson,
  );

  // ---- Games ----

  Future<List<AdminGame>> games() => _list('games/', AdminGame.fromJson);

  /// Creates [g] when it is new, else updates it.
  Future<AdminGame> saveGame(AdminGame g) => _one(
    g.isNew
        ? _api.post<Map<String, dynamic>>('${_base}games/', data: g.toJson())
        : _api.patch<Map<String, dynamic>>(
            '${_base}games/${g.id}/',
            data: g.toJson(),
          ),
    AdminGame.fromJson,
  );

  Future<void> deleteGame(int id) => _api.delete('${_base}games/$id/');

  // ---- Station types & stations ----

  Future<List<AdminStationType>> stationTypes() =>
      _list('station-types/', AdminStationType.fromJson);

  /// Creates [t] when it is new, else updates it.
  Future<AdminStationType> saveStationType(AdminStationType t) => _one(
    t.isNew
        ? _api.post<Map<String, dynamic>>(
            '${_base}station-types/',
            data: t.toJson(),
          )
        : _api.patch<Map<String, dynamic>>(
            '${_base}station-types/${t.id}/',
            data: t.toJson(),
          ),
    AdminStationType.fromJson,
  );

  Future<void> deleteStationType(int id) =>
      _api.delete('${_base}station-types/$id/');

  /// Stations, optionally only those of station type [typeCode].
  Future<List<AdminStation>> stations({String? typeCode}) =>
      _list('stations/', AdminStation.fromJson, query: {'type': ?typeCode});

  /// Adds station [number] of type [typeId]; the server creates its seats.
  Future<AdminStation> createStation({
    required int typeId,
    required int number,
  }) => _one(
    _api.post<Map<String, dynamic>>(
      '${_base}stations/',
      data: {'type': typeId, 'number': number, 'is_active': true},
    ),
    AdminStation.fromJson,
  );

  Future<AdminStation> setStationActive(int id, bool active) => _one(
    _api.patch<Map<String, dynamic>>(
      '${_base}stations/$id/',
      data: {'is_active': active},
    ),
    AdminStation.fromJson,
  );

  Future<void> deleteStation(int id) => _api.delete('${_base}stations/$id/');

  // ---- FAQs ----

  Future<List<AdminFaq>> faqs() => _list('faqs/', AdminFaq.fromJson);

  /// Creates [f] when it is new, else updates it.
  Future<AdminFaq> saveFaq(AdminFaq f) => _one(
    f.isNew
        ? _api.post<Map<String, dynamic>>('${_base}faqs/', data: f.toJson())
        : _api.patch<Map<String, dynamic>>(
            '${_base}faqs/${f.id}/',
            data: f.toJson(),
          ),
    AdminFaq.fromJson,
  );

  Future<void> deleteFaq(int id) => _api.delete('${_base}faqs/$id/');

  // ---- Policies ----

  Future<List<AdminPolicy>> policies() =>
      _list('policies/', AdminPolicy.fromJson);

  /// Creates [p] when it is new, else updates it (sections are replaced).
  Future<AdminPolicy> savePolicy(AdminPolicy p) => _one(
    p.isNew
        ? _api.post<Map<String, dynamic>>('${_base}policies/', data: p.toJson())
        : _api.patch<Map<String, dynamic>>(
            '${_base}policies/${p.id}/',
            data: p.toJson(),
          ),
    AdminPolicy.fromJson,
  );

  Future<void> deletePolicy(int id) => _api.delete('${_base}policies/$id/');

  // ---- Tickets ----

  /// [status] is `open` (= not resolved), `in_review` or `resolved`.
  Future<List<AdminTicket>> tickets({String? status}) =>
      _list('tickets/', AdminTicket.fromJson, query: {'status': ?status});

  /// Changes the status and/or reply; the player is emailed.
  Future<AdminTicket> updateTicket(
    int id, {
    String? status,
    String? staffReply,
  }) => _one(
    _api.patch<Map<String, dynamic>>(
      '${_base}tickets/$id/',
      data: {'status': ?status, 'staff_reply': ?staffReply},
    ),
    AdminTicket.fromJson,
  );

  // ---- Users ----

  Future<List<AdminUser>> users({String? query, bool staffOnly = false}) =>
      _list(
        'users/',
        AdminUser.fromJson,
        query: {
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          if (staffOnly) 'staff': '1',
        },
      );

  /// Partial update. The server ignores [isStaff] unless the caller is a
  /// superuser, and never lets staff change their own active/staff flags.
  Future<AdminUser> updateUser(
    int id, {
    double? credit,
    bool? isActive,
    bool? isStaff,
    bool? emailVerified,
  }) => _one(
    _api.patch<Map<String, dynamic>>(
      '${_base}users/$id/',
      data: {
        if (credit != null) 'credit': credit.toStringAsFixed(2),
        'is_active': ?isActive,
        'is_staff': ?isStaff,
        'email_verified': ?emailVerified,
      },
    ),
    AdminUser.fromJson,
  );

  // ---- Café settings ----

  Future<CafeSettings> cafe() => _one(
    _api.get<Map<String, dynamic>>('${_base}cafe/'),
    CafeSettings.fromJson,
  );

  Future<CafeSettings> saveCafe(CafeSettings s) => _one(
    _api.patch<Map<String, dynamic>>('${_base}cafe/', data: s.toJson()),
    CafeSettings.fromJson,
  );
}
