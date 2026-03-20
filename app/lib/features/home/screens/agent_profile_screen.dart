import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/remote_image.dart';
import '../data/repositories/estate_repository.dart';
import '../widgets/estate_card.dart';

/// Agent profile – Figma 19-1729 (Hanti riyo – Copy)
class AgentProfileScreen extends StatefulWidget {
  const AgentProfileScreen({
    super.key,
    this.agentId = '1',
    this.name = 'Amanda',
    this.email = 'amanda.trust@email.com',
    this.avatarUrl = 'https://www.figma.com/api/mcp/asset/654236e4-56ee-45ef-94a3-fd5669941a10',
    this.rank,
  });

  final String agentId;
  final String name;
  final String email;
  final String? avatarUrl;
  final int? rank;

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  final _estateRepo = EstateRepository();
  late final Future<_AgentProfileData> _profileFuture;
  Set<String> _savedIds = <String>{};
  bool _showListings = true; // Listings vs Sold tab
  bool _isGrid = true; // grid vs list view

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
              height: 63,
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.chatDetail('0', name: data.name)),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Start Chat',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.48,
                  ),
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
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      _circleActionButton(Icons.ios_share_outlined, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ProfileSection(data: data, rank: widget.rank),
                  const SizedBox(height: 22),
                  _StatsRow(
                    rating: data.rating,
                    reviewCount: data.reviewCount,
                    soldCount: data.soldCount,
                  ),
                  const SizedBox(height: 22),
                  _TabBar(
                    activeListings: _showListings,
                    onListingsTap: () => setState(() => _showListings = true),
                    onSoldTap: () => setState(() => _showListings = false),
                  ),
                  const SizedBox(height: 22),
                  _ListingsHeader(
                    count: _showListings ? data.listings.length : 0,
                    isGrid: _isGrid,
                    onGridTap: () => setState(() => _isGrid = true),
                    onListTap: () => setState(() => _isGrid = false),
                  ),
                  const SizedBox(height: 16),
                  _ListingsGrid(
                    listings: _showListings ? data.listings : const [],
                    isGrid: _isGrid,
                    savedIds: _savedIds,
                    onToggleSaved: _toggleSaved,
                    onTap: (id) => context.push(AppRoutes.estateDetail(id)),
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

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.data, this.rank});

  final _AgentProfileData data;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            data.name,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.42,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.email,
            style: GoogleFonts.raleway(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.greyMedium,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: ClipOval(
                  child: RemoteImage(
                    url: data.avatarUrl,
                    fit: BoxFit.cover,
                    errorWidget: Container(color: AppColors.greySoft1),
                  ),
                ),
              ),
              if (rank != null)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$rank',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.36,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.rating,
    required this.reviewCount,
    required this.soldCount,
  });

  final double rating;
  final int reviewCount;
  final int soldCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.42,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (_) => Icon(Icons.star, size: 12, color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.greySoft2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$reviewCount',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.42,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reviews',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.greyMedium,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.greySoft2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$soldCount',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.42,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sold',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.greyMedium,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.activeListings,
    required this.onListingsTap,
    required this.onSoldTap,
  });

  final bool activeListings;
  final VoidCallback onListingsTap;
  final VoidCallback onSoldTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onListingsTap,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: activeListings ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Listings',
                  style: GoogleFonts.raleway(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: activeListings ? AppColors.textPrimary : AppColors.greyBarelyMedium,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onSoldTap,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !activeListings ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Sold',
                  style: GoogleFonts.raleway(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: !activeListings ? AppColors.textPrimary : AppColors.greyBarelyMedium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingsHeader extends StatelessWidget {
  const _ListingsHeader({
    required this.count,
    required this.isGrid,
    required this.onGridTap,
    required this.onListTap,
  });

  final int count;
  final bool isGrid;
  final VoidCallback onGridTap;
  final VoidCallback onListTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$count ',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.54,
                ),
              ),
              TextSpan(
                text: 'listings',
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.54,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.greySoft1,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ViewBtn(icon: Icons.grid_view_rounded, active: isGrid, onTap: onGridTap),
              const SizedBox(width: 5),
              _ViewBtn(icon: Icons.view_agenda_outlined, active: !isGrid, onTap: onListTap),
            ],
          ),
        ),
      ],
    );
  }
}

class _ViewBtn extends StatelessWidget {
  const _ViewBtn({required this.icon, required this.active, required this.onTap});

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Icon(
          icon,
          size: 17,
          color: active ? AppColors.textPrimary : AppColors.greyBarelyMedium,
        ),
      ),
    );
  }
}

class _ListingsGrid extends StatelessWidget {
  const _ListingsGrid({
    required this.listings,
    required this.isGrid,
    required this.savedIds,
    required this.onToggleSaved,
    required this.onTap,
  });

  final List<_AgentListing> listings;
  final bool isGrid;
  final Set<String> savedIds;
  final void Function(String) onToggleSaved;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return const SizedBox(height: 80);
    }
    if (isGrid) {
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 7,
          childAspectRatio: 0.63,
        ),
        itemCount: listings.length,
        itemBuilder: (_, i) {
          final listing = listings[i];
          return EstateCard.vertical(
            title: listing.title,
            location: listing.location,
            price: listing.price,
            rating: 4.9,
            imageUrl: listing.imageUrl,
            category: null,
            isSaved: savedIds.contains(listing.id),
            onToggleSaved: () => onToggleSaved(listing.id),
            onTap: () => onTap(listing.id),
          );
        },
      );
    }
    return Column(
      children: listings
          .map(
            (listing) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EstateCard.horizontal(
                title: listing.title,
                location: listing.location,
                price: listing.price,
                rating: 4.9,
                imageUrl: listing.imageUrl,
                isSaved: savedIds.contains(listing.id),
                onToggleSaved: () => onToggleSaved(listing.id),
                onTap: () => onTap(listing.id),
                fullWidth: true,
              ),
            ),
          )
          .toList(),
    );
  }
}

