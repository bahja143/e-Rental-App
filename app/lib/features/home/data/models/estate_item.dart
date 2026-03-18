class EstateItem {
  const EstateItem({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
    this.rating,
    this.category,
  });

  final String id;
  final String title;
  final String location;
  final double price;
  final String imageUrl;
  final double? rating;
  final String? category;

  /// Derive category from title when not provided (e.g. "Sky Dandelions Apartment" -> "Apartment").
  String? get displayCategory {
    if (category != null && category!.isNotEmpty) return category;
    final t = title.toLowerCase();
    if (t.contains('apartment')) return 'Apartment';
    if (t.contains('villa')) return 'Villa';
    if (t.contains('bungalow')) return 'Bungalow';
    if (t.contains('house')) return 'House';
    return null;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
