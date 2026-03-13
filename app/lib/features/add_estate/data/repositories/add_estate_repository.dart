import '../../../../core/network/api_client.dart';
import '../models/estate_draft.dart';

class AddEstateRepository {
  AddEstateRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<bool> publishEstate(EstateDraft draft) async {
    try {
      await _apiClient.postJson('/listings', body: {
        'title': draft.title,
        'description': draft.description,
        'address': draft.location,
        // Default coordinates keep payload valid until location picker is wired to lat/lng.
        'lat': -6.2088,
        'lng': 106.8456,
        'rent_price': draft.pricePerMonth.round(),
        'rent_type': 'monthly',
        'images': <String>[],
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
