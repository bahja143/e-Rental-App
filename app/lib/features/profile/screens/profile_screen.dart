import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/remote_image.dart';
import '../../auth/data/repositories/auth_repository.dart';
import '../../home/data/models/estate_item.dart';
import '../../home/data/models/listing_review.dart';
import '../../home/data/repositories/estate_repository.dart';
import '../data/models/profile_user.dart';
import '../data/repositories/profile_repository.dart';
import '../utils/listing_performance_data.dart';
import '../utils/profile_avatar_letter.dart';
import '../widgets/listing_performance_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

enum _ProfileTab { transaction, listings, sold }

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileDashboardData> _pageFuture;
  bool _signingOut = false;
  _ProfileTab _activeTab = _ProfileTab.listings;

  @override
  void initState() {
    super.initState();
    _pageFuture = _loadPage();
  }

  Future<_ProfileDashboardData> _loadPage() async {
    final profile = await ProfileRepository().getMyProfile();
    final listings = await EstateRepository().getFeaturedEstates();
    final soldListings = listings.where((_,) => false).toList();
    final synthesizedSold = soldListings.isEmpty && listings.length > 1
        ? [for (var i = 0; i < listings.length; i++) if (i.isOdd) listings[i]]
        : soldListings;
    final reviews = <_ProfileListingReview>[];
    final estateRepository = EstateRepository();
    for (final listing in listings.take(3)) {
      final reviewMaps = await estateRepository.getListingReviews(listing.id);
      for (final review in reviewMaps.map(ListingReview.fromJson).take(2)) {
        reviews.add(_ProfileListingReview(listing: listing, review: review));
      }
    }
    return _ProfileDashboardData(
      profile: profile,
      listings: listings,
      soldListings: synthesizedSold,
      reviews: reviews,
    );
  }

  Future<void> _refresh() async {
    setState(() => _pageFuture = _loadPage());
    await _pageFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<_ProfileDashboardData>(
        future: _pageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final data = snapshot.data ?? _ProfileDashboardData.fallback();
          final visibleListings = _activeTab == _ProfileTab.sold ? data.soldListings : data.listings;

          return SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                children: [
                  _ProfileHeader(
                    onSettings: () => context.push(AppRoutes.settings),
                  ),
                  const SizedBox(height: 17),
                  _ProfileIdentityCard(
                    profile: data.profile,
                    onEdit: () => context.push(AppRoutes.editProfile),
                  ),
                  const SizedBox(height: 19),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileStatCard(
                          value: '${data.listings.length}',
                          label: 'Listings',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ProfileStatCard(
                          value: '${data.soldListings.length}',
                          label: 'Sold',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ProfileStatCard(
                          value: '${data.reviews.length}',
                          label: 'Reviews',
                          onTap: () => context.push(AppRoutes.profileReviews),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _ProfileTabPill(
                    activeTab: _activeTab,
                    onSelected: (tab) {
                      if (tab == _ProfileTab.transaction) {
                        context.push(AppRoutes.profileTransaction);
                        return;
                      }
                      setState(() => _activeTab = tab);
                    },
                  ),
                  const SizedBox(height: 35),
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.54,
                          ),
                          children: [
                            TextSpan(
                              text: '${visibleListings.length}',
                              style: GoogleFonts.lato(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.54,
                              ),
                            ),
                            TextSpan(
                              text: _activeTab == _ProfileTab.sold ? ' sold' : ' listings',
                              style: GoogleFonts.lato(
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
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.addEstate),
                        child: Container(
                          height: 29,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Add Listing',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.42,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (visibleListings.isEmpty)
                    _ProfileEmptyState(
                      label: _activeTab == _ProfileTab.sold
                          ? 'No sold listings yet.'
                          : 'No listings yet. Add your first property.',
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visibleListings.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.62,
                      ),
                      itemBuilder: (context, index) {
                        final item = visibleListings[index];
                        final insightsCount = 11 + (index % 7);
                        return _ProfileListingCard(
                          item: item,
                          insightsCount: insightsCount,
                          onOpen: () => context.push(AppRoutes.estateDetail(item.id)),
                          onEdit: () => context.push(AppRoutes.editEstateRoute(item.id)),
                          onAnalyticsTap: () => _showListingPerformanceSheet(item, insightsCount),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _signingOut ? null : _signOut,
                    child: Text(
                      _signingOut ? 'Signing out...' : 'Sign Out',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    await AuthRepository().logout();
    if (!mounted) return;
    setState(() => _signingOut = false);
    context.go(AppRoutes.welcome);
  }

  Future<void> _showListingPerformanceSheet(EstateItem item, int insightsCount) async {
    final data = buildListingPerformanceData(item, insightsCount: insightsCount);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: const Color(0xAA1F4C6B),
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.93,
          child: ListingPerformanceSheet(data: data),
        );
      },
    );
  }
}

class _ProfileDashboardData {
  const _ProfileDashboardData({
    required this.profile,
    required this.listings,
    required this.soldListings,
    required this.reviews,
  });

  final ProfileUser profile;
  final List<EstateItem> listings;
  final List<EstateItem> soldListings;
  final List<_ProfileListingReview> reviews;

  factory _ProfileDashboardData.fallback() {
    return _ProfileDashboardData(
      profile: const ProfileUser(name: '', email: ''),
      listings: const <EstateItem>[],
      soldListings: const <EstateItem>[],
      reviews: const <_ProfileListingReview>[],
    );
  }
}

class _ProfileListingReview {
  const _ProfileListingReview({
    required this.listing,
    required this.review,
  });

  final EstateItem listing;
  final ListingReview review;
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Profile',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.54,
            ),
          ),
          Positioned(
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSettings,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.greySoft1,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    size: 21,
                    color: AppColors.textPrimary,
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

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({
    required this.profile,
    required this.onEdit,
  });

  final ProfileUser profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatarUrl?.trim() ?? '';
    final letter = profileAvatarLetterFromName(profile.name);
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: avatar.isNotEmpty
                      ? RemoteImage(
                          url: avatar,
                          fit: BoxFit.cover,
                          errorWidget: _ProfileAvatarFallback(letter: letter),
                        )
                      : _ProfileAvatarFallback(letter: letter),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBackground,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            profile.name.isEmpty ? 'User' : profile.name,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.42,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email.isEmpty ? 'email@example.com' : profile.email,
            style: GoogleFonts.lato(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.greyMedium,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatarFallback extends StatelessWidget {
  const _ProfileAvatarFallback({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.greySoft2,
      alignment: Alignment.center,
      child: Text(
        letter.isEmpty ? 'U' : letter,
        style: GoogleFonts.lato(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.value,
    required this.label,
    this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.greySoft2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.42,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.lato(
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
    );
  }
}

class _ProfileTabPill extends StatelessWidget {
  const _ProfileTabPill({
    required this.activeTab,
    required this.onSelected,
  });

  final _ProfileTab activeTab;
  final ValueChanged<_ProfileTab> onSelected;

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
          _ProfileTabButton(
            label: 'Transaction',
            active: activeTab == _ProfileTab.transaction,
            onTap: () => onSelected(_ProfileTab.transaction),
          ),
          const SizedBox(width: 7),
          _ProfileTabButton(
            label: 'Listings',
            active: activeTab == _ProfileTab.listings,
            onTap: () => onSelected(_ProfileTab.listings),
          ),
          const SizedBox(width: 7),
          _ProfileTabButton(
            label: 'Sold',
            active: activeTab == _ProfileTab.sold,
            onTap: () => onSelected(_ProfileTab.sold),
          ),
        ],
      ),
    );
  }
}

class _ProfileTabButton extends StatelessWidget {
  const _ProfileTabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.textPrimary : AppColors.greyBarelyMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileListingCard extends StatelessWidget {
  const _ProfileListingCard({
    required this.item,
    required this.insightsCount,
    required this.onOpen,
    required this.onEdit,
    required this.onAnalyticsTap,
  });

  final EstateItem item;
  final int insightsCount;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onAnalyticsTap;

  @override
  Widget build(BuildContext context) {
    final category = item.displayCategory ?? 'Apartment';
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.greySoft1,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  height: 160,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RemoteImage(
                        url: item.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: Container(color: AppColors.greySoft2),
                      ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: _ProfileImageActionButton(
                          icon: Icons.edit_outlined,
                          fill: AppColors.primary,
                          onTap: onEdit,
                        ),
                      ),
                      const Positioned(
                        right: 8,
                        top: 8,
                        child: _ProfileImageActionButton(
                          icon: Icons.favorite_border_rounded,
                          fill: Colors.white,
                          iconColor: AppColors.textSecondary,
                        ),
                      ),
                      Positioned(
                        bottom: 39,
                        right: 4,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onAnalyticsTap,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xCC3F467C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bar_chart_rounded, size: 16, color: Colors.white),
                                  const SizedBox(width: 10),
                                  Text(
                                    '$insightsCount',
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      letterSpacing: 0.36,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: category.toLowerCase() == 'villa'
                                ? const Color(0xB03F467C)
                                : AppColors.primaryBackground.withValues(alpha: 0.69),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '\$ ${item.price.toInt()}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.36,
                                  ),
                                ),
                                TextSpan(
                                  text: '/month',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 6,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.greySoft1,
                                    letterSpacing: 0.18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 18 / 12,
                    letterSpacing: 0.36,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 9, color: AppColors.primary),
                  const SizedBox(width: 2),
                  Text(
                    (item.rating ?? 4.8).toStringAsFixed(1),
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greyMedium,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.location_on_outlined, size: 9, color: AppColors.greyMedium),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      item.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 8,
                        fontWeight: FontWeight.w400,
                        color: AppColors.greyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileImageActionButton extends StatelessWidget {
  const _ProfileImageActionButton({
    required this.icon,
    required this.fill,
    this.iconColor = Colors.white,
    this.onTap,
  });

  final IconData icon;
  final Color fill;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: iconColor),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: child,
      ),
    );
  }
}

class _ProfileEmptyState extends StatelessWidget {
  const _ProfileEmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.lato(
          fontSize: 14,
          color: AppColors.greyMedium,
          height: 1.5,
        ),
      ),
    );
  }
}
