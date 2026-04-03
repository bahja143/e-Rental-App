import 'dart:io';

import '../../../../core/network/api_client.dart';
import '../models/estate_draft.dart';

class AddEstateRepository {
  AddEstateRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  static Map<String, int>? _propertyFeatureIdsCache;
  static Map<String, int>? _facilityIdsCache;
  static Map<String, int>? _nearbyPlaceIdsCache;
  static Map<String, int>? _propertyCategoryIdsCache;

  Future<bool> publishEstate(EstateDraft draft) async {
    try {
      final media = await _uploadMedia(draft);
      final response = await _apiClient.postJson(
        '/listings',
        body: _buildListingPayload(draft, media.images, media.videos),
      );
      final listingId = _asInt(response['id']);
      if (listingId != null) {
        await _syncListingMetadata(listingId, draft);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateEstate(String estateId, EstateDraft draft) async {
    if (estateId.trim().isEmpty) return false;
    try {
      final media = await _uploadMedia(draft);
      await _apiClient.putJson(
        '/listings/$estateId',
        body: _buildListingPayload(draft, media.images, media.videos),
      );
      final listingId = _asInt(estateId);
      if (listingId != null) {
        await _syncListingMetadata(listingId, draft);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getListingPlaces(String listingId) async {
    if (listingId.trim().isEmpty) return const <Map<String, dynamic>>[];
    try {
      final rows = await _apiClient.getJsonList('/listing-places', query: {
        'listing_id': listingId,
        'limit': 100,
      });
      return rows.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<_UploadedListingMedia> _uploadMedia(EstateDraft draft) async {
    final images = await _uploadFiles(draft.imagePaths);
    final videos = await _uploadFiles(draft.videoPaths);
    return _UploadedListingMedia(images: images, videos: videos);
  }

  Future<List<String>> _uploadFiles(List<String> paths) async {
    final urls = <String>[];
    for (final path in paths) {
      final trimmed = path.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        urls.add(trimmed);
        continue;
      }
      final file = File(trimmed);
      if (!await file.exists()) continue;
      try {
        final res = await _apiClient.postMultipartFile(
          '/upload/listing-media',
          file,
          fieldName: 'media',
        );
        final url = res['url']?.toString();
        if (url != null && url.isNotEmpty) {
          urls.add(url);
        }
      } catch (_) {
        // Skip broken uploads so one file does not block publishing the rest.
      }
    }
    return urls;
  }

  Map<String, dynamic> _buildListingPayload(
      EstateDraft draft, List<String> uploadedImages, List<String> uploadedVideos) {
    final isSellListing = draft.listingType == 'sell';
    final address = draft.location.trim();
    return {
      'title': draft.title,
      'description': draft.description,
      'address': address.isEmpty ? null : address,
      'lat': draft.lat,
      'lng': draft.lng,
      'sell_price': isSellListing ? draft.pricePerMonth.round() : null,
      'rent_price': isSellListing ? null : draft.pricePerMonth.round(),
      'rent_type': isSellListing ? null : draft.listingType,
      'images': uploadedImages,
      'videos': uploadedVideos,
    };
  }

  Future<void> _syncListingMetadata(int listingId, EstateDraft draft) async {
    await _syncListingCategory(listingId, draft.category);
    await _syncListingFeatures(listingId, draft);
    await _syncListingFacilities(listingId, draft.amenities);
    await _syncListingPlaces(listingId, draft.nearbyPlaces);
  }

  Future<void> _syncListingCategory(int listingId, String categoryLabel) async {
    final categoryIds = await _getPropertyCategoryIds();
    final categoryId = await _ensureReferenceId(
      idsByName: categoryIds,
      path: '/property-categories',
      aliases: [categoryLabel],
      createBody: {
        'name_en': categoryLabel.trim(),
        'name_so': categoryLabel.trim(),
      },
    );
    if (categoryId == null) return;

    final currentRows = await _getAssocRows(
        '/listing-categories', {'listing_id': listingId, 'limit': 20});
    final rowsWithSameCategory = currentRows.where((row) {
      return _asInt(row['property_category_id']) == categoryId ||
          _asInt((row['propertyCategory'] as Map<String, dynamic>?)?['id']) ==
              categoryId;
    }).toList();

    if (rowsWithSameCategory.isEmpty) {
      if (currentRows.isEmpty) {
        await _apiClient.postJson('/listing-categories', body: {
          'listing_id': listingId,
          'property_category_id': categoryId,
        });
      } else {
        await _apiClient
            .putJson('/listing-categories/${currentRows.first['id']}', body: {
          'listing_id': listingId,
          'property_category_id': categoryId,
        });
      }
    }

    for (final row in currentRows) {
      final rowId = _asInt(row['id']);
      if (rowId == null) continue;
      final rowCategoryId = _asInt(row['property_category_id']) ??
          _asInt((row['propertyCategory'] as Map<String, dynamic>?)?['id']);
      if (rowCategoryId != null && rowCategoryId != categoryId) {
        await _safeDelete('/listing-categories/$rowId');
      }
    }
  }

  Future<void> _syncListingFeatures(int listingId, EstateDraft draft) async {
    final featureIds = await _getPropertyFeatureIds();
    final desiredByFeatureId = <int, String>{};

    Future<void> putFeature(
      List<String> aliases,
      String value, {
      required String nameEn,
      required String type,
    }) async {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      final featureId = await _ensureReferenceId(
        idsByName: featureIds,
        path: '/property-features',
        aliases: aliases,
        createBody: {
          'name_en': nameEn,
          'name_so': nameEn,
          'type': type,
        },
      );
      if (featureId != null) {
        desiredByFeatureId[featureId] = trimmed;
      }
    }

    if (draft.bedrooms > 0) {
      await putFeature(
        const ['Bedrooms', 'Bedroom'],
        '${draft.bedrooms}',
        nameEn: 'Bedroom',
        type: 'number',
      );
    }
    if (draft.bathrooms > 0) {
      await putFeature(
        const ['Bathrooms', 'Bathroom'],
        '${draft.bathrooms}',
        nameEn: 'Bathroom',
        type: 'number',
      );
    }
    if (draft.livingRooms > 0) {
      await putFeature(
        const ['Living Rooms', 'Living Room'],
        '${draft.livingRooms}',
        nameEn: 'Living Room',
        type: 'number',
      );
    }
    if (draft.kitchens > 0) {
      await putFeature(
        const ['Kitchens', 'Kitchen'],
        '${draft.kitchens}',
        nameEn: 'Kitchen',
        type: 'number',
      );
    }
    if (draft.numberOfFloors > 0) {
      await putFeature(
        const ['Number of Floors', 'Floors'],
        '${draft.numberOfFloors}',
        nameEn: 'Number of Floors',
        type: 'number',
      );
    }
    if (draft.floorArea != null && draft.floorArea! > 0) {
      await putFeature(
        const ['Floor Area', 'Area'],
        _trimTrailingZero(draft.floorArea!),
        nameEn: 'Area',
        type: 'string',
      );
    }
    if (draft.constructionYear != null && draft.constructionYear! > 0) {
      await putFeature(
        const ['Construction Year', 'Year Built'],
        '${draft.constructionYear}',
        nameEn: 'Construction Year',
        type: 'number',
      );
    }
    await putFeature(
      const ['Finish State', 'Finished', 'Status'],
      draft.isFinished ? 'Finished' : 'Unfinished',
      nameEn: 'Finish State',
      type: 'string',
    );

    final currentRows = await _getAssocRows(
        '/listing-features', {'listing_id': listingId, 'limit': 100});
    final currentByFeatureId = <int, Map<String, dynamic>>{};
    for (final row in currentRows) {
      final featureId = _asInt(row['property_feature_id']) ??
          _asInt((row['propertyFeature'] as Map<String, dynamic>?)?['id']);
      if (featureId != null) {
        currentByFeatureId[featureId] = row;
      }
    }

    for (final entry in desiredByFeatureId.entries) {
      final existing = currentByFeatureId.remove(entry.key);
      if (existing == null) {
        await _apiClient.postJson('/listing-features', body: {
          'listing_id': listingId,
          'property_feature_id': entry.key,
          'value': entry.value,
        });
        continue;
      }
      final rowId = _asInt(existing['id']);
      final currentValue = '${existing['value'] ?? ''}'.trim();
      if (rowId != null && currentValue != entry.value) {
        await _apiClient
            .putJson('/listing-features/$rowId', body: {'value': entry.value});
      }
    }

    for (final stale in currentByFeatureId.values) {
      final rowId = _asInt(stale['id']);
      if (rowId != null) {
        await _safeDelete('/listing-features/$rowId');
      }
    }
  }

  Future<void> _syncListingFacilities(
      int listingId, List<String> amenities) async {
    final facilityIds = await _getFacilityIds();
    final desiredByFacilityId = <int, String>{};
    for (final amenity in amenities) {
      final facilityId = await _ensureReferenceId(
        idsByName: facilityIds,
        path: '/facilities',
        aliases: [amenity],
        createBody: {
          'name_en': amenity.trim(),
          'name_so': amenity.trim(),
        },
      );
      if (facilityId != null) {
        desiredByFacilityId[facilityId] = 'Available';
      }
    }

    final currentRows = await _getAssocRows(
        '/listing-facilities', {'listing_id': listingId, 'limit': 100});
    final currentByFacilityId = <int, Map<String, dynamic>>{};
    for (final row in currentRows) {
      final facilityId = _asInt(row['facility_id']) ??
          _asInt((row['facility'] as Map<String, dynamic>?)?['id']);
      if (facilityId != null) {
        currentByFacilityId[facilityId] = row;
      }
    }

    for (final entry in desiredByFacilityId.entries) {
      final existing = currentByFacilityId.remove(entry.key);
      if (existing == null) {
        await _apiClient.postJson('/listing-facilities', body: {
          'listing_id': listingId,
          'facility_id': entry.key,
          'value': entry.value,
        });
        continue;
      }
      final rowId = _asInt(existing['id']);
      final currentValue = '${existing['value'] ?? ''}'.trim();
      if (rowId != null && currentValue != entry.value) {
        await _apiClient.putJson('/listing-facilities/$rowId',
            body: {'value': entry.value});
      }
    }

    for (final stale in currentByFacilityId.values) {
      final rowId = _asInt(stale['id']);
      if (rowId != null) {
        await _safeDelete('/listing-facilities/$rowId');
      }
    }
  }

  Future<void> _syncListingPlaces(
      int listingId, Map<String, int> nearbyPlaces) async {
    final nearbyPlaceIds = await _getNearbyPlaceIds();
    final desiredByPlaceId = <int, String>{};
    for (final entry in nearbyPlaces.entries) {
      if (entry.value <= 0) continue;
      final nearbyPlaceId = await _ensureReferenceId(
        idsByName: nearbyPlaceIds,
        path: '/nearby-places',
        aliases: [entry.key],
        createBody: {
          'name_en': entry.key.trim(),
          'name_so': entry.key.trim(),
        },
      );
      if (nearbyPlaceId != null) {
        desiredByPlaceId[nearbyPlaceId] = '${entry.value}';
      }
    }

    final currentRows = await _getAssocRows(
        '/listing-places', {'listing_id': listingId, 'limit': 100});
    final currentByPlaceId = <int, Map<String, dynamic>>{};
    for (final row in currentRows) {
      final nearbyPlaceId = _asInt(row['nearby_place_id']) ??
          _asInt((row['nearbyPlace'] as Map<String, dynamic>?)?['id']);
      if (nearbyPlaceId != null) {
        currentByPlaceId[nearbyPlaceId] = row;
      }
    }

    for (final entry in desiredByPlaceId.entries) {
      final existing = currentByPlaceId.remove(entry.key);
      if (existing == null) {
        await _apiClient.postJson('/listing-places', body: {
          'listing_id': listingId,
          'nearby_place_id': entry.key,
          'value': entry.value,
        });
        continue;
      }
      final rowId = _asInt(existing['id']);
      final currentValue = '${existing['value'] ?? ''}'.trim();
      if (rowId != null && currentValue != entry.value) {
        await _apiClient
            .putJson('/listing-places/$rowId', body: {'value': entry.value});
      }
    }

    for (final stale in currentByPlaceId.values) {
      final rowId = _asInt(stale['id']);
      if (rowId != null) {
        await _safeDelete('/listing-places/$rowId');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getAssocRows(
    String path,
    Map<String, dynamic> query,
  ) async {
    try {
      final rows = await _apiClient.getJsonList(path, query: query);
      return rows.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, int>> _getPropertyFeatureIds() async {
    return _propertyFeatureIdsCache ??=
        await _loadReferenceIds('/property-features');
  }

  Future<Map<String, int>> _getFacilityIds() async {
    return _facilityIdsCache ??= await _loadReferenceIds('/facilities');
  }

  Future<Map<String, int>> _getNearbyPlaceIds() async {
    return _nearbyPlaceIdsCache ??= await _loadReferenceIds('/nearby-places');
  }

  Future<Map<String, int>> _getPropertyCategoryIds() async {
    return _propertyCategoryIdsCache ??=
        await _loadReferenceIds('/property-categories');
  }

  Future<Map<String, int>> _loadReferenceIds(String path) async {
    final rows = await _apiClient.getJsonList(path, query: {'limit': 100});
    final ids = <String, int>{};
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      final id = _asInt(row['id']);
      if (id == null) continue;
      for (final key in ['name_en', 'name_so']) {
        final value = '${row[key] ?? ''}'.trim();
        if (value.isEmpty) continue;
        ids[_normalizeName(value)] = id;
      }
    }
    return ids;
  }

  int? _findReferenceId(Map<String, int> idsByName, List<String> aliases) {
    for (final alias in aliases) {
      final normalized = _normalizeName(alias);
      final exact = idsByName[normalized];
      if (exact != null) return exact;

      if (normalized.endsWith('s')) {
        final singular =
            idsByName[normalized.substring(0, normalized.length - 1)];
        if (singular != null) return singular;
      } else {
        final plural = idsByName['${normalized}s'];
        if (plural != null) return plural;
      }
    }
    return null;
  }

  Future<int?> _ensureReferenceId({
    required Map<String, int> idsByName,
    required String path,
    required List<String> aliases,
    required Map<String, dynamic> createBody,
  }) async {
    final existing = _findReferenceId(idsByName, aliases);
    if (existing != null) return existing;

    try {
      final created = await _apiClient.postJson(path, body: createBody);
      final id = _asInt(created['id']);
      if (id != null) {
        _indexReferenceId(idsByName, id, aliases);
        _indexReferenceId(idsByName, id, [
          '${created['name_en'] ?? ''}',
          '${created['name_so'] ?? ''}',
        ]);
        return id;
      }
    } catch (_) {
      // Another client or an earlier request may already have created it.
    }

    try {
      final refreshed = await _loadReferenceIds(path);
      idsByName
        ..clear()
        ..addAll(refreshed);
    } catch (_) {
      // Keep the in-memory cache as-is if refresh fails.
    }
    return _findReferenceId(idsByName, aliases);
  }

  void _indexReferenceId(
    Map<String, int> idsByName,
    int id,
    List<String> names,
  ) {
    for (final name in names) {
      final normalized = _normalizeName(name);
      if (normalized.isEmpty) continue;
      idsByName[normalized] = id;
      if (normalized.endsWith('s')) {
        final singular = normalized.substring(0, normalized.length - 1);
        if (singular.isNotEmpty) {
          idsByName[singular] = id;
        }
      } else {
        idsByName['${normalized}s'] = id;
      }
    }
  }

  Future<void> _safeDelete(String path) async {
    try {
      await _apiClient.deleteJson(path);
    } catch (_) {
      // Best-effort cleanup keeps listing updates moving even when a stale relation fails to delete.
    }
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  String _normalizeName(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  String _trimTrailingZero(double value) {
    final rounded = value.roundToDouble();
    if (rounded == value) {
      return rounded.toInt().toString();
    }
    return value.toString();
  }
}

class _UploadedListingMedia {
  const _UploadedListingMedia({
    required this.images,
    required this.videos,
  });

  final List<String> images;
  final List<String> videos;
}
