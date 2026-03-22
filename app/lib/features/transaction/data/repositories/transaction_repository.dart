import 'dart:io';

import '../../../../core/network/api_client.dart';
import '../models/booking_summary.dart';
import '../models/transaction_detail_data.dart';
import '../models/transaction_history_item.dart';

class TransactionRepository {
  TransactionRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<BookingSummary> getBookingSummary({String? estateId}) async {
    try {
      final listing = await _resolveListing(estateId);
      final me = await _currentUser();
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
      final discount = _toDouble(quote['discount']);
      final total = _toDouble(quote['total']);
      final paymentLabel = await _defaultPaymentLabel(
        userId: '${me?['id'] ?? ''}',
        fallbackEmail: '${me?['email'] ?? ''}',
      );

      final summary = BookingSummary(
        propertyTitle: '${listing['title'] ?? ''}'.trim().isEmpty ? 'Sky Dandelions Apartment' : '${listing['title'] ?? ''}',
        location: '${listing['address'] ?? ''}'.trim().isEmpty ? 'Jakarta, Indonesia' : '${listing['address'] ?? ''}',
        category: '${listing['category'] ?? 'Apartment'}',
        imageUrl: _extractImageUrl(listing),
        price: subtotal > 0 ? subtotal : _fallbackPrice(listing),
        duration: _durationLabel(rentType),
        discount: discount,
        total: total > 0 ? total : (subtotal > 0 ? subtotal - discount : _fallbackPrice(listing)),
        paymentLabel: paymentLabel,
      );
      return summary;
    } catch (_) {
      return const BookingSummary(
        propertyTitle: 'Sky Dandelions Apartment',
        location: 'Jakarta, Indonesia',
        category: 'Apartment',
        imageUrl: '',
        price: 220,
        duration: '2 month',
        discount: 88,
        total: 31250,
        paymentLabel: '••••••an@email.com',
      );
    }
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
      if (availability['available'] != true) return false;

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

  Future<List<TransactionHistoryItem>> getTransactionHistory() async {
    try {
      final me = await _currentUser();
      final currentUserId = '${me?['id'] ?? ''}';
      final response = await _apiClient.getJson('/listing-rentals', query: {'limit': 20});
      final data = response['data'];
      if (data is List) {
        final items = data
            .whereType<Map<String, dynamic>>()
            .map((raw) => _toHistoryItem(raw, currentUserId))
            .toList();
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}
    return const [
      TransactionHistoryItem(id: '1', title: 'Sell', dateLabel: '12-12-2025', amount: 5999, isIncome: true),
      TransactionHistoryItem(id: '2', title: 'Ad Promotion', dateLabel: '12-12-2025', amount: 5.99, isIncome: false),
      TransactionHistoryItem(id: '3', title: 'Rent', dateLabel: '12-12-2025', amount: 5999, isIncome: true),
      TransactionHistoryItem(id: '4', title: 'Refunded', dateLabel: '12-12-2025', amount: 5.99, isIncome: false),
    ];
  }

  Future<TransactionDetailData> getTransactionDetail(String transactionId) async {
    try {
      final rental = await _apiClient.getJson('/listing-rentals/$transactionId');
      return _toDetailData(rental);
    } catch (_) {
      return TransactionDetailData.fallback(transactionId);
    }
  }

  Future<bool> submitReview({
    required String listingId,
    required int rating,
    required String comment,
    List<String> imagePaths = const [],
  }) async {
    try {
      final me = await _currentUser();
      final userId = int.tryParse('${me?['id'] ?? ''}');
      final listId = int.tryParse(listingId);
      if (userId == null || listId == null) return false;
      final uploaded = await _uploadImages(imagePaths);
      await _apiClient.postJson('/listing-reviews', body: {
        'listing_id': listId,
        'user_id': userId,
        'rating': rating,
        'comment': comment.trim(),
        'images': uploaded,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  TransactionHistoryItem _toHistoryItem(Map<String, dynamic> raw, String currentUserId) {
    final listing = raw['listing'] is Map<String, dynamic> ? raw['listing'] as Map<String, dynamic> : const <String, dynamic>{};
    final isOwner = '${listing['user_id'] ?? ''}' == currentUserId;
    final status = '${raw['status'] ?? ''}'.toLowerCase();
    final amount = _toDouble(raw['total']);
    final isIncome = isOwner && status != 'cancelled';
    String title = isOwner ? 'Rent' : 'Booking';
    if (status == 'cancelled') {
      title = 'Refunded';
    } else if ('${raw['rent_type'] ?? ''}'.toLowerCase() == 'yearly') {
      title = 'Sell';
    }
    return TransactionHistoryItem(
      id: '${raw['id'] ?? ''}',
      title: title,
      dateLabel: _formatHistoryDate(raw['createdAt'] ?? raw['date']),
      amount: amount > 0 ? amount : 5999,
      isIncome: isIncome,
    );
  }

  TransactionDetailData _toDetailData(Map<String, dynamic> raw) {
    final listing = raw['listing'] is Map<String, dynamic> ? raw['listing'] as Map<String, dynamic> : const <String, dynamic>{};
    final renter = raw['renter'] is Map<String, dynamic> ? raw['renter'] as Map<String, dynamic> : const <String, dynamic>{};
    final status = '${raw['status'] ?? ''}'.toLowerCase();
    return TransactionDetailData(
      id: '${raw['id'] ?? ''}',
      listingId: '${listing['id'] ?? ''}',
      propertyTitle: '${listing['title'] ?? ''}'.trim().isEmpty ? 'Sky Dandelions Apartment' : '${listing['title'] ?? ''}',
      location: '${listing['address'] ?? ''}'.trim().isEmpty ? 'Jakarta, Indonesia' : '${listing['address'] ?? ''}',
      category: '${listing['category'] ?? 'Apartment'}',
      imageUrl: _extractImageUrl(listing),
      statusLabel: _statusLabel(status),
      statusAccentValue: status == 'cancelled' ? 0xFFE71704 : 0xFFE7B904,
      sellerName: '${renter['name'] ?? listing['owner_name'] ?? 'Amanda'}',
      sellerAvatarUrl: '${renter['profile_picture_url'] ?? ''}',
      sellerRating: 5,
      sellerSoldCount: 112,
      checkInLabel: _formatDetailDate(raw['start_date']),
      checkOutLabel: _formatDetailDate(raw['end_date']),
      ownerName: '${renter['name'] ?? 'Anderson'}',
      transactionType: _capitalize('${raw['rent_type'] ?? 'Rent'}'),
      periodLabel: _durationLabel('${raw['rent_type'] ?? listing['rent_type'] ?? 'monthly'}'),
      monthlyPayment: _toDouble(raw['subtotal']) > 0 ? _toDouble(raw['subtotal']) : _toDouble(listing['rent_price']),
      discount: _toDouble(raw['discount']),
      total: _toDouble(raw['total']) > 0 ? _toDouble(raw['total']) : _toDouble(raw['subtotal']),
      paymentLabel: _paymentLabelFromRental(raw, renterEmail: '${renter['email'] ?? ''}'),
      issueOptions: const [
        'Property not handed over',
        'Documents not received',
        'Property doesn\'t match description',
        'Seller unresponsive',
        'Other (describe below)',
      ],
      canAddReview: status == 'completed' || status == 'confirmed' || status == 'pending',
    );
  }

  Future<Map<String, dynamic>?> _currentUser() async {
    try {
      final me = await _apiClient.getJson('/auth/me');
      final user = me['user'];
      return user is Map<String, dynamic> ? user : null;
    } catch (_) {
      return null;
    }
  }

  Future<String> _defaultPaymentLabel({
    required String userId,
    required String fallbackEmail,
  }) async {
    try {
      final id = int.tryParse(userId);
      if (id == null) return _maskEmail(fallbackEmail);
      final response = await _apiClient.getJson('/user-bank-accounts', query: {
        'user_id': id,
        'limit': 5,
      });
      final data = response['data'];
      if (data is List) {
        final accounts = data.whereType<Map<String, dynamic>>().toList();
        if (accounts.isNotEmpty) {
          accounts.sort((a, b) => ('${b['is_default']}' == 'true' ? 1 : 0).compareTo('${a['is_default']}' == 'true' ? 1 : 0));
          final item = accounts.first;
          final bank = '${item['bank_name'] ?? ''}'.toLowerCase();
          if (bank.contains('paypal')) return _maskEmail(fallbackEmail);
          return '•••• ${_last4('${item['account_no'] ?? ''}')}';
        }
      }
    } catch (_) {}
    return _maskEmail(fallbackEmail.isEmpty ? 'an@email.com' : fallbackEmail);
  }

  String _paymentLabelFromRental(Map<String, dynamic> raw, {required String renterEmail}) {
    final bankName = '${raw['bank_name'] ?? ''}'.toLowerCase();
    if (bankName.contains('paypal')) return _maskEmail(renterEmail.isEmpty ? 'an@email.com' : renterEmail);
    final bankAccount = '${raw['bank_account'] ?? ''}';
    if (bankAccount.isNotEmpty) return '•••• ${_last4(bankAccount)}';
    return _maskEmail(renterEmail.isEmpty ? 'an@email.com' : renterEmail);
  }

  Future<List<String>> _uploadImages(List<String> imagePaths) async {
    final urls = <String>[];
    for (final path in imagePaths) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        urls.add(path);
        continue;
      }
      final file = File(path);
      if (!await file.exists()) continue;
      try {
        final response = await _apiClient.postMultipartFile('/upload/profile-image', file);
        final url = _extractUploadedUrl(response);
        if (url != null && url.isNotEmpty) urls.add(url);
      } catch (_) {}
    }
    return urls;
  }

  String? _extractUploadedUrl(Map<String, dynamic> response) {
    for (final key in ['url', 'image_url', 'imageUrl', 'path']) {
      final value = response[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      for (final key in ['url', 'image_url', 'imageUrl', 'path']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    }
    return null;
  }

  double _fallbackPrice(Map<String, dynamic> listing) {
    final rent = _toDouble(listing['rent_price']);
    if (rent > 0) return rent;
    return _toDouble(listing['sell_price']);
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  _DateRange _defaultDateRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final end = start.add(const Duration(days: 60));
    return _DateRange(start: start, end: end);
  }

  String _defaultRentTypeForListing(Map<String, dynamic> listing) {
    final raw = '${listing['rent_type'] ?? ''}'.toLowerCase();
    if (raw == 'daily' || raw == 'monthly' || raw == 'yearly') return raw;
    return 'monthly';
  }

  String _durationLabel(String rentType) {
    switch (rentType.toLowerCase()) {
      case 'daily':
        return '30 days';
      case 'yearly':
        return '1 year';
      default:
        return '2 month';
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

  String _extractImageUrl(Map<String, dynamic> listing) {
    final images = listing['images'];
    if (images is List && images.isNotEmpty) {
      final first = '${images.first}';
      if (first.isNotEmpty) return first;
    }
    for (final key in ['image_url', 'imageUrl', 'thumbnail']) {
      final value = '${listing[key] ?? ''}'.trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'cancelled':
        return 'Canceled & Refunded';
      case 'completed':
        return 'Completed';
      case 'confirmed':
        return 'Confirmed';
      default:
        return 'Pending';
    }
  }

  String _formatHistoryDate(dynamic value) {
    final date = DateTime.tryParse('$value');
    if (date == null) return '12-12-2025';
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _formatDetailDate(dynamic value) {
    final date = DateTime.tryParse('$value');
    if (date == null) return '11/28/2021';
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  String _maskEmail(String email) {
    final trimmed = email.trim();
    if (!trimmed.contains('@')) return '•••• 4242';
    final parts = trimmed.split('@');
    final name = parts.first;
    final domain = parts.last;
    final visible = name.length <= 2 ? name : name.substring(name.length - 2);
    return '••••••$visible@$domain';
  }

  String _last4(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) return digits;
    return digits.substring(digits.length - 4);
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
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
