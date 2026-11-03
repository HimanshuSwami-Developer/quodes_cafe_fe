import 'package:quodes_gaming/data/models/admin_models.dart';

/// Staff booking JSON as `admin/bookings/` returns it.
Map<String, dynamic> staffBookingJson({
  int id = 42,
  String status = 'pending_human',
  String deadline = '2026-10-31T11:00:00+05:30',
}) => {
  'id': id,
  'code': 'QG-$id',
  'status': status,
  'status_label': status,
  'station_type': 'PS5',
  'station_type_name': 'Station 5',
  'seats': [
    {'id': 1, 'code': 'S5-04-1', 'label': 'P1', 'station': 'S5-04'},
  ],
  'players': 1,
  'date': '2026-10-31',
  'start_hour': 16,
  'duration_hours': 2,
  'total': '300.00',
  'amount_due': '300.00',
  'utr': '123456789012',
  'ai_checks': [
    {'key': 'amount', 'label': 'Amount', 'status': 'pass'},
    {'key': 'payee', 'label': 'Payee', 'status': 'fail'},
  ],
  'ai_message': 'Payee did not match',
  'server_time': '2026-10-31T10:00:00+05:30',
  'verify_deadline': deadline,
  'player': {
    'id': 7,
    'email': 'player@email.com',
    'gamertag': 'NightOwl',
    'full_name': 'Night Owl',
    'phone': '9999999999',
    'credit': '50.00',
  },
  'screenshot_url': 'http://localhost:8000/media/proofs/42.png',
  'ai_raw': {'amount': '300', 'payee': 'Someone'},
  'staff_note': '',
  'reviewed_by': null,
  'rebooked_from': 12,
};

StaffBooking staffBooking({int id = 42, String status = 'pending_human'}) =>
    StaffBooking.fromJson(staffBookingJson(id: id, status: status));

Map<String, dynamic> dashboardJson({int toVerify = 3, int openTickets = 2}) => {
  'kpis': {
    'to_verify': toVerify,
    'sessions_today': 5,
    'revenue_today': '1250.00',
    'live_locks': 1,
    'open_tickets': openTickets,
    'players': 40,
  },
  'queue': [staffBookingJson()],
  'today': [staffBookingJson(id: 43, status: 'confirmed')],
  'server_time': '2026-10-31T10:00:00+05:30',
};
