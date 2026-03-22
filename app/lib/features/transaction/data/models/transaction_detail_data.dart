class TransactionDetailData {
  const TransactionDetailData({
    required this.id,
    required this.listingId,
    required this.propertyTitle,
    required this.location,
    required this.category,
    required this.imageUrl,
    required this.statusLabel,
    required this.statusAccentValue,
    required this.sellerName,
    required this.sellerAvatarUrl,
    required this.sellerRating,
    required this.sellerSoldCount,
    required this.checkInLabel,
    required this.checkOutLabel,
    required this.ownerName,
    required this.transactionType,
    required this.periodLabel,
    required this.monthlyPayment,
    required this.discount,
    required this.total,
    required this.paymentLabel,
    required this.issueOptions,
    required this.canAddReview,
  });

  final String id;
  final String listingId;
  final String propertyTitle;
  final String location;
  final String category;
  final String imageUrl;
  final String statusLabel;
  final int statusAccentValue;
  final String sellerName;
  final String sellerAvatarUrl;
  final double sellerRating;
  final int sellerSoldCount;
  final String checkInLabel;
  final String checkOutLabel;
  final String ownerName;
  final String transactionType;
  final double monthlyPayment;
  final double discount;
  final double total;
  final String periodLabel;
  final String paymentLabel;
  final List<String> issueOptions;
  final bool canAddReview;

  factory TransactionDetailData.fallback(String id) {
    return TransactionDetailData(
      id: id,
      listingId: '1',
      propertyTitle: 'Sky Dandelions Apartment',
      location: 'Jakarta, Indonesia',
      category: 'Apartment',
      imageUrl: '',
      statusLabel: 'Canceled & Refunded',
      statusAccentValue: 0xFFE71704,
      sellerName: 'Amanda',
      sellerAvatarUrl: '',
      sellerRating: 5,
      sellerSoldCount: 112,
      checkInLabel: '11/28/2021',
      checkOutLabel: '01/28/2022',
      ownerName: 'Anderson',
      transactionType: 'Rent',
      periodLabel: '2 month',
      monthlyPayment: 220,
      discount: 88,
      total: 31250,
      paymentLabel: '••••••an@email.com',
      issueOptions: const [
        'Property not handed over',
        'Documents not received',
        'Property doesn\'t match description',
        'Seller unresponsive',
        'Other (describe below)',
      ],
      canAddReview: true,
    );
  }
}
