import 'package:image_picker/image_picker.dart' show XFile;

import '../../core/network/api_client.dart';
import '../models/models.dart';

class BookingRepository {
  BookingRepository(this._api);
  final ApiClient _api;

  Booking _b(Object? j) =>
      Booking.fromJson(Map<String, dynamic>.from(j as Map));

  Future<Booking> create({
    required int gameId,
    required List<int> seatIds,
    required String date,
    required int startHour,
    required int durationHours,
  }) async => _b(
    await _api.post<Map<String, dynamic>>(
      'bookings/',
      data: {
        'game': gameId,
        'seat_ids': seatIds,
        'date': date,
        'start_hour': startHour,
        'duration_hours': durationHours,
      },
    ),
  );

  Future<List<Booking>> mine({bool activeOnly = false}) async =>
      (await _api.get<List<dynamic>>(
        'bookings/',
        query: activeOnly ? {'active': 1} : null,
      )).map(_b).toList();

  Future<Booking> byId(int id) async =>
      _b(await _api.get<Map<String, dynamic>>('bookings/$id/'));

  Future<Booking> cancel(int id) async =>
      _b(await _api.post<Map<String, dynamic>>('bookings/$id/cancel/'));

  Future<Booking> uploadProof(
    int id, {
    required XFile screenshot,
    String utr = '',
    void Function(int sent, int total)? onProgress,
  }) async => _b(
    await _api.upload<Map<String, dynamic>>(
      'bookings/$id/proof/',
      fields: {if (utr.isNotEmpty) 'utr': utr},
      files: {'screenshot': screenshot},
      onProgress: onProgress,
    ),
  );

  Future<Booking> requestManualReview(int id) async =>
      _b(await _api.post<Map<String, dynamic>>('bookings/$id/manual-review/'));

  Future<Booking> rebookWithCredit(int id) async =>
      _b(await _api.post<Map<String, dynamic>>('bookings/$id/rebook/'));
}
