import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_session.dart';
import '../models/estate_item.dart';
import '../models/top_agent_item.dart';
import '../models/top_location_item.dart';

class EstateRepository {
  EstateRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static Set<String>? _savedIdsCache;
  static String? _savedIdsCacheUserId;
  static List<dynamic>? _publicListingsCache;
  static DateTime? _publicListingsCacheAt;
  static Future<List<dynamic>>? _publicListingsInFlight;
  static const Duration _publicListingsCacheTtl = Duration(seconds: 30);
  final ApiClient _apiClient;

  String? _currentUserId() {
    final userId = ApiSession.currentUserId?.trim();
    return userId == null || userId.isEmpty ? null : userId;
  }

  void _invalidateSavedIdsCacheIfUserChanged() {
    final userId = _currentUserId();
    if (_savedIdsCacheUserId != userId) {
      _savedIdsCacheUserId = userId;
      _savedIdsCache = null;
    }
  }

  Future<List<EstateItem>> getSavedEstates() async {
    _invalidateSavedIdsCacheIfUserChanged();
    try {
      final favourites = await _apiClient.getJsonList('/favourites', query: {'limit': 50});
      final listingIds = favourites
          .whereType<Map<String, dynamic>>()
          .map((fav) => fav['listing'])
          .whereType<Map<String, dynamic>>()
          .map((listing) => '${listing['id'] ?? ''}')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final details = await Future.wait(
        listingIds.map((id) async {
          try {
            return await _apiClient.getJson('/public/listings/$id');
          } catch (_) {
            return <String, dynamic>{};
          }
        }),
      );

      final estates = details
          .where((json) => json.isNotEmpty)
          .map(_toEstateItem)
          .where((e) => e.id.isNotEmpty)
          .toList();
      if (estates.isNotEmpty) return estates;
      return const <EstateItem>[];
    } catch (_) {}
    return const <EstateItem>[];
  }

