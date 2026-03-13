import '../../../../core/network/api_client.dart';
import '../models/booking_summary.dart';

class TransactionRepository {
  TransactionRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<BookingSummary> getBookingSummary({String? estateId}) async {
    try {
      final listing = await _resolveListing(estateId);

      if (listing == null) throw Exception('No listing found');

      final dateRange = _defaultDateRange();
      final rentType = _defaultRentTypeForListing(listing);
      final quote = await _apiClient.getJson(
        '/public/listings/${listing['id']}/rental-quote',
        query: {
          'start_date': dateRange.start.toIso8601String(),
          'end_date': dateRange.end.toIso8601String(),
          'rent_type': rentType,
        },
      );

      final subtotal = _toDouble(quote['subtotal']);
      final total = _toDouble(quote['total']);
      final fallbackBasePrice = _toDouble(listing['rent_price']) > 0
          ? _toDouble(listing['rent_price'])
          : _toDouble(listing['sell_price']);
      final basePrice = subtotal > 0 ? subtotal : fallbackBasePrice;
      final serviceFee = total > subtotal && subtotal > 0 ? total - subtotal : basePrice * 0.05;

      final summary = BookingSummary(
        propertyTitle: '${listing['title'] ?? ''}',
        location: '${listing['address'] ?? ''}',
        price: basePrice,
        duration: _durationLabel(rentType),
        serviceFee: serviceFee,
        paymentLast4: '4242',
      );
      if (summary.propertyTitle.isNotEmpty) return summary;
    } catch (_) {
      // Fallback keeps booking flow usable before backend is fully connected.
    }
    return const BookingSummary(
      propertyTitle: 'Modern Apartment',
      location: 'Mogadishu',
      price: 190,
      duration: '1 month',
      serviceFee: 19,
      paymentLast4: '4242',
    );
  }

  Future<bool> confirmBooking({String? estateId}) async {
    try {
      final listing = await _resolveListing(estateId);
      if (listing == null) return false;
      final id = int.tryParse('${listing['id'] ?? ''}');
      if (id == null) return false;

      final rentType = _defaultRentTypeForListing(listing);
      final dateRange = _defaultDateRange();
      final availability = await _apiClient.getJson(
        '/public/listings/$id/availability',
        query: {
          'start_date': dateRange.start.toIso8601String(),
          'end_date': dateRange.end.toIso8601String(),
        },
      );
      if (availability['available'] != true) {
        return false;
      }

      await _apiClient.postJson('/listing-rentals', body: {
        'list_id': id,
        'start_date': dateRange.start.toIso8601String(),
        'end_date': dateRange.end.toIso8601String(),
        'rent_type': rentType,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  _DateRange _defaultDateRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final end = start.add(const Duration(days: 30));
    return _DateRange(start: start, end: end);
  }

  String _defaultRentTypeForListing(Map<String, dynamic> listing) {
    final raw = '${listing['rent_type'] ?? ''}'.toLowerCase();
    if (raw == 'daily' || raw == 'monthly' || raw == 'yearly') return raw;
    return 'monthly';
  }

  String _durationLabel(String rentType) {
    switch (rentType) {
      case 'daily':
        return '30 days';
      case 'yearly':
        return '1 year';
      default:
        return '1 month';
    }
  }

  Future<Map<String, dynamic>?> _resolveListing(String? estateId) async {
    if (estateId != null && estateId.isNotEmpty) {
      return _apiClient.getJson('/public/listings/$estateId');
    }
    final listings = await _apiClient.getJsonList('/public/listings', query: {'limit': 1});
    if (listings.isNotEmpty && listings.first is Map<String, dynamic>) {
      return listings.first as Map<String, dynamic>;
    }
    return null;
  }
}

class _DateRange {
  const _DateRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}
