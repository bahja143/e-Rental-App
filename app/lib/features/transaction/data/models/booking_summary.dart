class BookingSummary {
  const BookingSummary({
    required this.propertyTitle,
    required this.location,
    required this.category,
    required this.imageUrl,
    required this.price,
    required this.duration,
    required this.discount,
    required this.total,
    required this.paymentLabel,
  });

  final String propertyTitle;
  final String location;
  final String category;
  final String imageUrl;
  final double price;
  final String duration;
  final double discount;
  final double total;
  final String paymentLabel;

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    return BookingSummary(
      propertyTitle: '${json['propertyTitle'] ?? ''}',
      location: '${json['location'] ?? ''}',
      category: '${json['category'] ?? 'Apartment'}',
      imageUrl: '${json['imageUrl'] ?? ''}',
      price: _toDouble(json['price']),
      duration: '${json['duration'] ?? '1 month'}',
      discount: _toDouble(json['discount']),
      total: _toDouble(json['total']),
      paymentLabel: '${json['paymentLabel'] ?? '•••• 4242'}',
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
