import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
  /// Local override for "What do you need?" - null means use data.lookingFor
  bool? _preferRent;
  String? _selectedLocation;
  bool _exitDialogVisible = false;

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
      lookingFor: profile?.lookingFor ?? 'rent',
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

  /// Pop overlay routes first; otherwise show exit confirm. Used by [BackButtonListener] + [PopScope].
  void _handleHomeBack() {
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    _showExitModal();
  }

  /// Android often delivers the system back key here before [PopScope] runs reliably.
  Future<bool> _onAndroidBackPressed() async {
    _handleHomeBack();
    return true;
  }

  void _showExitModal() {
    if (!mounted || _exitDialogVisible) return;
    _exitDialogVisible = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.greySoft1,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.greySoft2, width: 1),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 28,
                  color: AppColors.greyMedium,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Exit app',
                style: GoogleFonts.lato(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to exit the app?',
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.greyMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greySoft1,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          SystemNavigator.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Exit'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (mounted) _exitDialogVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: _onAndroidBackPressed,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleHomeBack();
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: FutureBuilder<_HomeData>(
        future: _homeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final data = snapshot.data ?? const _HomeData.empty();
          final topPadding = MediaQuery.of(context).padding.top;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
            child: SafeArea(
              top: false,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: -110,
                          top: -130,
                          child: Container(
                            width: 380,
                            height: 380,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryBackground.withOpacity(0.15),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(24, topPadding, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              _buildHeader(context, data),
                        const SizedBox(height: 24),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.lato(
                              fontSize: 25,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            children: [
                              const TextSpan(text: 'Hey, '),
                              TextSpan(
                                text: data.userName.isEmpty ? 'there' : '${data.userName}!',
                                style: GoogleFonts.lato(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inputBorderActive,
                                ),
                              ),
                              if (data.userName.isNotEmpty) const TextSpan(text: '\n'),
                              const TextSpan(text: "Let's start exploring"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSearchBar(context),
                        const SizedBox(height: 20),
                        _buildCategories(),
                        const SizedBox(height: 20),
                        _buildSectionHeader(context, 'What do you need?', right: null),
                        const SizedBox(height: 10),
                        _buildNeedToggle(context, data),
                        const SizedBox(height: 24),
                              _buildSectionHeader(context, 'Featured Estates', right: 'view all', onSeeAll: () => context.push(AppRoutes.explore)),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                  child: SizedBox(
                    height: 156,
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
                          category: estate.displayCategory,
                          isSaved: _savedIds.contains(estate.id),
                          onToggleSaved: () => _toggleSaved(estate),
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
                        _buildSectionHeader(context, 'Top Locations', right: 'explore', onSeeAll: () => context.push(AppRoutes.topLocations)),
                        const SizedBox(height: 12),
                        _buildTopLocations(context, data.topLocations),
                        const SizedBox(height: 20),
                        _buildSectionHeader(context, 'Top Estate Agent', right: 'explore', onSeeAll: () => context.push(AppRoutes.topAgents)),
                        const SizedBox(height: 12),
                        _buildTopAgents(context, data.topAgents),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, 'Explore Nearby Estates', right: null),
                        GridView.count(
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
                              category: estate.displayCategory,
                              isSaved: _savedIds.contains(estate.id),
                              onToggleSaved: () => _toggleSaved(estate),
                              onTap: () => context.push(AppRoutes.estateDetail(estate.id)),
                            ),
                          )
                          .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
          bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, _HomeData data) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => LocationModal.show(
                context,
                topLocations: data.topLocations,
                initialLocation: _selectedLocation ?? data.currentLocation,
                onSelect: (loc) => setState(() => _selectedLocation = loc),
              ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.greySoft2),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  _selectedLocation ?? data.currentLocation,
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
          hasNotification: true,
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
      onTap: () => context.push(AppRoutes.searchResultsRoute()),
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.greySoft1,
          borderRadius: BorderRadius.circular(10),
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
           
          ],
        ),
      ),
    );
  }

  Widget _buildTopLocations(BuildContext context, List<TopLocationItem> locations) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: locations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final loc = locations[i];
          final hasValidUrl = loc.avatarUrl.trim().isNotEmpty;
          return GestureDetector(
          onTap: () => context.push(AppRoutes.locationDetail(loc.name)),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.greySoft1,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: AppColors.greySoft2,
                          child: Center(
                            child: Text(
                              loc.name.isNotEmpty ? loc.name[0].toUpperCase() : '?',
                              style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.greyMedium),
                            ),
                          ),
                        ),
                        if (hasValidUrl)
                          RemoteImage(
                            url: loc.avatarUrl,
                            fit: BoxFit.cover,
                            placeholder: const SizedBox.shrink(),
                            errorWidget: const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  loc.name,
                  style: GoogleFonts.raleway(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  Widget _buildTopAgents(BuildContext context, List<TopAgentItem> agents) {
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: agents.length,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (_, i) {
          final agent = agents[i];
          final hasValidUrl = agent.avatarUrl.trim().isNotEmpty;
          return GestureDetector(
            onTap: () => context.push(AppRoutes.agentProfile(agent.id)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.greySoft1, width: 4),
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: AppColors.greySoft2,
                          child: Center(
                            child: Text(
                              agent.name.isNotEmpty ? agent.name[0].toUpperCase() : '?',
                              style: GoogleFonts.raleway(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.greyMedium),
                            ),
                          ),
                        ),
                        if (hasValidUrl)
                          RemoteImage(
                            url: agent.avatarUrl,
                            fit: BoxFit.cover,
                            placeholder: const SizedBox.shrink(),
                            errorWidget: const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  agent.name,
                  style: GoogleFonts.raleway(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 47,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          CategoryChip(label: 'All', isSelected: true),
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

  Widget _buildNeedToggle(BuildContext context, _HomeData data) {
    final preferRent = _preferRent ?? (data.lookingFor == 'buy' ? false : true);
    return GestureDetector(
      onTap: () => setState(() => _preferRent = !preferRent),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.greySoft2,
          borderRadius: BorderRadius.circular(72),
          border: Border.all(color: AppColors.greySoft2, width: 0.8),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: preferRent ? 8 : null,
              right: preferRent ? null : 8,
              top: 8,
              child: Container(
                width: 156,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE9BD36), AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(72),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'I need to rent',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        color: preferRent ? Colors.white : AppColors.navGray,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'I need to buy',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        color: !preferRent ? Colors.white : AppColors.navGray,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {String? right, VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.54,
          ),
        ),
        if (right != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              right,
              style: GoogleFonts.raleway(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.inputBorderActive,
                letterSpacing: 0.3,
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
    this.avatarUrl,
    this.lookingFor = 'rent',
  });

  const _HomeData.empty()
      : featured = const <EstateItem>[],
        nearby = const <EstateItem>[],
        topLocations = const <TopLocationItem>[],
        topAgents = const <TopAgentItem>[],
        userName = '',
        avatarUrl = null,
        lookingFor = 'rent';

  final List<EstateItem> featured;
  final List<EstateItem> nearby;
  final List<TopLocationItem> topLocations;
  final List<TopAgentItem> topAgents;
  final String userName;
  final String? avatarUrl;
  final String lookingFor;

  String get currentLocation {
    if (topLocations.isNotEmpty) return topLocations.first.name;
    if (nearby.isNotEmpty) return nearby.first.location;
    return 'Jakarta, Indonesia';
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
    this.child,
    this.outlined = false,
    this.hasNotification = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Widget? child;
  final bool outlined;
  final bool hasNotification;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: child ??
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: outlined
                      ? Border.all(color: AppColors.primary, width: 1.2)
                      : Border.all(color: const Color(0xFFDFDFDF), width: 1.2),
                ),
                child: Icon(icon, color: AppColors.textPrimary, size: 22),
              ),
              if (hasNotification)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
    );
  }
}
