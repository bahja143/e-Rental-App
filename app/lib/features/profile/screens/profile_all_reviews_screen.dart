import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/remote_image.dart';
import '../../home/data/models/estate_item.dart';
import '../../home/data/models/listing_review.dart';
import '../../home/data/repositories/estate_repository.dart';
import '../../home/widgets/listing_review_tile.dart';
import '../data/models/profile_user.dart';
import '../data/repositories/profile_repository.dart';
import '../utils/profile_avatar_letter.dart';

class ProfileAllReviewsScreen extends StatefulWidget {
  const ProfileAllReviewsScreen({super.key});

  @override
  State<ProfileAllReviewsScreen> createState() => _ProfileAllReviewsScreenState();
}

class _ProfileAllReviewsScreenState extends State<ProfileAllReviewsScreen> {
  late final Future<_ProfileReviewsData> _pageFuture;
  int? _starFilter;

  @override
  void initState() {
    super.initState();
    _pageFuture = _loadPage();
  }

  Future<_ProfileReviewsData> _loadPage() async {
    final profile = await ProfileRepository().getMyProfile();
    final listings = await EstateRepository().getFeaturedEstates();
    final reviews = <_ProfileListingReview>[];
    final estateRepository = EstateRepository();
    for (final listing in listings.take(4)) {
      final reviewMaps = await estateRepository.getListingReviews(listing.id);
      for (final review in reviewMaps.map(ListingReview.fromJson).take(1)) {
        reviews.add(_ProfileListingReview(listing: listing, review: review));
      }
    }
    return _ProfileReviewsData(profile: profile, reviews: reviews);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<_ProfileReviewsData>(
          future: _pageFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            final data = snapshot.data ?? _ProfileReviewsData.fallback();
            final reviews = _starFilter == null
                ? data.reviews
                : data.reviews.where((e) => e.review.rating == _starFilter).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: [
                SizedBox(
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        'All reviews',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.54,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: AppColors.greySoft1,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _OwnerCard(
                  profile: data.profile,
                  onChat: () => context.push(AppRoutes.messages),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ReviewFilterChip(
                        active: _starFilter == null,
                        label: 'All',
                        onTap: () => setState(() => _starFilter = null),
                      ),
                      const SizedBox(width: 10),
                      for (final n in [1, 2, 3, 4, 5]) ...[
                        _ReviewFilterChip(
                          active: _starFilter == n,
                          label: '$n',
                          onTap: () => setState(() => _starFilter = n),
                        ),
                        if (n != 5) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'User reviews',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.54,
                  ),
                ),
                const SizedBox(height: 20),
                ...reviews.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _ProfileReviewCard(item: item),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileReviewsData {
  const _ProfileReviewsData({
    required this.profile,
    required this.reviews,
  });

  final ProfileUser profile;
  final List<_ProfileListingReview> reviews;

  factory _ProfileReviewsData.fallback() {
    return _ProfileReviewsData(
      profile: const ProfileUser(name: '', email: ''),
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

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({
    required this.profile,
    required this.onChat,
  });

  final ProfileUser profile;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatarUrl?.trim() ?? '';
    final letter = profileAvatarLetterFromName(profile.name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26.5),
            child: SizedBox(
              width: 53,
              height: 53,
              child: avatar.isNotEmpty
                  ? RemoteImage(
                      url: avatar,
                      fit: BoxFit.cover,
                      errorWidget: _OwnerAvatarFallback(letter: letter),
                    )
                  : _OwnerAvatarFallback(letter: letter),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.isEmpty ? 'Owner' : profile.name,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.42,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Owner',
                  style: GoogleFonts.lato(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: AppColors.greyMedium,
                    letterSpacing: 0.27,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onChat,
            child: const Icon(
              Icons.mode_comment_outlined,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerAvatarFallback extends StatelessWidget {
  const _OwnerAvatarFallback({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.greySoft2,
      alignment: Alignment.center,
      child: Text(
        letter.isEmpty ? 'U' : letter,
        style: GoogleFonts.lato(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ReviewFilterChip extends StatelessWidget {
  const _ReviewFilterChip({
    required this.active,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17.5),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryBackground : AppColors.greySoft1,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '⭐',
                style: GoogleFonts.raleway(
                  fontSize: 15,
                  color: active ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.greySoft1 : AppColors.textPrimary,
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

class _ProfileReviewCard extends StatelessWidget {
  const _ProfileReviewCard({required this.item});

  final _ProfileListingReview item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greySoft2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 74,
                    height: 36,
                    child: RemoteImage(
                      url: item.listing.imageUrl,
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
                      Text(
                        item.listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 9, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Text(
                            (item.listing.rating ?? 4.8).toStringAsFixed(1),
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
                              item.listing.location,
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
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: const BoxDecoration(
              color: AppColors.greySoft1,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
            child: ListingReviewListTile(review: item.review),
          ),
        ],
      ),
    );
  }
}
