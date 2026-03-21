/// Single review on a listing — API + **Figma `28:4414`** mock data.
class ListingReview {
  const ListingReview({
    required this.name,
    required this.rating,
    required this.text,
    required this.dateLabel,
    this.avatarUrl,
    this.imageUrls = const [],
  });

  final String name;
  final int rating;
  final String text;
  final String dateLabel;
  /// `Photos / User - Small` — Figma `28:4414`.
  final String? avatarUrl;
  /// Optional review photos — `Card / Review - Estate` gallery row.
  final List<String> imageUrls;

  factory ListingReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map<String, dynamic> ? user : const <String, dynamic>{};
    final createdAt = DateTime.tryParse('${json['createdAt'] ?? json['created_at'] ?? ''}');
    final avatar = userMap['profile_picture_url'] ?? userMap['avatar_url'] ?? userMap['avatarUrl'];
    final attachments = json['attachments'] ?? json['images'];
    final urls = <String>[];
    if (attachments is List) {
      for (final e in attachments) {
        final s = '$e'.trim();
        if (s.isNotEmpty) urls.add(s);
      }
    }
    return ListingReview(
      name: '${userMap['name'] ?? 'User'}',
      rating: _toInt(json['rating']),
      text: '${json['comment'] ?? json['text'] ?? ''}',
      dateLabel: _dateLabel(createdAt),
      avatarUrl: avatar != null && '$avatar'.trim().isNotEmpty ? '$avatar'.trim() : null,
      imageUrls: urls,
    );
  }

  static List<ListingReview> mockListForListing(String listingId) =>
      mockJsonList(listingId).map((e) => ListingReview.fromJson(e)).toList();

  /// Mock reviews when API returns none — design **node `28:4414`**.
  static List<Map<String, dynamic>> mockJsonList(String listingId) {
    final base = DateTime.now();
    String iso(int daysAgo) => base.subtract(Duration(days: daysAgo)).toIso8601String();
    return [
      {
        'rating': 5,
        'comment':
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        'createdAt': iso(0),
        'user': {
          'name': 'Kurt Mullins',
          'profile_picture_url':
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop',
        },
      },
      {
        'rating': 4,
        'comment':
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        'createdAt': iso(0),
        'user': {
          'name': 'Samuel Ella',
          'profile_picture_url':
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop',
        },
        'attachments': [
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=200&h=200&fit=crop',
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=200&h=200&fit=crop',
          'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=200&h=200&fit=crop',
        ],
      },
      {
        'rating': 5,
        'comment':
            'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperia.',
        'createdAt': iso(1),
        'user': {
          'name': 'Kay Swanson',
          'profile_picture_url':
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&h=200&fit=crop',
        },
      },
      {
        'rating': 4,
        'comment':
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        'createdAt': iso(2),
        'user': {
          'name': 'Samuel Ella',
          'profile_picture_url':
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop',
        },
      },
      {
        'rating': 5,
        'comment':
            'Beautiful apartment, exactly as in the photos. Quiet building and the agent was very responsive. Would rent again.',
        'createdAt': iso(2),
        'user': {'name': 'Amanda Chen'},
      },
      {
        'rating': 4,
        'comment': 'Great location near shops. AC works well. Minor delay on move-in paperwork but overall satisfied.',
        'createdAt': iso(5),
        'user': {'name': 'Marcus Webb'},
      },
      {
        'rating': 5,
        'comment': 'Perfect for our family. Kids love the neighborhood. Parking was a plus.',
        'createdAt': iso(9),
        'user': {'name': 'Sofia Rahman'},
      },
      {
        'rating': 4,
        'comment': 'Clean and modern. Wi‑Fi could be faster; landlord said they will upgrade.',
        'createdAt': iso(14),
        'user': {'name': 'James Okafor'},
      },
      {
        'rating': 5,
        'comment': 'Listing #$listingId matched the description. Smooth viewing and contract process.',
        'createdAt': iso(21),
        'user': {'name': 'Elena Rossi'},
      },
      {
        'rating': 3,
        'comment': 'Decent value. Some street noise in the evening — bring earplugs if you are a light sleeper.',
        'createdAt': iso(30),
        'user': {'name': 'David Kim'},
      },
    ];
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static String _dateLabel(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    if (diff.inHours >= 1) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
    return 'Just now';
  }
}
