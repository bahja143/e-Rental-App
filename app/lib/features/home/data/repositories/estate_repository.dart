import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_session.dart';
import '../models/estate_item.dart';
import '../models/top_agent_item.dart';
import '../models/top_location_item.dart';

class EstateRepository {
  EstateRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<EstateItem>> getSavedEstates() async {
    var requestSucceeded = false;
    try {
      final favourites = await _apiClient.getJsonList('/favourites', query: {'limit': 50});
      requestSucceeded = true;
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
    } catch (_) {
      // Fallback keeps app usable while backend endpoint is being connected.
    }
    if (requestSucceeded) return const <EstateItem>[];
    return _fallbackSavedEstates;
  }

  Future<bool> removeSavedEstate(String listingId) async {
    final userId = ApiSession.currentUserId;
    if (userId == null || userId.isEmpty || listingId.isEmpty) {
      return false;
    }
    try {
      await _apiClient.deleteJson('/favourites/$userId/$listingId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addSavedEstate(String listingId) async {
    if (listingId.isEmpty) return false;
    try {
      await _apiClient.postJson('/favourites', body: {
        'listing_id': int.tryParse(listingId) ?? listingId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Set<String>> getSavedEstateIds() async {
    try {
      final favourites = await _apiClient.getJsonList('/favourites', query: {'limit': 100});
      return favourites
          .whereType<Map<String, dynamic>>()
          .map((fav) => fav['listing'])
          .whereType<Map<String, dynamic>>()
          .map((listing) => '${listing['id'] ?? ''}')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<List<EstateItem>> getFeaturedEstates() async {
    var requestSucceeded = false;
    try {
      final response = await _apiClient.getJsonList('/public/listings', query: {'limit': 20});
      requestSucceeded = true;
      final estates = _parseEstates(response);
      if (estates.isNotEmpty) return estates;
      return const <EstateItem>[];
    } catch (_) {}
    if (requestSucceeded) return const <EstateItem>[];
    return _fallbackFeaturedEstates;
  }

  Future<List<EstateItem>> getNearbyEstates() async {
    var requestSucceeded = false;
    try {
      final response = await _apiClient.getJsonList('/public/listings', query: {'limit': 20});
      requestSucceeded = true;
      final estates = _parseEstates(response);
      if (estates.isNotEmpty) return estates;
      return const <EstateItem>[];
    } catch (_) {}
    if (requestSucceeded) return const <EstateItem>[];
    return _fallbackNearbyEstates;
  }

  Future<List<EstateItem>> searchEstates(String query) async {
    var requestSucceeded = false;
    try {
      final response = await _apiClient.getJsonList('/public/listings', query: {'search': query, 'limit': 20});
      requestSucceeded = true;
      final estates = _parseEstates(response);
      if (estates.isNotEmpty) return estates;
      return const <EstateItem>[];
    } catch (_) {}
    if (requestSucceeded) return const <EstateItem>[];
    return _fallbackSearchEstates;
  }

  Future<List<TopLocationItem>> getTopLocations() async {
    var requestSucceeded = false;
    try {
      final response = await _apiClient.getJsonList('/public/listings', query: {'limit': 40});
      requestSucceeded = true;
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
      if (locations.isNotEmpty) return locations;
      return const <TopLocationItem>[];
    } catch (_) {}
    if (requestSucceeded) return const <TopLocationItem>[];
    return _fallbackTopLocations;
  }

  Future<List<TopAgentItem>> getTopAgents() async {
    var requestSucceeded = false;
    try {
      final response = await _apiClient.getJsonList('/public/listings', query: {'limit': 40});
      requestSucceeded = true;
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
      if (agents.isNotEmpty) return agents;
      return const <TopAgentItem>[];
    } catch (_) {}
    if (requestSucceeded) return const <TopAgentItem>[];
    return _fallbackTopAgents;
  }

  Future<Map<String, dynamic>?> getEstateById(String estateId) async {
    try {
      final response = await _apiClient.getJson('/public/listings/$estateId');
      if ('${response['id'] ?? ''}'.isNotEmpty) return response;
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> getListingReviews(String estateId) async {
    try {
      final response = await _apiClient.getJsonList(
        '/listing-reviews',
        query: {'listing_id': estateId, 'limit': 20},
      );
      return response.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<EstateItem>> getNearbyFromEstate(String estateId) async {
    var requestSucceeded = false;
    try {
      final response = await _apiClient.getJsonList('/public/listings', query: {'limit': 12});
      requestSucceeded = true;
      final estates = response
          .whereType<Map<String, dynamic>>()
          .map(_toEstateItem)
          .where((e) => e.id.isNotEmpty && e.id != estateId)
          .take(4)
          .toList();
      if (estates.isNotEmpty) return estates;
      return const <EstateItem>[];
    } catch (_) {}
    if (requestSucceeded) return const <EstateItem>[];
    return _fallbackNearbyEstates.take(4).toList();
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

    return EstateItem(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      location: address,
      price: price,
      imageUrl: imageUrl,
      rating: json['rating'] == null ? null : _toDouble(json['rating']),
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

  static const List<EstateItem> _fallbackSavedEstates = [
    EstateItem(
      id: '1',
      title: 'Flower Heaven House',
      location: 'Bali, Indonesia',
      price: 370,
      imageUrl: 'https://www.figma.com/api/mcp/asset/287cbe40-257d-4858-9e2e-9a8c01de893a',
      rating: 4.7,
    ),
    EstateItem(
      id: '2',
      title: 'The Overdale Apartment',
      location: 'Jakarta, Indonesia',
      price: 290,
      imageUrl: 'https://www.figma.com/api/mcp/asset/196009a7-dad1-47eb-a36b-015d44845b7a',
      rating: 4.8,
    ),
    EstateItem(
      id: '3',
      title: 'Brookvale Villa',
      location: 'Jakarta, Indonesia',
      price: 320,
      imageUrl: 'https://www.figma.com/api/mcp/asset/15855b80-c86c-4a44-8e3c-36edc38728ef',
      rating: 5.0,
    ),
  ];

  static const List<EstateItem> _fallbackFeaturedEstates = [
    EstateItem(
      id: '101',
      title: 'Sky Dandelions Apartment',
      location: 'Jakarta, Indonesia',
      price: 290,
      imageUrl: 'https://www.figma.com/api/mcp/asset/bde4e198-8bfa-4ef7-bb5e-3ae6c4a73592',
      rating: 4.9,
    ),
    EstateItem(
      id: '102',
      title: 'Mill Sper House',
      location: 'Jakarta, Indonesia',
      price: 271,
      imageUrl: 'https://www.figma.com/api/mcp/asset/405837a1-6d0e-46e5-9242-c160f4a48f09',
      rating: 4.8,
    ),
  ];

  static const List<EstateItem> _fallbackNearbyEstates = [
    EstateItem(
      id: '201',
      title: 'Wings Tower',
      location: 'Jakarta, Indonesia',
      price: 220,
      imageUrl: 'https://www.figma.com/api/mcp/asset/bde4e198-8bfa-4ef7-bb5e-3ae6c4a73592',
      rating: 4.9,
    ),
    EstateItem(
      id: '202',
      title: 'Mill Sper House',
      location: 'Jakarta, Indonesia',
      price: 271,
      imageUrl: 'https://www.figma.com/api/mcp/asset/405837a1-6d0e-46e5-9242-c160f4a48f09',
      rating: 4.8,
    ),
    EstateItem(
      id: '203',
      title: 'Bridgeland Modern House',
      location: 'Semarang, Indonesia',
      price: 260,
      imageUrl: 'https://www.figma.com/api/mcp/asset/44749882-3416-4060-acc7-3e7953fdede5',
      rating: 4.7,
    ),
    EstateItem(
      id: '204',
      title: 'Flower Heaven Apartment',
      location: 'Bali, Indonesia',
      price: 370,
      imageUrl: 'https://www.figma.com/api/mcp/asset/477bfe3b-5167-4a49-a126-134d593b70b5',
      rating: 4.9,
    ),
  ];

  static const List<EstateItem> _fallbackSearchEstates = [
    EstateItem(
      id: '301',
      title: 'Bungalow House',
      location: 'Jakarta, Indonesia',
      price: 235,
      imageUrl: 'https://www.figma.com/api/mcp/asset/300aee5e-f567-4697-b22e-c21d4f650b05',
      rating: 4.7,
    ),
    EstateItem(
      id: '302',
      title: 'Bridgeland Modern House',
      location: 'Semarang, Indonesia',
      price: 260,
      imageUrl: 'https://www.figma.com/api/mcp/asset/e4dc8313-46ee-4d2c-b641-00417db80d6c',
      rating: 4.9,
    ),
    EstateItem(
      id: '303',
      title: 'Mill Sper House',
      location: 'Jakarta, Indonesia',
      price: 271,
      imageUrl: 'https://www.figma.com/api/mcp/asset/636ac4a4-a1a5-461a-8639-576a12397eae',
      rating: 4.8,
    ),
    EstateItem(
      id: '304',
      title: 'Flower Heaven Apartment',
      location: 'Bali, Indonesia',
      price: 370,
      imageUrl: 'https://www.figma.com/api/mcp/asset/3515ef49-6b18-486e-823c-f26d397ebf4d',
      rating: 4.7,
    ),
  ];

  static const List<TopLocationItem> _fallbackTopLocations = [
    TopLocationItem(
      name: 'Bali',
      avatarUrl: 'https://www.figma.com/api/mcp/asset/ec918139-6bd9-40dd-b319-ed690fc4a9f2',
    ),
    TopLocationItem(
      name: 'Jakarta',
      avatarUrl: 'https://www.figma.com/api/mcp/asset/14f407e0-9528-4af0-af3a-1426c7fe4b43',
    ),
    TopLocationItem(
      name: 'Yogyakarta',
      avatarUrl: 'https://www.figma.com/api/mcp/asset/ef3cb24b-a64f-4cc2-8509-5ae33e6b000b',
    ),
  ];

  static const List<TopAgentItem> _fallbackTopAgents = [
    TopAgentItem(
      id: 'a1',
      name: 'Amanda',
      avatarUrl: 'https://www.figma.com/api/mcp/asset/402afd5f-35ea-481d-a8fe-ba2d6f65e6e6',
    ),
    TopAgentItem(
      id: 'a2',
      name: 'Anderson',
      avatarUrl: 'https://www.figma.com/api/mcp/asset/dbe2d095-4b7f-4e65-9331-b7f3ac5301af',
    ),
    TopAgentItem(
      id: 'a3',
      name: 'Samantha',
      avatarUrl: 'https://www.figma.com/api/mcp/asset/3e5fccad-d890-4711-9064-45db6ddc7229',
    ),
    TopAgentItem(
      id: 'a4',
      name: 'Andrew',
      avatarUrl: 'https://www.figma.com/api/mcp/asset/ade435f9-615c-4b22-8293-eb45b30823e1',
    ),
  ];
}
