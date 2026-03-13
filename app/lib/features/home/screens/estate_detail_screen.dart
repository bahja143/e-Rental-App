import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/remote_image.dart';
import '../data/models/estate_item.dart';
import '../data/repositories/estate_repository.dart';
import '../widgets/estate_card.dart';

class EstateDetailScreen extends StatefulWidget {
  const EstateDetailScreen({
    super.key,
    this.estateId = '1',
    this.title = 'Modern Apartment',
    this.location = 'Mogadishu',
    this.price = 190,
    this.imageUrl = 'https://www.figma.com/api/mcp/asset/4313825d-f243-4dfc-9d1e-699a17342288',
    this.description,
  });

  final String estateId;
  final String title;
  final String location;
  final double price;
  final String imageUrl;
  final String? description;

  @override
  State<EstateDetailScreen> createState() => _EstateDetailScreenState();
}

class _EstateDetailScreenState extends State<EstateDetailScreen> {
  final _repo = EstateRepository();
  late final Future<_EstateDetailData> _detailFuture;
  bool _isSaved = false;
  bool _savingFavorite = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final ids = await _repo.getSavedEstateIds();
    if (!mounted) return;
    setState(() => _isSaved = ids.contains(widget.estateId));
  }

  Future<void> _toggleSaved() async {
    if (_savingFavorite) return;
    setState(() => _savingFavorite = true);
    final ok = _isSaved
        ? await _repo.removeSavedEstate(widget.estateId)
        : await _repo.addSavedEstate(widget.estateId);
    if (!mounted) return;
    setState(() {
      _savingFavorite = false;
      if (ok) _isSaved = !_isSaved;
    });
  }

  Future<_EstateDetailData> _loadDetail() async {
    final repo = EstateRepository();
    final listing = await repo.getEstateById(widget.estateId);
    final nearby = await repo.getNearbyFromEstate(widget.estateId);
    final reviews = await repo.getListingReviews(widget.estateId);

    return _EstateDetailData.fromApi(
      listing: listing,
      nearby: nearby,
      reviews: reviews,
      widgetFallback: widget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EstateDetailData>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final data = snapshot.data ?? _EstateDetailData.fallback(widget);
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(context, data),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$ ${data.price.toInt()}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 32),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(data.location, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const SizedBox(height: 18),
                  _buildFactPills(),
                  const SizedBox(height: 18),
                  _buildAgentCard(context, data),
                  const SizedBox(height: 24),
                  _buildTitle(context, 'Location & Public Facilities'),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 145,
                      decoration: BoxDecoration(
                        color: AppColors.greySoft1,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text('View all map', style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTitle(context, 'Facilities'),
                  const SizedBox(height: 10),
                  _buildFacilities(context, data.facilities),
                  const SizedBox(height: 24),
                  _buildTitle(context, 'Description'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: Text(
                      data.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTitle(context, 'Reviews'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.textSecondary, borderRadius: BorderRadius.circular(25)),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.primary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            data.rating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 10),
                          ...List.generate(
                            5,
                            (i) => Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Icon(
                                Icons.star,
                                color: i < data.rating.round() ? AppColors.primary : Colors.white24,
                                size: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (data.reviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'No reviews yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: data.reviews
                            .take(3)
                            .map(
                              (r) => _ReviewTile(
                                name: r.name,
                                rating: r.rating,
                                text: r.text,
                                date: r.dateLabel,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 18),
                  _buildTitle(context, 'Nearby From this Location'),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.63,
                      children: data.nearby
                          .map(
                            (estate) => EstateCard.vertical(
                              title: estate.title,
                              location: estate.location,
                              price: estate.price,
                              rating: estate.rating,
                              imageUrl: estate.imageUrl,
                              onTap: () => context.push(AppRoutes.estateDetail(estate.id)),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push(AppRoutes.chatDetail('0', name: data.agentName)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        side: const BorderSide(color: AppColors.textSecondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Chat', style: Theme.of(context).textTheme.labelLarge),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: 'Book Now',
                      onPressed: () => context.push(AppRoutes.transactionSummaryForEstate(widget.estateId)),
                      height: 56,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero(BuildContext context, _EstateDetailData data) {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          Positioned.fill(
            child: RemoteImage(
              url: data.imageUrl,
              fit: BoxFit.cover,
              errorWidget: Container(color: AppColors.greySoft1, child: const Icon(Icons.home_work, size: 64)),
            ),
          ),
          Positioned(
            left: 24,
            top: 18,
            child: _roundButton(icon: Icons.arrow_back_ios_new, onTap: () => context.pop()),
          ),
          Positioned(
            right: 84,
            top: 18,
            child: _roundButton(icon: Icons.ios_share, onTap: () {}),
          ),
          Positioned(
            right: 24,
            top: 18,
            child: _roundButton(
              icon: _isSaved ? Icons.favorite : Icons.favorite_border,
              onTap: _toggleSaved,
              fill: _isSaved ? AppColors.primary : AppColors.greySoft1,
              iconColor: _isSaved ? Colors.white : AppColors.textPrimary,
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 12,
            child: Row(
              children: [
                _statBadge(data.rating.toStringAsFixed(1)),
                const SizedBox(width: 8),
                _chip('Apartment'),
                const Spacer(),
                _chip('+3'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap, Color fill = AppColors.greySoft1, Color iconColor = AppColors.textPrimary}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF234F68).withValues(alpha: 0.75), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: const TextStyle(fontSize: 8, color: Colors.white)),
    );
  }

  Widget _statBadge(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF234F68).withValues(alpha: 0.75), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.star, size: 10, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(rating, style: const TextStyle(fontSize: 8, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildFactPills() {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: const [
          _SmallPill('1 Bed room'),
          SizedBox(width: 8),
          _SmallPill('1 Bath room'),
          SizedBox(width: 8),
          _SmallPill('1 Living room'),
        ],
      ),
    );
  }

  Widget _buildAgentCard(BuildContext context, _EstateDetailData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.greySoft1,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: ClipOval(
                child: RemoteImage(
                  url: data.agentAvatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: Container(color: AppColors.greySoft2),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.agentName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text('House owner', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8)),
                ],
              ),
            ),
            const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
    );
  }

  Widget _buildFacilities(BuildContext context, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map((e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: const Color(0xFFECEDF3), borderRadius: BorderRadius.circular(100)),
                  child: Text(e, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8)),
                ))
            .toList(),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.name, required this.rating, required this.text, required this.date});

  final String name;
  final int rating;
  final String text;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundColor: AppColors.primary.withValues(alpha: 0.3), child: Text(name[0], style: const TextStyle(color: AppColors.primary))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
                    Row(
                      children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < rating ? AppColors.primary : AppColors.greyBarelyMedium)),
                    ),
                  ],
                ),
              ),
              Text(date, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppColors.greyBarelyMedium)),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.greySoft1, borderRadius: BorderRadius.circular(100)),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8)),
    );
  }
}