  Future<bool> removeSavedEstate(String listingId) async {
    _invalidateSavedIdsCacheIfUserChanged();
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty || listingId.isEmpty) {
      return false;
    }
    try {
      await _apiClient.deleteJson('/favourites/$userId/$listingId');
      _savedIdsCache?.remove(listingId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addSavedEstate(String listingId) async {
    _invalidateSavedIdsCacheIfUserChanged();
    if (listingId.isEmpty) return false;
    try {
      await _apiClient.postJson('/favourites', body: {
        'listing_id': int.tryParse(listingId) ?? listingId,
      });
      (_savedIdsCache ??= <String>{}).add(listingId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearSavedEstates(Iterable<String> listingIds) async {
    var allOk = true;
    for (final id in listingIds.toSet()) {
      final ok = await removeSavedEstate(id);
      if (!ok) allOk = false;
    }
    return allOk;
  }

  Future<Set<String>> getSavedEstateIds({bool forceRefresh = false}) async {
    _invalidateSavedIdsCacheIfUserChanged();
    if (!forceRefresh && _savedIdsCache != null) {
      return Set<String>.from(_savedIdsCache!);
    }
    try {
      final favourites = await _apiClient.getJsonList('/favourites', query: {'limit': 100});
      final ids = favourites
          .whereType<Map<String, dynamic>>()
          .map((fav) => fav['listing'])
          .whereType<Map<String, dynamic>>()
          .map((listing) => '${listing['id'] ?? ''}')
          .where((id) => id.isNotEmpty)
          .toSet();
      _savedIdsCache = ids;
      return Set<String>.from(ids);
    } catch (_) {
      return _savedIdsCache != null ? Set<String>.from(_savedIdsCache!) : <String>{};
    }
  }

  Future<List<EstateItem>> getMyListings({int limit = 100}) async {
    final userId = _currentUserId();
    if (userId == null) return const <EstateItem>[];
    try {
      final response = await _apiClient.getJsonList('/listings', query: {
        'user_id': userId,
        'limit': limit,
        'include': 'types,categories',
      });
      return _parseEstates(response);
    } catch (_) {}
    return const <EstateItem>[];
  }

  Future<List<EstateItem>> getFeaturedEstates() async {
    try {
      final response = await _getPublicListingsSnapshot(limit: 40);
      final estates = _parseEstates(response);
      return estates.take(20).toList();
    } catch (_) {}
    return const <EstateItem>[];
  }

  Future<List<EstateItem>> getNearbyEstates() async {
    try {
      final response = await _getPublicListingsSnapshot(limit: 40);
      final estates = _parseEstates(response);
      return estates.take(20).toList();
    } catch (_) {}
    return const <EstateItem>[];
  }

  Future<List<EstateItem>> searchEstates(String query) async {
    try {
      final response = await _apiClient.getJsonList('/public/listings', query: {'search': query, 'limit': 20});
      final estates = _parseEstates(response);
      return estates;
    } catch (_) {}
    return const <EstateItem>[];
  }

  /// Public listings with optional search + price filters (server + local property type).
  /// Backend: `rent_price_min` / `rent_price_max` or `sell_price_min` / `sell_price_max`.
  Future<List<EstateItem>> queryPublicListings({
    String? search,
    int limit = 40,
    bool preferRent = true,
    String? rentPriceMin,
    String? rentPriceMax,
    String? sellPriceMin,
    String? sellPriceMax,
    String propertyType = 'All',
  }) async {
    final s = search?.trim();
    try {
      final query = <String, dynamic>{'limit': limit};
      if (s != null && s.isNotEmpty) query['search'] = s;
      if (preferRent) {
        final a = rentPriceMin?.trim();
        final b = rentPriceMax?.trim();
        if (a != null && a.isNotEmpty) query['rent_price_min'] = a;
        if (b != null && b.isNotEmpty) query['rent_price_max'] = b;
      } else {
        final a = sellPriceMin?.trim();
        final b = sellPriceMax?.trim();
        if (a != null && a.isNotEmpty) query['sell_price_min'] = a;
        if (b != null && b.isNotEmpty) query['sell_price_max'] = b;
      }
      final response = await _apiClient.getJsonList('/public/listings', query: query);
      var estates = _parseEstates(response);
      estates = _filterByPropertyType(estates, propertyType);
      return estates;
    } catch (_) {}
    return const <EstateItem>[];
  }

  List<EstateItem> _filterByPropertyType(List<EstateItem> items, String propertyType) {
    if (propertyType == 'All') return items;
    final t = propertyType.toLowerCase();
    return items.where((e) {
      final c = (e.displayCategory ?? '').toLowerCase();
      return c.contains(t) || e.title.toLowerCase().contains(t);
    }).toList();
  }

  Future<List<TopLocationItem>> getTopLocations() async {
    try {
      final response = await _getPublicListingsSnapshot(limit: 40);
      final byName = <String, TopLocationItem>{};
      for (final raw in response.whereType<Map<String, dynamic>>()) {
        final address = '${raw['address'] ?? ''}'.trim();
        final locationName = _extractLocationName(address);
        if (locationName.isEmpty || byName.containsKey(locationName)) continue;
        final images = raw['images'];
        final avatarUrl = (images is List && images.isNotEmpty) ? '${images.first}' : '';
        if (avatarUrl.isEmpty) continue;
        byName[locationName] = TopLocationItem(
          name: locationName,
          avatarUrl: avatarUrl,
        );
      }
      final locations = byName.values.toList();
      return locations;
    } catch (_) {}
    return const <TopLocationItem>[];
  }

  Future<List<TopAgentItem>> getTopAgents() async {
    try {
      final response = await _getPublicListingsSnapshot(limit: 40);
      final byId = <String, TopAgentItem>{};
      for (final raw in response.whereType<Map<String, dynamic>>()) {
        final user = raw['user'];
        if (user is! Map<String, dynamic>) continue;
        final id = '${user['id'] ?? ''}';
        if (id.isEmpty || byId.containsKey(id)) continue;
        final name = '${user['name'] ?? ''}';
        final avatarUrl = '${user['profile_picture_url'] ?? ''}';
        if (name.isEmpty || avatarUrl.isEmpty) continue;
        byId[id] = TopAgentItem(id: id, name: name, avatarUrl: avatarUrl);
      }
      final agents = byId.values.toList();
      return agents;
    } catch (_) {}
    return const <TopAgentItem>[];
  }

  Future<Map<String, dynamic>?> getEstateById(String estateId) async {
    try {
      final response = await _apiClient.getJson('/public/listings/$estateId');
      if ('${response['id'] ?? ''}'.isNotEmpty) return response;
    } catch (_) {}
    return null;
  }

  /// Listing row for screens like **Figma `28:4414`** reviews header card.
  Future<EstateItem?> getEstateItemById(String estateId) async {
    final m = await getEstateById(estateId);
    if (m == null) return null;
    try {
      return _toEstateItem(m);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getListingReviews(String estateId) async {
    try {
      final response = await _apiClient.getJsonList(
        '/listing-reviews',
        query: {'listing_id': estateId, 'limit': 20},
      );
      final list = response.whereType<Map<String, dynamic>>().toList();
      return list;
    } catch (_) {}
    return const <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getListingPlaces(String estateId) async {
    if (estateId.trim().isEmpty) return const <Map<String, dynamic>>[];
    try {
      final response = await _apiClient.getJsonList(
        '/listing-places',
        query: {'listing_id': estateId, 'limit': 100},
      );
      return response.whereType<Map<String, dynamic>>().toList();
    } catch (_) {}
    return const <Map<String, dynamic>>[];
  }

  Future<List<EstateItem>> getNearbyFromEstate(String estateId) async {
    try {
      final response = await _getPublicListingsSnapshot(limit: 40);
      final estates = response
          .whereType<Map<String, dynamic>>()
          .map(_toEstateItem)
          .where((e) => e.id.isNotEmpty && e.id != estateId)
          .take(4)
          .toList();
      return estates;
    } catch (_) {}
    return const <EstateItem>[];
  }

  Future<List<dynamic>> _getPublicListingsSnapshot({int limit = 40}) async {
    final now = DateTime.now();
    final cache = _publicListingsCache;
    final cacheAt = _publicListingsCacheAt;
    final hasFreshCache = cache != null &&
        cacheAt != null &&
        now.difference(cacheAt) <= _publicListingsCacheTtl;
    if (hasFreshCache) {
      return List<dynamic>.from(cache);
    }

    final inFlight = _publicListingsInFlight;
    if (inFlight != null) {
      try {
        return List<dynamic>.from(await inFlight);
      } catch (_) {
        if (cache != null) return List<dynamic>.from(cache);
        rethrow;
      }
    }

    final request = _apiClient.getJsonList('/public/listings', query: {
      'limit': limit,
      'include': 'types,categories',
    });
    _publicListingsInFlight = request;
    try {
      final response = await request;
      _publicListingsCache = List<dynamic>.from(response);
      _publicListingsCacheAt = DateTime.now();
      return List<dynamic>.from(response);
    } catch (_) {
      if (cache != null) return List<dynamic>.from(cache);
      rethrow;
    } finally {
      if (identical(_publicListingsInFlight, request)) {
        _publicListingsInFlight = null;
      }
    }
  }

  List<EstateItem> _parseEstates(List<dynamic> response) {
    return response
        .whereType<Map<String, dynamic>>()
        .map(_toEstateItem)
        .where((e) => e.id.isNotEmpty)
        .toList();
  }

  EstateItem _toEstateItem(Map<String, dynamic> json) {
    final images = json['images'];
    String imageUrl = '';
    if (images is List && images.isNotEmpty) {
      imageUrl = '${images.first}';
    } else if (json['imageUrl'] != null) {
      imageUrl = '${json['imageUrl']}';
    } else if (json['image_url'] != null) {
      imageUrl = '${json['image_url']}';
    }

    final address = '${json['address'] ?? json['location'] ?? ''}'.trim();
    final sellPrice = _toDouble(json['sell_price']);
    final rentPrice = _toDouble(json['rent_price']);
    final price = sellPrice > 0 ? sellPrice : (rentPrice > 0 ? rentPrice : _toDouble(json['price']));

    String? category;
    final propertyCategories = json['propertyCategories'] ?? json['property_categories'];
    if (propertyCategories is List && propertyCategories.isNotEmpty) {
      final first = propertyCategories.first;
      if (first is Map) {
        category = '${first['name_en'] ?? first['name_so'] ?? ''}'.trim();
      }
    }
    final types = json['listingTypes'] ?? json['listing_types'];
    if ((category == null || category.isEmpty) && types is List && types.isNotEmpty) {
      final first = types.first;
      if (first is Map) {
        category = '${first['name_en'] ?? first['name_so'] ?? ''}'.trim();
      }
    }

    final lat = json['lat'] != null
        ? _toDouble(json['lat'])
        : (json['latitude'] != null ? _toDouble(json['latitude']) : null);
    final lng = json['lng'] != null
        ? _toDouble(json['lng'])
        : (json['longitude'] != null ? _toDouble(json['longitude']) : null);

    return EstateItem(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      location: address,
      price: price,
      imageUrl: imageUrl,
      rating: json['rating'] == null ? null : _toDouble(json['rating']),
      category: category?.isNotEmpty == true ? category : null,
      lat: lat,
      lng: lng,
      rentPrice: rentPrice > 0 ? rentPrice : null,
      sellPrice: sellPrice > 0 ? sellPrice : null,
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  String _extractLocationName(String address) {
    if (address.isEmpty) return '';
    final segments = address.split(',');
    if (segments.length >= 2) {
      return segments.sublist(segments.length - 2).join(',').trim();
    }
    return address.trim();
  }
}
