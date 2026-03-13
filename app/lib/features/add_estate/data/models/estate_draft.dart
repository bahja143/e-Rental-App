class EstateDraft {
  const EstateDraft({
    required this.title,
    required this.description,
    required this.location,
    required this.pricePerMonth,
  });

  final String title;
  final String description;
  final String location;
  final double pricePerMonth;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'pricePerMonth': pricePerMonth,
    };
  }
}
