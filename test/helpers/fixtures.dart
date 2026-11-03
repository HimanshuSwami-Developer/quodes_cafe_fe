import 'package:quodes_gaming/data/models/models.dart';

Map<String, dynamic> userJson({int id = 7, String credit = '0.00'}) => {
  'id': id,
  'email': 'player@email.com',
  'gamertag': 'NightOwl',
  'full_name': 'Night Owl',
  'phone': '',
  'initials': 'NO',
  'credit': credit,
  'hours_played': '3',
  'sessions': 2,
};

User user({int id = 7, bool staff = false}) =>
    User.fromJson({...userJson(id: id), 'is_staff': staff});

Game game({int maxPlayers = 4}) => Game.fromJson({
  'id': 1,
  'name': 'EA Sports FC 25',
  'mono': 'FC25',
  'genre': 'SPORTS',
  'platforms': ['PS5', 'PS4', 'PC'],
  'max_players': maxPlayers,
});

StationType stationType(String code, {int seats = 2}) => StationType.fromJson({
  'code': code,
  'name': code,
  'seats_per_station': seats,
  'hourly_rate': '150.00',
});

Seat seat(int id) =>
    Seat.fromJson({'id': id, 'code': 'S5-0$id-1', 'label': 'P1'});

Booking booking({int id = 42, String status = 'locked'}) => Booking.fromJson({
  'id': id,
  'code': 'QG-7F3K2A',
  'status': status,
  'status_label': status,
  'station_type': 'PS5',
  'seats': [
    {'id': 1, 'code': 'S5-04-1', 'label': 'P1', 'station': 'S5-04'},
  ],
  'players': 1,
  'date': '2026-10-31',
  'start_hour': 16,
  'duration_hours': 2,
  'total': '300.00',
  'amount_due': '300.00',
  'server_time': '2026-10-31T10:00:00+05:30',
  'lock_expires_at': '2026-10-31T10:10:00+05:30',
});
