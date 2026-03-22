import '../../home/data/models/estate_item.dart';

class ListingPerformanceData {
  const ListingPerformanceData({
    required this.title,
    required this.location,
    required this.totalViews,
    required this.inquiries,
    required this.saves,
    required this.conversionRate,
    required this.appTraffic,
    required this.shareTraffic,
    required this.adsTraffic,
    required this.earnings,
    required this.properties,
    required this.pending,
    required this.balance,
    required this.chartViews,
    required this.chartConversions,
    this.promotions = const <PromotionInfo>[],
  });

  final String title;
  final String location;
  final int totalViews;
  final int inquiries;
  final int saves;
  final int conversionRate;
  final int appTraffic;
  final int shareTraffic;
  final int adsTraffic;
  final int earnings;
  final int properties;
  final int pending;
  final int balance;
  final List<int> chartViews;
  final List<int> chartConversions;
  final List<PromotionInfo> promotions;
}

class PromotionInfo {
  const PromotionInfo({
    required this.title,
    required this.expiry,
  });

  final String title;
  final String expiry;
}

enum PerformanceRange { daily, weekly, monthly, all }

extension PerformanceRangeLabel on PerformanceRange {
  String get label {
    switch (this) {
      case PerformanceRange.daily:
        return 'Daily';
      case PerformanceRange.weekly:
        return 'Weekly';
      case PerformanceRange.monthly:
        return 'Monthly';
      case PerformanceRange.all:
        return 'All';
    }
  }
}

ListingPerformanceData buildListingPerformanceData(
  EstateItem item, {
  int insightsCount = 11,
  PerformanceRange range = PerformanceRange.monthly,
}) {
  final baseViews = 1400 + (insightsCount * 65) + (item.id.hashCode.abs() % 400);
  final multiplier = switch (range) {
    PerformanceRange.daily => 0.22,
    PerformanceRange.weekly => 0.58,
    PerformanceRange.monthly => 1.0,
    PerformanceRange.all => 1.45,
  };
  final totalViews = (baseViews * multiplier).round();
  final inquiries = (totalViews * 0.48).round();
  final saves = (totalViews * 0.9).round();
  final conversionRate = totalViews == 0 ? 0 : ((inquiries / totalViews) * 100).round().clamp(1, 99);
  final appTraffic = (totalViews * 0.74).round();
  final shareTraffic = (totalViews * 0.23).round();
  final adsTraffic = (totalViews * 0.11).round();
  final price = item.price.round();

  final chartViews = switch (range) {
    PerformanceRange.daily => <int>[2, 4, 3, 5],
    PerformanceRange.weekly => <int>[7, 12, 10, 14],
    PerformanceRange.monthly => <int>[9, 4, 7, 5],
    PerformanceRange.all => <int>[12, 9, 14, 11],
  };
  final chartConversions = switch (range) {
    PerformanceRange.daily => <int>[1, 2, 1, 3],
    PerformanceRange.weekly => <int>[4, 6, 5, 7],
    PerformanceRange.monthly => <int>[5, 2, 4, 3],
    PerformanceRange.all => <int>[7, 5, 8, 6],
  };

  return ListingPerformanceData(
    title: item.title,
    location: item.location,
    totalViews: totalViews,
    inquiries: inquiries,
    saves: saves,
    conversionRate: conversionRate,
    appTraffic: appTraffic,
    shareTraffic: shareTraffic,
    adsTraffic: adsTraffic,
    earnings: price * 34,
    properties: 10 + (item.id.hashCode.abs() % 6),
    pending: price * 11,
    balance: price * 28,
    chartViews: chartViews,
    chartConversions: chartConversions,
    promotions: const <PromotionInfo>[
      PromotionInfo(title: 'Featured on Homepage', expiry: '12/12/25'),
      PromotionInfo(title: 'Top of Search', expiry: '12/12/25'),
    ],
  );
}
