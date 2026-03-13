class EstateItem {
  const EstateItem({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
    this.rating,
  });

  final String id;
  final String title;
  final String location;
  final double price;
  final String imageUrl;
  final double? rating;

  factory EstateItem.fromJson(Map<String, dynamic> json) {
    return EstateItem(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      location: '${json['location'] ?? ''}',
      price: _toDouble(json['price']),
      imageUrl: '${json['imageUrl'] ?? ''}',
      rating: json['rating'] == null ? null : _toDouble(json['rating']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
