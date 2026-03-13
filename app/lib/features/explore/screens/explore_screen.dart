import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/data/models/estate_item.dart';
import '../../home/data/repositories/estate_repository.dart';
import '../../home/widgets/estate_card.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/remote_image.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final Future<_ExploreData> _exploreFuture;

  @override
  void initState() {
    super.initState();
    _exploreFuture = _loadExploreData();
  }

  Future<_ExploreData> _loadExploreData() async {
    final repo = EstateRepository();
    final results = await Future.wait<dynamic>([
      repo.getFeaturedEstates(),
      repo.getNearbyEstates(),
    ]);
    final featured = (results[0] as List<EstateItem>);
    final nearby = (results[1] as List<EstateItem>);
    return _ExploreData(
      highlightedEstate: featured.isNotEmpty ? featured.first : (nearby.isNotEmpty ? nearby.first : null),
      nearbyCount: nearby.length,
    );
  }

  static const _mapImage = 'https://www.figma.com/api/mcp/asset/1da1ec4a-64f3-41a3-877c-e28cec53f803';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_ExploreData>(
        future: _exploreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final data = snapshot.data;
          return SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: RemoteImage(
                      url: _mapImage,
                      fit: BoxFit.cover,
                      errorWidget: Container(color: AppColors.greySoft1),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: 24,
                  child: Row(
                    children: [
                      _pillButton(
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 15, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text('Jakarta, Indonesia', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: AppColors.textPrimary)),
                            const SizedBox(width: 8),
                            const Icon(Icons.keyboard_arrow_down, size: 10, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _roundBtn(icon: Icons.tune),
                    ],
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: 94,
                  child: _pillButton(
                    radius: 25,
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 20, color: AppColors.textPrimary),
                        const SizedBox(width: 10),
                        Text('Search House, Apartment, etc', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.greyBarelyMedium)),
                        const Spacer(),
                        Container(width: 1, height: 36, color: AppColors.greySoft2),
                        const SizedBox(width: 12),
                        const Icon(Icons.mic_none, size: 20, color: AppColors.greyMedium),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  bottom: 148,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(
                            '${data?.nearbyCount ?? 0}',
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Nearby You', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                if (data?.highlightedEstate != null)
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 86,
                    child: EstateCard.horizontal(
                      title: data!.highlightedEstate!.title,
                      location: data.highlightedEstate!.location,
                      price: data.highlightedEstate!.price,
                      rating: data.highlightedEstate!.rating,
                      imageUrl: data.highlightedEstate!.imageUrl,
                      onTap: () => context.push(AppRoutes.estateDetail(data.highlightedEstate!.id)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  Widget _pillButton({required Widget child, double radius = 25}) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(child: child),
    );
  }

  Widget _roundBtn({required IconData icon}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 20),
    );
  }
}

class _ExploreData {
  const _ExploreData({
    required this.highlightedEstate,
    required this.nearbyCount,
  });

  final EstateItem? highlightedEstate;
  final int nearbyCount;
}
