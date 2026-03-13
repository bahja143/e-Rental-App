class BookingSummary {
  const BookingSummary({
    required this.propertyTitle,
    required this.location,
    required this.price,
    required this.duration,
    required this.serviceFee,
    required this.paymentLast4,
  });

  final String propertyTitle;
  final String location;
  final double price;
  final String duration;
  final double serviceFee;
  final String paymentLast4;

  double get total => price + serviceFee;

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    return BookingSummary(
      propertyTitle: '${json['propertyTitle'] ?? ''}',
      location: '${json['location'] ?? ''}',
      price: _toDouble(json['price']),
      duration: '${json['duration'] ?? '1 month'}',
      serviceFee: _toDouble(json['serviceFee']),
      paymentLast4: '${json['paymentLast4'] ?? '4242'}',
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
