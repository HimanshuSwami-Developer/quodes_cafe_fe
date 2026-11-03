import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:mocktail/mocktail.dart';
import 'package:quodes_gaming/core/network/api_client.dart';
import 'package:quodes_gaming/data/models/admin_models.dart';
import 'package:quodes_gaming/data/repositories/admin_repository.dart';

import '../helpers/admin_fixtures.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late AdminRepository repo;

  setUp(() {
    api = MockApiClient();
    repo = AdminRepository(api);
  });

  test('dashboard parses KPIs, queue and staff-only booking fields', () async {
    when(
      () => api.get<Map<String, dynamic>>('admin/dashboard/'),
    ).thenAnswer((_) async => dashboardJson());

    final d = await repo.dashboard();

    expect(d.kpis.toVerify, 3);
    expect(d.kpis.revenueToday, 1250);
    expect(d.kpis.openTickets, 2);
    expect(d.queue, hasLength(1));
    final b = d.queue.single;
    expect(b.code, 'QG-42');
    expect(b.booking.amountDue, 300);
    expect(b.booking.aiChecks.map((c) => c.status), ['pass', 'fail']);
    expect(b.player.gamertag, 'NightOwl');
    expect(b.player.credit, 50);
    expect(b.screenshotUrl, endsWith('/proofs/42.png'));
    expect(b.aiRaw, {'amount': '300', 'payee': 'Someone'});
    expect(b.rebookedFrom, 12);
    expect(b.reviewedBy, isNull);
    expect(b.canReview, isTrue);
    expect(d.today.single.status, 'confirmed');
    expect(d.today.single.canReview, isFalse);
  });

  test('bookings sends filters as query params', () async {
    when(
      () =>
          api.get<List<dynamic>>('admin/bookings/', query: any(named: 'query')),
    ).thenAnswer((_) async => [staffBookingJson()]);

    final l = await repo.bookings(
      statuses: ['confirmed', 'pending_human'],
      date: '2026-10-31',
      query: '  QG-42 ',
    );

    expect(l.single.id, 42);
    verify(
      () => api.get<List<dynamic>>(
        'admin/bookings/',
        query: {
          'status': 'confirmed,pending_human',
          'date': '2026-10-31',
          'q': 'QG-42',
        },
      ),
    ).called(1);
  });

  test('verifyQueue asks for the verify queue', () async {
    when(
      () =>
          api.get<List<dynamic>>('admin/bookings/', query: any(named: 'query')),
    ).thenAnswer((_) async => [staffBookingJson(), staffBookingJson(id: 43)]);

    expect(await repo.verifyQueue(), hasLength(2));
    verify(
      () =>
          api.get<List<dynamic>>('admin/bookings/', query: {'queue': 'verify'}),
    ).called(1);
  });

  test('reject posts the note and parses the result', () async {
    when(
      () => api.post<Map<String, dynamic>>(
        'admin/bookings/42/reject/',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => {
        ...staffBookingJson(status: 'rejected'),
        'staff_note': 'No such UTR',
        'reviewed_by': 'desk@quodes.gg',
      },
    );

    final b = await repo.reject(42, note: ' No such UTR ');

    expect(b.status, 'rejected');
    expect(b.staffNote, 'No such UTR');
    expect(b.reviewedBy, 'desk@quodes.gg');
    verify(
      () => api.post<Map<String, dynamic>>(
        'admin/bookings/42/reject/',
        data: {'note': 'No such UTR'},
      ),
    ).called(1);
  });

  test('saveGame POSTs new games and PATCHes existing ones', () async {
    final json = {
      'id': 9,
      'name': 'Valorant',
      'mono': 'VAL',
      'genre': 'SHOOTER',
      'hue': '#FF4D9D',
      'deep': '#341634',
      'platforms': ['PC'],
      'max_players': 1,
      'is_active': true,
      'sort': 3,
    };
    when(
      () => api.post<Map<String, dynamic>>(
        'admin/games/',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => json);
    when(
      () => api.patch<Map<String, dynamic>>(
        'admin/games/9/',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => json);

    const draft = AdminGame(
      name: 'Valorant',
      mono: 'VAL',
      genre: 'SHOOTER',
      platforms: ['PC'],
      maxPlayers: 1,
    );
    final created = await repo.saveGame(draft);
    expect(created.id, 9);
    expect(created.platforms, ['PC']);
    expect(created.hue, '#FF4D9D');
    verify(
      () =>
          api.post<Map<String, dynamic>>('admin/games/', data: draft.toJson()),
    ).called(1);

    await repo.saveGame(created);
    verify(
      () => api.patch<Map<String, dynamic>>(
        'admin/games/9/',
        data: created.toJson(),
      ),
    ).called(1);
  });

  test('uploadGameCover posts multipart and parses cover_url', () async {
    final file = XFile.fromData(Uint8List(4), name: 'cover.png');
    when(
      () => api.upload<Map<String, dynamic>>(
        'admin/games/9/cover/',
        files: any(named: 'files'),
      ),
    ).thenAnswer(
      (_) async => {
        'id': 9,
        'name': 'Valorant',
        'cover_url':
            'https://res.cloudinary.com/x/image/upload/v1/quodes/games/val.png',
      },
    );
    final g = await repo.uploadGameCover(9, file);
    expect(g.coverUrl, contains('res.cloudinary.com'));
    verify(
      () => api.upload<Map<String, dynamic>>(
        'admin/games/9/cover/',
        files: {'cover': file},
      ),
    ).called(1);
  });

  test('removeGameCover deletes then reloads the game', () async {
    when(() => api.delete('admin/games/9/cover/')).thenAnswer((_) async {});
    when(
      () => api.get<Map<String, dynamic>>('admin/games/9/'),
    ).thenAnswer((_) async => {'id': 9, 'name': 'Valorant', 'cover_url': null});
    final g = await repo.removeGameCover(9);
    expect(g.coverUrl, isNull);
    verify(() => api.delete('admin/games/9/cover/')).called(1);
  });

  test('deleteGame calls DELETE', () async {
    when(() => api.delete('admin/games/9/')).thenAnswer((_) async {});
    await repo.deleteGame(9);
    verify(() => api.delete('admin/games/9/')).called(1);
  });

  test('station types, stations, tickets, users and cafe parse', () async {
    when(
      () => api.get<List<dynamic>>(
        'admin/station-types/',
        query: any(named: 'query'),
      ),
    ).thenAnswer(
      (_) async => [
        {
          'id': 1,
          'code': 'PS5',
          'name': 'Station 5',
          'spec': '4K',
          'seats_per_station': 2,
          'hourly_rate': '150.00',
          'seat_prefix': 'S5',
          'grid_cols': 3,
          'sort': 0,
          'station_count': 6,
        },
      ],
    );
    when(
      () =>
          api.get<List<dynamic>>('admin/stations/', query: any(named: 'query')),
    ).thenAnswer(
      (_) async => [
        {
          'id': 4,
          'type': 1,
          'type_code': 'PS5',
          'type_name': 'Station 5',
          'number': 4,
          'code': 'S5-04',
          'is_active': false,
          'seat_count': 2,
        },
      ],
    );
    when(
      () =>
          api.get<List<dynamic>>('admin/tickets/', query: any(named: 'query')),
    ).thenAnswer(
      (_) async => [
        {
          'id': 3,
          'number': '0003',
          'player': {'id': 7, 'email': 'p@e.com', 'gamertag': 'NightOwl'},
          'topic': 'Refund',
          'booking_code': 'QG-42',
          'message': 'Help',
          'attachment_url': null,
          'status': 'in_review',
          'status_label': 'In review',
          'staff_reply': 'On it',
          'created_at': '2026-10-31T10:00:00+05:30',
          'updated_at': '2026-10-31T10:05:00+05:30',
        },
      ],
    );
    when(
      () => api.get<List<dynamic>>('admin/users/', query: any(named: 'query')),
    ).thenAnswer(
      (_) async => [
        {
          'id': 7,
          'email': 'p@e.com',
          'gamertag': 'NightOwl',
          'credit': '25.50',
          'email_verified': true,
          'is_active': true,
          'is_staff': false,
          'bookings': 4,
        },
      ],
    );
    when(() => api.get<Map<String, dynamic>>('admin/cafe/')).thenAnswer(
      (_) async => {
        'name': 'Quodes Gaming',
        'open_hour': 11,
        'close_hour': 23,
        'upi_id': 'quodes@upi',
        'upi_payee': 'Quodes',
        'lock_minutes': 10,
        'verify_hours': 2,
        'support_phone': '',
        'maps_url': '',
        'reply_minutes': 15,
        'booking_days_ahead': 7,
      },
    );

    final t = (await repo.stationTypes()).single;
    expect(t.hourlyRate, 150);
    expect(t.stationCount, 6);
    expect(t.toJson()['hourly_rate'], '150.00');

    final st = (await repo.stations(typeCode: 'PS5')).single;
    expect(st.code, 'S5-04');
    expect(st.isActive, isFalse);
    verify(
      () => api.get<List<dynamic>>('admin/stations/', query: {'type': 'PS5'}),
    ).called(1);

    final tk = (await repo.tickets(status: 'in_review')).single;
    expect(tk.player.gamertag, 'NightOwl');
    expect(tk.staffReply, 'On it');

    final u = (await repo.users(query: 'owl', staffOnly: true)).single;
    expect(u.credit, 25.5);
    expect(u.bookings, 4);
    verify(
      () => api.get<List<dynamic>>(
        'admin/users/',
        query: {'q': 'owl', 'staff': '1'},
      ),
    ).called(1);

    final c = await repo.cafe();
    expect(c.openHour, 11);
    expect(c.replyMinutes, 15);
  });

  test('updateUser only sends the fields given', () async {
    when(
      () => api.patch<Map<String, dynamic>>(
        'admin/users/7/',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => {'id': 7, 'credit': '100.00'});

    final u = await repo.updateUser(7, credit: 100, isActive: false);

    expect(u.credit, 100);
    verify(
      () => api.patch<Map<String, dynamic>>(
        'admin/users/7/',
        data: {'credit': '100.00', 'is_active': false},
      ),
    ).called(1);
  });
}
