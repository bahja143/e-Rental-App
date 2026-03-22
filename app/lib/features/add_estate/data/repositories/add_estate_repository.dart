import 'dart:io';

import '../../../../core/network/api_client.dart';
import '../models/estate_draft.dart';

class AddEstateRepository {
  AddEstateRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<bool> publishEstate(EstateDraft draft) async {
    try {
      final uploadedImages = await _uploadImages(draft.imagePaths);
      await _apiClient.postJson('/listings', body: {
        'title': draft.title,
        'description': draft.description,
        'address': draft.location,
        'lat': draft.lat,
        'lng': draft.lng,
        'rent_price': draft.pricePerMonth.round(),
        'rent_type': draft.listingType,
        'property_type': draft.category.toLowerCase(),
        'images': uploadedImages,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateEstate(String estateId, EstateDraft draft) async {
    if (estateId.trim().isEmpty) return false;
    try {
      final uploadedImages = await _uploadImages(draft.imagePaths);
      await _apiClient.putJson('/listings/$estateId', body: {
        'title': draft.title,
        'description': draft.description,
        'address': draft.location,
        'lat': draft.lat,
        'lng': draft.lng,
        'rent_price': draft.pricePerMonth.round(),
        'rent_type': draft.listingType,
        'property_type': draft.category.toLowerCase(),
        'images': uploadedImages,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> _uploadImages(List<String> imagePaths) async {
    final urls = <String>[];
    for (final path in imagePaths) {
      final trimmed = path.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        urls.add(trimmed);
        continue;
      }
      final file = File(trimmed);
      if (!await file.exists()) continue;
      try {
        // Reuse the app's existing generic image upload endpoint.
        final res = await _apiClient.postMultipartFile('/upload/profile-image', file);
        final url = res['url']?.toString();
        if (url != null && url.isNotEmpty) {
          urls.add(url);
        }
      } catch (_) {
        // Skip broken uploads so one image does not block publishing the rest.
      }
    }
    return urls;
  }
}
