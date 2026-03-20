import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/top_location_item.dart';
import '../data/repositories/estate_repository.dart';
import '../../../shared/widgets/remote_image.dart';

/// Top Locations grid – Figma 19-1812 (Hanti riyo – Copy)
/// ButtonBackSolid 50px, Title Lato 25px, Subtitle Raleway 12px.
/// Estates Card: bg #F5F4F8, rounded 25, padding 8/16/8, image 144×175 rounded 15, badge gold 25h rounded 8.
class TopLocationsScreen extends StatefulWidget {
  const TopLocationsScreen({super.key});

  @override
  State<TopLocationsScreen> createState() => _TopLocationsScreenState();
}

class _TopLocationsScreenState extends State<TopLocationsScreen> {
  final _repo = EstateRepository();
  late final Future<List<TopLocationItem>> _locationsFuture;

  @override
  void initState() {
    super.initState();
    _locationsFuture = _repo.getTopLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<List<TopLocationItem>>(
          future: _locationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final locations = snapshot.data ?? [];
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.greySoft1,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Top Locations',
                          style: GoogleFonts.lato(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.75,
                            height: 40 / 25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 327,
                          child: Text(
                            'Find the best recommendations place to live',
                            style: GoogleFonts.raleway(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.greyMedium,
                              letterSpacing: 0.36,
                              height: 20 / 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.74,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final loc = locations[i];
                        final rank = i + 1;
                        return _LocationCard(
                          name: loc.name,
                          imageUrl: loc.avatarUrl,
                          rank: rank,
                          onTap: () => context.push(AppRoutes.locationDetail(loc.name, rank: rank)),
                        );
                      },
                      childCount: locations.length,
                    ),
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

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.name,
    required this.imageUrl,
    required this.rank,
    required this.onTap,
  });

  final String name;
  final String imageUrl;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        decoration: BoxDecoration(
          color: AppColors.greySoft1,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: RemoteImage(
                        url: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: AppColors.greySoft2,
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: GoogleFonts.raleway(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: AppColors.greyMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 7,
                    child: Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
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
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: GoogleFonts.raleway(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.36,
                height: 18 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
