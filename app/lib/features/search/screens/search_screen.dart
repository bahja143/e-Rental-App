import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/figma_tokens.dart';
import '../../home/data/models/estate_item.dart';
import '../../home/data/models/top_location_item.dart';
import '../../home/data/repositories/estate_repository.dart';
import '../../home/widgets/estate_card.dart';
import '../../explore/widgets/filter_modal.dart';
import '../../home/widgets/location_modal.dart';
import '../data/repositories/recent_search_repository.dart';
import '../utils/map_pin_descriptor.dart';

/// `true` = Explore / Empty (Figma 21-3735): no pins, no cards. Or run:
/// `flutter run --dart-define=SEARCH_SIMULATE_NO_LISTINGS=true`
const bool kSearchSimulateNoListings =
    bool.fromEnvironment('SEARCH_SIMULATE_NO_LISTINGS', defaultValue: false);

/// Search/Explore screen matching Figma nodes 21-3735, 21-3695, 21-3653.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _modalSearchFocusNode = FocusNode(debugLabel: 'modalSearch');
  final _repo = EstateRepository();
  final _recentRepo = RecentSearchRepository();

  String _selectedLocation = 'Jakarta, Indonesia';
  List<TopLocationItem> _topLocations = const [];
  List<EstateItem> _nearbyEstates = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  bool _showSearchOverlay = false;
  Set<String> _savedIds = <String>{};
  bool _loading = true;
  int _pageStart = 1;
  BitmapDescriptor? _pinDescriptor;
  Map<String, BitmapDescriptor> _markerDescriptors = {};
  final _mapController = Completer<GoogleMapController>();

  static const _defaultCenter = LatLng(-6.2088, 106.8456); // Jakarta
  static const _defaultZoom = 12.0;
  static const _headerRowHeight = 52.0;
  /// Full-screen loading scrim (stronger than map-area-only; covers top chrome + bottom bar).
  static const _loadingPageBlurSigma = 18.0;

  int _pageEnd = 50;
  int _totalCount = 200;

  /// Listings shown on map + bottom sheet (empty when simulating no listings).
  List<EstateItem> get _visibleEstates =>
      kSearchSimulateNoListings ? const <EstateItem>[] : _nearbyEstates;

  @override
  void initState() {
    super.initState();
    _modalSearchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData();
    _loadPinDescriptor();
  }

  Future<void> _loadPinDescriptor() async {
    final descriptor = await createMapPinDescriptor();
    if (!mounted) return;
    setState(() => _pinDescriptor = descriptor);
  }

  Future<void> _loadMarkerDescriptors() async {
    final withCoords = _nearbyEstates.where((e) => e.hasCoordinates).toList();
    if (withCoords.isEmpty) return;
    final descriptors = <String, BitmapDescriptor>{};
    await Future.wait(withCoords.map((e) async {
      final d = await createMapPinDescriptor(imageUrl: e.imageUrl);
      if (mounted) descriptors[e.id] = d;
    }));
    if (!mounted) return;
    setState(() => _markerDescriptors = descriptors);
  }

  Future<void> _fitMapToMarkers() async {
    final withCoords = _visibleEstates.where((e) => e.hasCoordinates).toList();
    if (withCoords.isEmpty) return;
    try {
      final controller = await _mapController.future;
      if (!mounted) return;
      if (withCoords.length == 1) {
        controller.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(withCoords.first.lat!, withCoords.first.lng!),
          14,
        ));
      } else {
        final lats = withCoords.map((e) => e.lat!);
        final lngs = withCoords.map((e) => e.lng!);
        final bounds = LatLngBounds(
          southwest: LatLng(lats.reduce((a, b) => a < b ? a : b), lngs.reduce((a, b) => a < b ? a : b)),
          northeast: LatLng(lats.reduce((a, b) => a > b ? a : b), lngs.reduce((a, b) => a > b ? a : b)),
        );
        controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _modalSearchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearchOverlay() async {
    setState(() => _showSearchOverlay = !_showSearchOverlay);
    if (_showSearchOverlay) await _loadRecentSearches();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final locations = await _repo.getTopLocations();
    final nearby = await _repo.getNearbyEstates();
    final saved = await _repo.getSavedEstateIds();
    if (!mounted) return;
    setState(() {
      _topLocations = locations;
      _nearbyEstates = nearby;
      _savedIds = saved;
      _loading = false;
    });
    _fitMapToMarkers();
    _loadMarkerDescriptors();
  }

  Future<void> _loadRecentSearches() async {
    final list = await _recentRepo.getRecentSearches();
    if (!mounted) return;
    setState(() => _recentSearches = list);
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    await _recentRepo.addRecentSearch(q);
    setState(() {
      _isSearching = true;
      _showSearchOverlay = false;
    });
    final results = await _repo.searchEstates(q);
    if (!mounted) return;
    setState(() {
      _nearbyEstates = results;
      _isSearching = false;
    });
    _fitMapToMarkers();
    _loadMarkerDescriptors();
  }

  Future<void> _toggleSaved(EstateItem item) async {
    final id = item.id;
    if (id.isEmpty) return;
    final currentlySaved = _savedIds.contains(id);
    final ok = currentlySaved ? await _repo.removeSavedEstate(id) : await _repo.addSavedEstate(id);
    if (!mounted || !ok) return;
    setState(() {
      if (currentlySaved) {
        _savedIds.remove(id);
      } else {
        _savedIds.add(id);
      }
    });
  }

  Future<void> _clearRecentSearches() async {
    await _recentRepo.clearRecentSearches();
    if (!mounted) return;
    setState(() => _recentSearches = []);
  }

  Future<void> _removeRecentSearch(String item) async {
    await _recentRepo.removeRecentSearch(item);
    if (!mounted) return;
    setState(() => _recentSearches = _recentSearches.where((s) => s != item).toList());
  }

  /// Search is often opened with [context.go] (bottom nav) — no stack entry, so "pop" exits the app.
  /// Prefer popping when [context.push] was used; otherwise return to home (dashboard).
  void _handleSearchScreenBack() {
    if (_showSearchOverlay) {
      setState(() => _showSearchOverlay = false);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  /// Android: [GoogleMap] can swallow the system back key before [PopScope] runs — handle here first.
  Future<bool> _onBackButtonPressed() async {
    _handleSearchScreenBack();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: _onBackButtonPressed,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleSearchScreenBack();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildMapBackground(context),
              // Figma 21:3681 — full-screen blur + tint; tap dimmed map dismisses modal.
              if (_showSearchOverlay)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleSearchOverlay,
                    child: _buildSearchOverlayFader(context),
                  ),
                ),
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    if (_showSearchOverlay)
                      _buildSearchOverlayTopSpacer(context)
                    else
                      _buildTopChrome(context, includeSearchBar: true),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _showSearchOverlay
                          ? const IgnorePointer(
                              child: SizedBox.expand(),
                            )
                          : _buildMapArea(context),
                    ),
                    if (!_showSearchOverlay) _buildBottomSection(context),
                  ],
                ),
              ),
              // Blur entire page (map + top chrome + bottom) while loading / searching.
              if ((_loading || _isSearching) && !_showSearchOverlay)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: _loadingPageBlurSigma,
                        sigmaY: _loadingPageBlurSigma,
                      ),
                      child: ColoredBox(
                        color: AppColors.primaryBackground.withValues(alpha: 0.28),
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
              // Figma 21:3682 — modal layer: filled search + recent card (above fader).
              if (_showSearchOverlay) ...[
                Positioned(
                  left: 24,
                  right: 24,
                  top: _modalSearchTop(context),
                  child: _buildFigmaModalSearchField(context),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: _modalSearchTop(context) + 70 + 20,
                  child: _buildFigmaRecentSearchCard(context),
                ),
                // Above fader: location + filter stay tappable (page chrome).
                Positioned(
                  left: 24,
                  right: 24,
                  top: MediaQuery.paddingOf(context).top + 16,
                  child: _buildHeaderRow(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom of location + filter row (Y where modal fader starts).
  double _headerRowBottom(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return topInset + 16 + _headerRowHeight;
  }

  /// Modal search field: below header + 20px gap.
  double _modalSearchTop(BuildContext context) => _headerRowBottom(context) + 20;

  /// Reserves the same vertical space as [ _buildTopChrome ] when only header is on the page layer.
  Widget _buildSearchOverlayTopSpacer(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(height: topInset + 16 + _headerRowHeight);
  }

  /// Blur + teal tint below header only (modal area).
  Widget _buildSearchOverlayFader(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: FigmaHantiRiyoTokens.exploreSearchFaderBlurSigma,
          sigmaY: FigmaHantiRiyoTokens.exploreSearchFaderBlurSigma,
        ),
        child: Container(color: FigmaHantiRiyoTokens.exploreSearchFaderTint),
      ),
    );
  }

  String? _imageUrlForRecentQuery(String text) {
    final t = text.toLowerCase().trim();
    if (t.isEmpty) return null;
    for (final e in _nearbyEstates) {
      final title = e.title.toLowerCase();
      if (title == t || title.contains(t) || t.contains(title)) {
        final url = e.imageUrl;
        if (url.isNotEmpty) return url;
      }
    }
    return null;
  }

  /// Full-screen Google Map with custom pins (Figma 21-3695).
  Widget _buildMapBackground(BuildContext context) {
    final markers = _visibleEstates
        .where((e) => e.hasCoordinates)
        .map((e) => Marker(
              markerId: MarkerId(e.id),
              position: LatLng(e.lat!, e.lng!),
              icon: _markerDescriptors[e.id] ?? _pinDescriptor ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              onTap: () => context.push(AppRoutes.estateDetail(e.id)),
            ))
        .toSet();

    return Positioned.fill(
      child: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _defaultCenter,
          zoom: _defaultZoom,
        ),
        onMapCreated: (c) => _mapController.complete(c),
        markers: markers,
        mapType: MapType.normal,
        myLocationEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: false,
        mapToolbarEnabled: false,
        liteModeEnabled: false,
      ),
    );
  }

  /// Map area (middle) - map visible, empty when not searching.
  /// Map draws in the stack below; this slot stays transparent unless we add in-column UI later.
  Widget _buildMapArea(BuildContext context) => const SizedBox.shrink();

  /// One chrome block: gradient from status bar → below search + single dark-blue shadow (nav / text primary — no gold).
  /// When search overlay is open, header is not built here — see [ _buildHeaderRow ] in Stack (page layer).
  Widget _buildTopChrome(BuildContext context, {required bool includeSearchBar}) {
    final topInset = MediaQuery.paddingOf(context).top;
    final nav = AppColors.primaryBackground;
    final darkBlue = AppColors.textPrimary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            nav.withValues(alpha: 0.20),
            nav.withValues(alpha: 0.10),
            nav.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.72, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: nav.withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, topInset + 16, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderRow(context),
          if (includeSearchBar) ...[
            const SizedBox(height: 20),
            _buildSearchBarRow(context),
          ],
        ],
      ),
    );
  }

  /// Header: location dropdown + filter (no per-control shadow — chrome handles it).
  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => LocationModal.show(
            context,
            topLocations: _topLocations,
            initialLocation: _selectedLocation,
            onSelect: (loc) => setState(() => _selectedLocation = loc),
          ),
            child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      _selectedLocation,
                      style: GoogleFonts.raleway(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.keyboard_arrow_down, size: 10, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => FilterModal.show(context),
            borderRadius: BorderRadius.circular(25),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(Icons.tune, size: 22, color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Search button row: 70px height, tap to open search overlay (Figma 21-3735).
  Widget _buildSearchBarRow(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleSearchOverlay,
        borderRadius: BorderRadius.circular(25),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: FigmaHantiRiyoTokens.exploreSearchGlassBlurSigma,
              sigmaY: FigmaHantiRiyoTokens.exploreSearchGlassBlurSigma,
            ),
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: FigmaHantiRiyoTokens.exploreSearchGlassFill,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: AppColors.greyBarelyMedium),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search House, Apartment, etc',
                      style: GoogleFonts.raleway(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.inputPlaceholder,
                        letterSpacing: 0.36,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const double _modalSearchInnerRadius = 22;
  static const double _modalSearchInsetBorder = 2.5;

  /// Figma 21:3684 — search field: blur shell + inner padding + inset focus ring (inside field).
  Widget _buildFigmaModalSearchField(BuildContext context) {
    final focused = _modalSearchFocusNode.hasFocus;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [FigmaHantiRiyoTokens.exploreSearchModalGoldShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: FigmaHantiRiyoTokens.exploreSearchGlassBlurSigma,
            sigmaY: FigmaHantiRiyoTokens.exploreSearchGlassBlurSigma,
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 70),
            color: FigmaHantiRiyoTokens.exploreSearchGlassFill,
            padding: const EdgeInsets.all(_modalSearchInsetBorder),
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_modalSearchInnerRadius),
                border: Border.all(
                  color: focused ? AppColors.primary : Colors.transparent,
                  width: 1.25,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: TextField(
                  controller: _searchController,
                  focusNode: _modalSearchFocusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search House, Apartment, etc',
                    hintStyle: GoogleFonts.raleway(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inputPlaceholder,
                      letterSpacing: 0.36,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    isDense: false,
                    contentPadding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
                    suffixIcon: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10, top: 2, bottom: 2),
                      child: Icon(Icons.search, size: 20, color: AppColors.textPrimary),
                    ),
                    suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  style: GoogleFonts.raleway(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.36,
                  ),
                  onSubmitted: _runSearch,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Figma 21:3685 — `Recent Search` card: h~201, blur 9, r25, gold shadow, 18 bold title, 10 semibold Clear.
  Widget _buildFigmaRecentSearchCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [FigmaHantiRiyoTokens.exploreSearchModalGoldShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
          child: Container(
            height: FigmaHantiRiyoTokens.exploreSearchRecentCardHeight,
            color: FigmaHantiRiyoTokens.exploreSearchGlassFill,
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 21,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Search',
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.54,
                        ),
                      ),
                      if (_recentSearches.isNotEmpty)
                        GestureDetector(
                          onTap: _clearRecentSearches,
                          child: Text(
                            'Clear',
                            style: GoogleFonts.raleway(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.3,
                              height: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _recentSearches.isEmpty
                      ? Center(
                          child: Text(
                            'No recent searches',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.raleway(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.greyMedium,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          physics: const ClampingScrollPhysics(),
                          itemCount: _recentSearches.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 15),
                          itemBuilder: (context, i) =>
                              _buildFigmaRecentSearchRow(context, _recentSearches[i]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Figma 21:3638 / 21:3690 — 30px row, clock in tinted circle or estate thumb + 12px semibold `#53587A`.
  Widget _buildFigmaRecentSearchRow(BuildContext context, String text) {
    final imageUrl = _imageUrlForRecentQuery(text);

    return SizedBox(
      height: 30,
      child: Row(
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FigmaHantiRiyoTokens.exploreSearchThumbRadius),
                border: Border.all(
                  color: FigmaHantiRiyoTokens.exploreSearchThumbBorder,
                  width: FigmaHantiRiyoTokens.exploreSearchThumbBorderWidth,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
                  Container(color: FigmaHantiRiyoTokens.exploreSearchThumbOverlay),
                ],
              ),
            )
          else
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FigmaHantiRiyoTokens.exploreSearchClockPill,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(Icons.access_time, size: 14, color: AppColors.greyMedium),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _searchController.text = text;
                _runSearch(text);
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.raleway(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greyMedium,
                    letterSpacing: 0.36,
                  ),
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _removeRecentSearch(text),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: AppColors.greyBarelyMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom section: floating pill + cards + pagination over map (Figma 21-3695, 21-3735).
  Widget _buildBottomSection(BuildContext context) {
    if (_loading || _isSearching) return const SizedBox.shrink();
    final isEmpty = _visibleEstates.isEmpty;
    final count = _visibleEstates.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.white.withValues(alpha: 0.92)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: isEmpty
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildNearbyPill(context, isEmpty: true, count: 0),
                  ),
                  const SizedBox(height: 20),
                  _buildEmptyState(context),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerLeft, child: _buildNearbyPill(context, isEmpty: false, count: count)),
                  const SizedBox(height: 20),
                  _buildResultsSection(context),
                ],
              ),
      ),
    );
  }

  /// "Nearby You" pill: Figma 21-3726 – left-aligned, yellow circle + count.
  Widget _buildNearbyPill(BuildContext context, {required bool isEmpty, required int count}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF234F68),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              isEmpty
                  ? Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '!',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.36,
                          height: 1,
                        ),
                      ),
                    )
                  : Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.36,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(width: 8),
              Text(
                'Nearby You',
                style: GoogleFonts.raleway(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty state: dark blue card per Figma 21-3735 "Item / Header - Error" (w-[307px]).
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 327),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF1F4C6B),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              "Can't found real estate nearby you",
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                letterSpacing: 0.36,
                height: 20 / 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Horizontal estate cards + pagination (Figma 21-3695).
  Widget _buildResultsSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _visibleEstates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final e = _visibleEstates[i];
              return EstateCard.horizontal(
                title: e.title,
                price: e.price,
                rating: e.rating,
                location: e.location,
                imageUrl: e.imageUrl,
                category: e.displayCategory,
                isSaved: _savedIds.contains(e.id),
                onToggleSaved: () => _toggleSaved(e),
                onTap: () => context.push(AppRoutes.estateDetail(e.id)),
                compact: true,
                withBlur: true,
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildPagination(context),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Pagination: "1–50 / 200" + 32px prev/next buttons (Figma 21-3695).
  Widget _buildPagination(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$_pageStart–$_pageEnd / $_totalCount',
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            letterSpacing: 0.36,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaginationButton(
              onPressed: _pageStart > 1 ? () => setState(() { _pageStart -= 50; _pageEnd -= 50; }) : null,
              icon: Icons.chevron_left,
            ),
            const SizedBox(width: 12),
            _buildPaginationButton(
              onPressed: _pageEnd < _totalCount ? () => setState(() { _pageStart += 50; _pageEnd += 50; }) : null,
              icon: Icons.chevron_right,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaginationButton({VoidCallback? onPressed, required IconData icon}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.greySoft1,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: Offset.zero,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18,
            color: onPressed != null ? AppColors.textPrimary : AppColors.greyBarelyMedium,
          ),
        ),
      ),
    );
  }
}
