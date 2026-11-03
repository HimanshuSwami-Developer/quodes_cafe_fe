import '../../core/network/api_client.dart';
import '../models/models.dart';

class CatalogRepository {
  CatalogRepository(this._api);
  final ApiClient _api;

  Cafe? _cafe;

  /// Café settings rarely change; cached for the session.
  Future<Cafe> cafe({bool refresh = false}) async {
    if (_cafe != null && !refresh) return _cafe!;
    return _cafe = Cafe.fromJson(await _api.get<Map<String, dynamic>>('cafe/'));
  }

  Future<List<String>> genres() async =>
      List<String>.from(await _api.get<List<dynamic>>('genres/'));

  Future<List<Game>> games({String? genre, String? query}) async {
    final l = await _api.get<List<dynamic>>(
      'games/',
      query: {
        if (genre != null && genre != 'All') 'genre': genre.toUpperCase(),
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
    return l.map((e) => Game.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<StationType>> stationTypes({int? gameId}) async {
    final l = await _api.get<List<dynamic>>(
      'station-types/',
      query: {'game': ?gameId},
    );
    return l
        .map((e) => StationType.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<SeatMap> seatMap(String type) async => SeatMap.fromJson(
    await _api.get<Map<String, dynamic>>('seatmap/', query: {'type': type}),
  );

  Future<Availability> availability(String date) async => Availability.fromJson(
    await _api.get<Map<String, dynamic>>(
      'availability/',
      query: {'date': date},
    ),
  );

  Future<List<DayOption>> dates() async => (await _api.get<List<dynamic>>(
    'dates/',
  )).map((e) => DayOption.fromJson(Map<String, dynamic>.from(e))).toList();

  Future<List<SlotHour>> slots(List<int> seatIds, String date) async {
    final b = await _api.get<Map<String, dynamic>>(
      'slots/',
      query: {'seats': seatIds.join(','), 'date': date},
    );
    return (b['hours'] as List)
        .map((e) => SlotHour.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