class _EstateDetailData {
  const _EstateDetailData({
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.facilities,
    required this.agentName,
    required this.agentAvatarUrl,
    required this.rating,
    required this.reviews,
    required this.nearby,
  });

  factory _EstateDetailData.fallback(EstateDetailScreen widget) {
    return _EstateDetailData(
      title: widget.title,
      location: widget.location,
      price: widget.price,
      imageUrl: widget.imageUrl,
      description: widget.description ??
          'Property Overview\nOwnership Type: freehold / leasehold\nLorem ipsum dolor sit amet, consectetur adipiscing elit.',
      facilities: const ['Parking lot', 'Pet Friendly', 'Garden', 'Gym', 'Park', 'Home theatre'],
      agentName: 'Agent',
      agentAvatarUrl: '',
      rating: 4.8,
      reviews: const [],
      nearby: const [],
    );
  }

  factory _EstateDetailData.fromApi({
    required Map<String, dynamic>? listing,
    required List<EstateItem> nearby,
    required List<Map<String, dynamic>> reviews,
    required EstateDetailScreen widgetFallback,
  }) {
    final data = listing ?? <String, dynamic>{};
    final images = data['images'];
    String imageUrl = widgetFallback.imageUrl;
    if (images is List && images.isNotEmpty) {
      imageUrl = '${images.first}';
    }

    final facilities = <String>[];
    final listingFacilities = data['listingFacilities'];
    if (listingFacilities is List) {
      for (final item in listingFacilities.whereType<Map<String, dynamic>>()) {
        final facility = item['facility'];
        if (facility is Map<String, dynamic>) {
          final name = '${facility['name_en'] ?? facility['name_so'] ?? ''}'.trim();
          if (name.isNotEmpty) facilities.add(name);
        }
      }
    }

    final reviewItems = reviews.map(_ReviewItem.fromJson).toList();
    final avgRating = reviewItems.isEmpty
        ? 4.8
        : reviewItems.map((e) => e.rating.toDouble()).reduce((a, b) => a + b) / reviewItems.length;

    final user = data['user'];
    final userMap = user is Map<String, dynamic> ? user : const <String, dynamic>{};

    return _EstateDetailData(
      title: '${data['title'] ?? widgetFallback.title}',
      location: '${data['address'] ?? widgetFallback.location}',
      price: _toDouble(data['rent_price']) > 0
          ? _toDouble(data['rent_price'])
          : (_toDouble(data['sell_price']) > 0 ? _toDouble(data['sell_price']) : widgetFallback.price),
      imageUrl: imageUrl,
      description: '${data['description'] ?? widgetFallback.description ?? ''}'.trim().isEmpty
          ? 'No description provided.'
          : '${data['description'] ?? widgetFallback.description}',
      facilities: facilities.isEmpty ? const ['Parking lot', 'Pet Friendly'] : facilities,
      agentName: '${userMap['name'] ?? 'Agent'}',
      agentAvatarUrl: '${userMap['profile_picture_url'] ?? ''}',
      rating: avgRating,
      reviews: reviewItems,
      nearby: nearby,
    );
  }

  final String title;
  final String location;
  final double price;
  final String imageUrl;
  final String description;
  final List<String> facilities;
  final String agentName;
  final String agentAvatarUrl;
  final double rating;
  final List<_ReviewItem> reviews;
  final List<EstateItem> nearby;

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}

class _ReviewItem {
  const _ReviewItem({
    required this.name,
    required this.rating,
    required this.text,
    required this.dateLabel,
  });

  factory _ReviewItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map<String, dynamic> ? user : const <String, dynamic>{};
    final createdAt = DateTime.tryParse('${json['createdAt'] ?? ''}');
    return _ReviewItem(
      name: '${userMap['name'] ?? 'User'}',
      rating: _toInt(json['rating']),
      text: '${json['comment'] ?? ''}',
      dateLabel: _dateLabel(createdAt),
    );
  }

  final String name;
  final int rating;
  final String text;
  final String dateLabel;

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
