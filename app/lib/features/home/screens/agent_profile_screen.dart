import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/remote_image.dart';
import '../data/repositories/estate_repository.dart';
import '../widgets/estate_card.dart';

/// Agent profile with their listings
class AgentProfileScreen extends StatefulWidget {
  const AgentProfileScreen({
    super.key,
    this.agentId = '1',
    this.name = 'Amanda',
    this.email = 'amanda.trust@email.com',
    this.avatarUrl = 'https://www.figma.com/api/mcp/asset/654236e4-56ee-45ef-94a3-fd5669941a10',
  });

  final String agentId;
  final String name;
  final String email;
  final String? avatarUrl;

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  final _estateRepo = EstateRepository();
  late final Future<_AgentProfileData> _profileFuture;
  Set<String> _savedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _loadSavedIds();
  }

  Future<void> _loadSavedIds() async {
    final ids = await _estateRepo.getSavedEstateIds();
    if (!mounted) return;
    setState(() => _savedIds = ids);
  }

  Future<void> _toggleSaved(String listingId) async {
    if (listingId.isEmpty) return;
    final isSaved = _savedIds.contains(listingId);
    final ok = isSaved
        ? await _estateRepo.removeSavedEstate(listingId)
        : await _estateRepo.addSavedEstate(listingId);
    if (!mounted || !ok) return;
    setState(() {
      if (isSaved) {
        _savedIds.remove(listingId);
      } else {
        _savedIds.add(listingId);
      }
    });
  }

  Future<_AgentProfileData> _loadProfile() async {
    final api = ApiClient();
    try {
      final user = await api.getJson('/users/${widget.agentId}');
      final listingsRaw = await api.getJsonList('/public/listings', query: {
        'user_id': widget.agentId,
        'limit': 40,
      });
      List<dynamic> reviewsRaw = const [];
      try {
        reviewsRaw = await api.getJsonList('/listing-reviews', query: {
          'user_id': widget.agentId,
          'limit': 200,
        });
      } catch (_) {}

      final listings = listingsRaw
          .whereType<Map<String, dynamic>>()
          .map(_AgentListing.fromJson)
          .where((e) => e.id.isNotEmpty)
          .toList();
      final reviews = reviewsRaw.whereType<Map<String, dynamic>>().toList();
      final reviewCount = reviews.length;
      final rating = reviewCount == 0
          ? 5.0
          : reviews
                  .map((e) => _toDouble(e['rating']))
                  .reduce((a, b) => a + b) /
              reviewCount;

      final sold = listingsRaw.whereType<Map<String, dynamic>>().where((e) => '${e['availability'] ?? '1'}' != '1').length;

      return _AgentProfileData(
        id: '${user['id'] ?? widget.agentId}',
        name: '${user['name'] ?? widget.name}',
        email: '${user['email'] ?? widget.email}',
        avatarUrl: '${user['profile_picture_url'] ?? widget.avatarUrl ?? ''}',
        rating: rating,
        reviewCount: reviewCount,
        soldCount: sold,
        listings: listings,
      );
    } catch (_) {
      return _AgentProfileData.fallback(widget);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return FutureBuilder<_AgentProfileData>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        final data = snapshot.data ?? _AgentProfileData.fallback(widget);
        return Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(24, 6, 24, 18),
            child: SizedBox(
              height: 62,
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.chatDetail('0', name: data.name)),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFE7B904),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Start Chat',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _circleActionButton(Icons.arrow_back_ios_new, onTap: context.pop),
                      const Spacer(),
                      Text(
                        'Profile',
                        style: text.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _circleActionButton(Icons.ios_share_outlined, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Text(data.name, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 30)),
                        const SizedBox(height: 4),
                        Text(
                          data.email,
                          style: text.bodySmall?.copyWith(fontSize: 16, color: AppColors.greyMedium),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: ClipOval(
                            child: RemoteImage(
                              url: data.avatarUrl,
                              fit: BoxFit.cover,
                              errorWidget: Container(color: AppColors.greySoft1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(child: _StatCard(title: data.rating.toStringAsFixed(1), subtitle: '☆☆☆☆☆', highlighted: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(title: '${data.reviewCount}', subtitle: 'Reviews')),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(title: '${data.soldCount}', subtitle: 'Sold')),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${data.listings.length} ',
                              style: text.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 34,
                              ),
                            ),
                            TextSpan(
                              text: 'listings',
                              style: text.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.59,
                    ),
                    itemCount: data.listings.length,
                    itemBuilder: (_, i) {
                      final listing = data.listings[i];
                      return EstateCard.vertical(
                        title: listing.title,
                        location: listing.location,
                        price: listing.price,
                        imageUrl: listing.imageUrl,
                        isSaved: _savedIds.contains(listing.id),
                        onToggleSaved: () => _toggleSaved(listing.id),
                        onTap: () => context.push(AppRoutes.estateDetail(listing.id)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _circleActionButton(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: onTap,
      child: Ink(
        width: 50,
        height: 50,
        decoration: BoxDecoration(color: AppColors.greySoft1, borderRadius: BorderRadius.circular(25)),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

class _AgentProfileData {
  const _AgentProfileData({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.rating,
    required this.reviewCount,
    required this.soldCount,
    required this.listings,
  });

  factory _AgentProfileData.fallback(AgentProfileScreen widget) {
    return _AgentProfileData(
      id: widget.agentId,
      name: widget.name,
      email: widget.email,
      avatarUrl: widget.avatarUrl ?? '',
      rating: 5.0,
      reviewCount: 0,
      soldCount: 0,
      listings: const [],
    );
  }

  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final double rating;
  final int reviewCount;
  final int soldCount;
  final List<_AgentListing> listings;
}

class _AgentListing {
  const _AgentListing({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
  });

  factory _AgentListing.fromJson(Map<String, dynamic> json) {
    final images = json['images'];
    String imageUrl = '';
    if (images is List && images.isNotEmpty) {
      imageUrl = '${images.first}';
    }
    final rent = _toDouble(json['rent_price']);
    final sell = _toDouble(json['sell_price']);
    return _AgentListing(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      location: '${json['address'] ?? ''}',
      price: rent > 0 ? rent : sell,
      imageUrl: imageUrl,
    );
  }

  final String id;
  final String title;
  final String location;
  final double price;
  final String imageUrl;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.subtitle,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.greySoft1 : Colors.white,
        border: Border.all(color: AppColors.greySoft2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: text.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 28),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: text.bodySmall?.copyWith(
              fontSize: highlighted ? 14 : 15,
              color: highlighted ? const Color(0xFFE7B904) : AppColors.greyMedium,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
