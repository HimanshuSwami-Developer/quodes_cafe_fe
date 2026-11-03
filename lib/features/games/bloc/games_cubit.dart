import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/catalog_repository.dart';

class GamesState extends Equatable {
  const GamesState({
    this.status = LoadStatus.initial,
    this.cafe,
    this.genres = defaultGenres,
    this.genre = 'All',
    this.query = '',
    this.games,
    this.error,
  });

  static const defaultGenres = [
    'All',
    'Shooter',
    'Sports',
    'Racing',
    'Fighting',
    'Open world',
    'Action',
  ];

  final LoadStatus status;
  final Cafe? cafe;
  final List<String> genres;
  final String genre;
  final String query;

  /// Null until the first list arrives (keeps the grid during refreshes).
  final List<Game>? games;
  final ApiException? error;

  GamesState copyWith({
    LoadStatus? status,
    Cafe? cafe,
    List<String>? genres,
    String? genre,
    String? query,
    List<Game>? games,
    ApiException? error,
  }) => GamesState(
    status: status ?? this.status,
    cafe: cafe ?? this.cafe,
    genres: genres ?? this.genres,
    genre: genre ?? this.genre,
    query: query ?? this.query,
    games: games ?? this.games,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    cafe?.openNow,
    cafe?.closesAt,
    genres,
    genre,
    query,
    games?.map((g) => g.id).toList(),
    error,
  ];
}

class GamesCubit extends Cubit<GamesState> {
  GamesCubit(this._catalog, {this.debounce = const Duration(milliseconds: 300)})
    : super(const GamesState());

  final CatalogRepository _catalog;
  final Duration debounce;
  Timer? _debounce;
  int _request = 0;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final r = await Future.wait([
        _catalog.cafe(refresh: true),
        _catalog.genres(),
      ]);
      final genres = r[1] as List<String>;
      if (isClosed) return;
      emit(
        state.copyWith(
          cafe: r[0] as Cafe,
          genres: genres.isEmpty ? null : genres,
        ),
      );
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(status: LoadStatus.failure, error: e));
      return;
    }
    await _loadGames();
  }

  void selectGenre(String genre) {
    if (genre == state.genre) return;
    emit(state.copyWith(genre: genre));
    _loadGames();
  }

  /// Debounced so typing doesn't fire a request per keystroke.
  void search(String q) {
    emit(state.copyWith(query: q.trim()));
    _debounce?.cancel();
    _debounce = Timer(debounce, _loadGames);
  }

  Future<void> _loadGames() async {
    final id = ++_request;
    try {
      final games = await _catalog.games(
        genre: state.genre,
        query: state.query,
      );
      // Drop stale responses from an earlier filter/query.
      if (isClosed || id != _request) return;
      emit(state.copyWith(status: LoadStatus.success, games: games));
    } on ApiException catch (e) {
      if (!isClosed && id == _request) {
        emit(state.copyWith(status: LoadStatus.failure, error: e));
      }
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
