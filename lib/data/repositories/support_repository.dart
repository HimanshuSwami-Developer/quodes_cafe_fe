import 'package:image_picker/image_picker.dart' show XFile;

import '../../core/network/api_client.dart';
import '../models/models.dart';

class SupportRepository {
  SupportRepository(this._api);
  final ApiClient _api;

  Future<List<Ticket>> tickets() async => (await _api.get<List<dynamic>>(
    'tickets/',
  )).map((e) => Ticket.fromJson(Map<String, dynamic>.from(e))).toList();

  Future<Ticket> createTicket({
    required String topic,
    required String message,
    String bookingCode = '',
    XFile? attachment,
  }) async => Ticket.fromJson(
    await _api.upload<Map<String, dynamic>>(
      'tickets/',
      fields: {'topic': topic, 'message': message, 'booking_code': bookingCode},
      files: {'attachment': ?attachment},
    ),
  );

  List<Faq>? _faqs;
  List<Policy>? _policies;

  Future<List<Faq>> faqs() async => _faqs ??= (await _api.get<List<dynamic>>(
    'faqs/',
  )).map((e) => Faq.fromJson(Map<String, dynamic>.from(e))).toList();

  Future<List<Policy>> policies() async =>
      _policies ??= (await _api.get<List<dynamic>>(
        'policies/',
      )).map((e) => Policy.fromJson(Map<String, dynamic>.from(e))).toList();
}
