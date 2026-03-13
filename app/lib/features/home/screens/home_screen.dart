import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/remote_image.dart';
import '../../profile/data/models/profile_user.dart';
import '../../profile/data/repositories/profile_repository.dart';
import '../data/models/estate_item.dart';
import '../data/models/top_agent_item.dart';
import '../data/models/top_location_item.dart';
import '../data/repositories/estate_repository.dart';
import '../widgets/category_chip.dart';
import '../widgets/estate_card.dart';
import '../widgets/location_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = EstateRepository();
  late final Future<_HomeData> _homeFuture;
  Set<String> _savedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _homeFuture = _loadHomeData();
    _loadSavedIds();
  }

  Future<_HomeData> _loadHomeData() async {
    ProfileUser? profile;
    try {
      profile = await ProfileRepository().getMyProfile();
    } catch (_) {}
    final results = await Future.wait<dynamic>([
      _repo.getFeaturedEstates(),
      _repo.getNearbyEstates(),
      _repo.getTopLocations(),
      _repo.getTopAgents(),
    ]);
    return _HomeData(
      featured: results[0] as List<EstateItem>,
      nearby: results[1] as List<EstateItem>,
      topLocations: results[2] as List<TopLocationItem>,
      topAgents: results[3] as List<TopAgentItem>,
      userName: (profile?.name ?? '').trim(),
      avatarUrl: profile?.avatarUrl,
    );
  }

  Future<void> _loadSavedIds() async {
    final ids = await _repo.getSavedEstateIds();
    if (!mounted) return;
    setState(() => _savedIds = ids);
  }

  Future<void> _toggleSaved(EstateItem estate) async {
    if (estate.id.isEmpty) return;
    final isSaved = _savedIds.contains(estate.id);
    final ok = isSaved ? await _repo.removeSavedEstate(estate.id) : await _repo.addSavedEstate(estate.id);
    if (!mounted || !ok) return;
    setState(() {
      if (isSaved) {
        _savedIds.remove(estate.id);
      } else {
        _savedIds.add(estate.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<_HomeData>(
        future: _homeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final data = snapshot.data ?? const _HomeData.empty();
          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildHeader(context, data),
                        const SizedBox(height: 24),
                        Text(
                          'Hey, ${data.userName.isEmpty ? 'there' : data.userName}!\nLet\'s start exploring',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontSize: 40,
                                height: 1.15,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 24),
                        _buildSearchBar(context),
                        const SizedBox(height: 20),
                        _buildCategories(),
                        const SizedBox(height: 20),
                        _buildSectionHeader(context, 'What do you need?', right: null),
                        const SizedBox(height: 10),
                        _buildNeedToggle(),
                        const SizedBox(height: 24),
                        _buildSectionHeader(context, 'Featured Estates', right: 'view all', onSeeAll: () => context.push(AppRoutes.explore)),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemBuilder: (_, i) {
                        final estate = data.featured[i];
                        return EstateCard.horizontal(
                          title: estate.title,
                          location: estate.location,
                          price: estate.price,
                          rating: estate.rating,
                          imageUrl: estate.imageUrl,
                          onTap: () => context.push(AppRoutes.estateDetail(estate.id)),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemCount: data.featured.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildSectionHeader(context, 'Top Locations', right: 'explore', onSeeAll: () => context.push(AppRoutes.locationDetail('Jakarta'))),
                        const SizedBox(height: 12),
                        _buildTopLocations(context, data.topLocations),
                        const SizedBox(height: 20),
                        _buildSectionHeader(context, 'Top Estate Agent', right: 'explore', onSeeAll: () => context.push(AppRoutes.agentProfile('1'))),
                        const SizedBox(height: 12),
                        _buildTopAgents(context, data.topAgents),
                        const SizedBox(height: 20),
                        _buildSectionHeader(context, 'Explore Nearby Estates', right: null),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 7,
                      childAspectRatio: 0.63,
                      children: data.nearby
                          .map(
                            (estate) => EstateCard.vertical(
                              title: estate.title,
                              location: estate.location,
                              price: estate.price,
                              rating: estate.rating,
                              imageUrl: estate.imageUrl,
                              isSaved: _savedIds.contains(estate.id),
                              onToggleSaved: () => _toggleSaved(estate),
                              onTap: () => context.push(AppRoutes.estateDetail(estate.id)),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildHeader(BuildContext context, _HomeData data) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => LocationModal.show(context),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  data.currentLocation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down, size: 10, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        const Spacer(),
        _IconButton(
          icon: Icons.notifications_none,
          onTap: () => context.push(AppRoutes.notifications),
          outlined: true,
        ),
        const SizedBox(width: 10),
        _IconButton(
          icon: Icons.person,
          onTap: () => context.go(AppRoutes.profile),
          child: SizedBox(
            width: 44,
            height: 44,
            child: ClipOval(
              child: RemoteImage(
                url: data.avatarUrl ??
                    'https://www.figma.com/api/mcp/asset/b8e3e9f1-dc5f-4db6-ba68-7746550ef637',
                fit: BoxFit.cover,
                errorWidget: Container(color: AppColors.greySoft1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.search),
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.greySoft1,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.greyBarelyMedium, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search House, Apartment, etc',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.mic_none, color: AppColors.greyBarelyMedium, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTopLocations(BuildContext context, List<TopLocationItem> locations) {
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: locations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => context.push(AppRoutes.locationDetail(locations[i].name)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.greySoft1,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: ClipOval(
                    child: RemoteImage(
                      url: locations[i].avatarUrl,
                      fit: BoxFit.cover,
                      errorWidget: Container(color: AppColors.greySoft1),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  locations[i].name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8, color: AppColors.greyMedium),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopAgents(BuildContext context, List<TopAgentItem> agents) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: agents.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => context.push(AppRoutes.agentProfile(agents[i].id)),
          child: Column(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: ClipOval(
                  child: RemoteImage(
                    url: agents[i].avatarUrl,
                    fit: BoxFit.cover,
                    errorWidget: Container(color: AppColors.greySoft1),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(agents[i].name, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 47,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          CategoryChip(label: 'All', isSelected: true, selectedColor: AppColors.textSecondary),
          SizedBox(width: 10),
          CategoryChip(label: 'House'),
          SizedBox(width: 10),
          CategoryChip(label: 'Apartment'),
          SizedBox(width: 10),
          CategoryChip(label: 'House'),
        ],
      ),
    );
  }

  Widget _buildNeedToggle() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Text(
                'I need to rent',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'I need to buy',
                style: TextStyle(fontSize: 12, color: AppColors.greyMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {String? right, VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 25)),
        if (right != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              right,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
      ],
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.featured,
    required this.nearby,
    required this.topLocations,
    required this.topAgents,
    required this.userName,
    required this.avatarUrl,
  });

  const _HomeData.empty()
      : featured = const <EstateItem>[],
        nearby = const <EstateItem>[],
        topLocations = const <TopLocationItem>[],
        topAgents = const <TopAgentItem>[],
        userName = '',
        avatarUrl = null;

  final List<EstateItem> featured;
  final List<EstateItem> nearby;
  final List<TopLocationItem> topLocations;
  final List<TopAgentItem> topAgents;
  final String userName;
  final String? avatarUrl;

  String get currentLocation {
    if (topLocations.isNotEmpty) return topLocations.first.name;
    if (nearby.isNotEmpty) return nearby.first.location;
    return 'Jakarta, Indonesia';
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap, this.child, this.outlined = false});

  final IconData icon;
  final VoidCallback onTap;
  final Widget? child;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: child ??
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.greySoft1,
              borderRadius: BorderRadius.circular(25),
              border: outlined ? Border.all(color: AppColors.primary, width: 1) : null,
            ),
            child: Icon(icon, color: AppColors.textPrimary),
          ),
    );
  }
}
