import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/maps/google_directions_client.dart';
import '../../../core/maps/google_geocoding_client.dart';
import '../../../core/maps/maps_api_key_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/figma_tokens.dart';
import '../../profile/data/repositories/profile_repository.dart';
import '../../profile/utils/profile_avatar_letter.dart';
import '../../search/utils/map_geo_utils.dart';
import '../../search/utils/map_pin_descriptor.dart';
import '../data/models/top_location_item.dart';
import '../data/repositories/estate_repository.dart';
import '../widgets/location_modal.dart';

/// A **nearby listing** on the full map: same custom image pin as detail, tappable → estate detail.
class ListingMapNearbyPin {
  const ListingMapNearbyPin({
    required this.id,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String imageUrl;
  final double latitude;
  final double longitude;

  LatLng get position => LatLng(latitude, longitude);
}

/// Passed via [GoRouterState.extra] when opening **Figma `28:4432`** (`Detail / View on Map`).
class ListingMapRouteArgs {
  const ListingMapRouteArgs({
    required this.estateId,
    required this.title,
    required this.locationLabel,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.regionLabel,
    this.nearbyPins = const [],
  });

  final String estateId;
  final String title;
  /// Full address for bottom “Location detail” card.
  final String locationLabel;
  final String imageUrl;
  final double latitude;
  final double longitude;
  /// Short label for the white dropdown pill (e.g. `Jakarta, Indonesia`).
  final String? regionLabel;
  /// Other listings (e.g. “Nearby recommended”) — image pins, tap opens that property’s detail.
  final List<ListingMapNearbyPin> nearbyPins;

  LatLng get target => LatLng(latitude, longitude);

  static String deriveRegionChip(String location) {
    final parts = location.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[parts.length - 2]}, ${parts[parts.length - 1]}';
    }
    return location.trim().isNotEmpty ? location : 'Jakarta, Indonesia';
  }
}

/// Full-screen map — **Figma `28:4432`** (`Detail / View on Map`).
class ListingFullMapScreen extends StatefulWidget {
  const ListingFullMapScreen({super.key, required this.args});

  final ListingMapRouteArgs args;

  @override
  State<ListingFullMapScreen> createState() => _ListingFullMapScreenState();
}

class _ListingFullMapScreenState extends State<ListingFullMapScreen> {
  final _estateRepo = EstateRepository();

  BitmapDescriptor? _listingPin;
  /// Same teardrop as property pins, image = user profile avatar ([`createMapPinDescriptor`]).
  BitmapDescriptor? _explorerPin;
  final Map<String, BitmapDescriptor?> _nearbyPinIcons = {};
  final _mapReady = Completer<GoogleMapController>();

  /// Map “you / explore” point — [`LocationModal`] (same as home) or long-press.
  late LatLng _explorerPoint;
  late String _regionPillText;
  bool _geocodingBusy = false;

  /// Driving duration to listing ([Directions API]); null → estimate from straight-line distance.
  DirectionsLegSummary? _drivingLeg;

  /// Grey fader stops — `rgba(83,88,122,0.31)` → transparent (`28:4433` / `28:4434`).
  static const Color _faderGrey = Color(0x4F53587A);

  /// Route line — green (`28:4432` map).
  static const Color _routeGreen = Color(0xFF8BC83F);

  /// Card shadow — `0px 17px 80px rgba(199,191,222,0.7)`.
  static final List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: const Color(0xB3C7BFDE),
      blurRadius: 40,
      offset: const Offset(0, 17),
      spreadRadius: -12,
    ),
  ];

  ListingMapRouteArgs get _a => widget.args;

  /// Never blank: API address → title → coordinates.
  String get _propertyAddressDisplay {
    final a = _a.locationLabel.trim();
    if (a.isNotEmpty) return a;
    final t = _a.title.trim();
    if (t.isNotEmpty) return t;
    return '${_a.target.latitude.toStringAsFixed(5)}, ${_a.target.longitude.toStringAsFixed(5)}';
  }

  /// First line of bottom card: listing title, else address/coords.
  String get _detailCardLocationName {
    final t = _a.title.trim();
    if (t.isNotEmpty) return t;
    return _propertyAddressDisplay;
  }

  @override
  void initState() {
    super.initState();
    _explorerPoint = LatLng(_a.target.latitude + 0.007, _a.target.longitude - 0.005);
    _regionPillText = _a.regionLabel?.trim().isNotEmpty == true
        ? _a.regionLabel!.trim()
        : ListingMapRouteArgs.deriveRegionChip(_a.locationLabel);
    for (final p in _a.nearbyPins) {
      _nearbyPinIcons[p.id] = null;
    }
    _loadPins();
    _loadExplorerPin();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshDrivingDirections());
  }

  Future<void> _refreshDrivingDirections() async {
    if (!mounted) return;
    final leg = await GoogleDirectionsClient.drivingLeg(_explorerPoint, _a.target);
    if (!mounted) return;
    setState(() => _drivingLeg = leg);
  }

  /// Rough drive-time guess when Directions API is unavailable (~32 km/h average).
  static int _estimatedDriveMinutesFromMeters(double meters) {
    if (meters <= 0) return 1;
    final km = meters / 1000;
    return math.max(1, (km / 32 * 60).round());
  }

  Future<void> _loadExplorerPin() async {
    String? avatarUrl;
    String? avatarLetter;
    try {
      final profile = await ProfileRepository().getMyProfile();
      final u = profile.avatarUrl?.trim();
      if (u != null && u.isNotEmpty) avatarUrl = u;
      final letter = profileAvatarLetterFromName(profile.name);
      avatarLetter = letter.isEmpty ? null : letter;
    } catch (_) {}
    try {
      final icon = await createMapPinDescriptor(
        imageUrl: avatarUrl,
        avatarLetter: avatarLetter,
        useProfileStyleFallback: true,
      );
      if (!mounted) return;
      setState(() => _explorerPin = icon);
    } catch (_) {
      try {
        final fallback = await createMapPinDescriptor(
          useProfileStyleFallback: true,
        );
        if (mounted) setState(() => _explorerPin = fallback);
      } catch (_) {}
    }
  }

  String _shortPillLabel(String formattedAddress) {
    final t = formattedAddress.trim();
    if (t.isEmpty) return _regionPillText;
    if (t.length <= 44) return t;
    return ListingMapRouteArgs.deriveRegionChip(t);
  }

  Future<void> _applyChosenExplorerPoint(LatLng p) async {
    setState(() {
      _explorerPoint = p;
      _geocodingBusy = true;
    });
    final addr = await GoogleGeocodingClient.reverseGeocode(p);
    if (!mounted) return;
    setState(() {
      _geocodingBusy = false;
      if (addr != null && addr.isNotEmpty) {
        _regionPillText = _shortPillLabel(addr);
      } else {
        _regionPillText =
            '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}';
      }
    });
    await _animateToFitListingAndExplorer();
    await _refreshDrivingDirections();
  }

  Future<void> _animateToFitListingAndExplorer() async {
    if (!_mapReady.isCompleted) return;
    final c = await _mapReady.future;
    final t = _a.target;
    final e = _explorerPoint;
    final minLat = math.min(t.latitude, e.latitude) - 0.012;
    final maxLat = math.max(t.latitude, e.latitude) + 0.012;
    final minLng = math.min(t.longitude, e.longitude) - 0.012;
    final maxLng = math.max(t.longitude, e.longitude) + 0.012;
    try {
      await c.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          72,
        ),
      );
    } catch (_) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(e, 14));
    }
  }

  /// Same sheet as home header — [`LocationModal`] (Figma 13-1231).
  Future<void> _openSelectLocationModal(BuildContext context) async {
    await MapsApiKeyProvider.resolve();
    if (!context.mounted) return;
    List<TopLocationItem> locations;
    try {
      locations = await _estateRepo.getTopLocations();
    } catch (_) {
      locations = const [];
    }
    if (!context.mounted) return;
    await LocationModal.show(
      context,
      topLocations: locations,
      initialLocation: _regionPillText,
      onSelectFuture: _geocodePlaceNameFromHomeModal,
    );
  }

  Future<void> _geocodePlaceNameFromHomeModal(String placeName) async {
    final apiKey = (await MapsApiKeyProvider.resolve()).trim();
    if (apiKey.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add your Maps API key (see MAP_SETUP.md) and enable Geocoding API.',
          ),
        ),
      );
      return;
    }
    setState(() => _geocodingBusy = true);
    final place = await GoogleGeocodingClient.geocodeAddress(placeName);
    if (!mounted) return;
    setState(() => _geocodingBusy = false);
    if (place == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find that location.')),
      );
      return;
    }
    setState(() {
      _explorerPoint = place.location;
      _regionPillText = _shortPillLabel(place.formattedAddress);
    });
    await _animateToFitListingAndExplorer();
    await _refreshDrivingDirections();
  }

  Future<void> _loadPins() async {
    final mainUrl = _a.imageUrl.trim().isNotEmpty ? _a.imageUrl : null;
    final mainIcon = await createMapPinDescriptor(imageUrl: mainUrl);
    if (!mounted) return;
    setState(() => _listingPin = mainIcon);

    for (final pin in _a.nearbyPins) {
      final u = pin.imageUrl.trim().isNotEmpty ? pin.imageUrl : null;
      createMapPinDescriptor(imageUrl: u).then((icon) {
        if (!mounted) return;
        setState(() => _nearbyPinIcons[pin.id] = icon);
      });
    }
  }

  Future<void> _recenterOnListing() async {
    if (!_mapReady.isCompleted) return;
    final c = await _mapReady.future;
    await c.animateCamera(CameraUpdate.newLatLngZoom(_a.target, 15.2));
  }

  Set<Marker> _buildMarkers(BuildContext context) {
    final out = <Marker>{
      Marker(
        markerId: MarkerId('explorer_${_a.estateId}'),
        position: _explorerPoint,
        icon: _explorerPin ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        anchor: Offset(0.5, _explorerPin != null ? 0.95 : 1),
      ),
    };
    for (final pin in _a.nearbyPins) {
      final custom = _nearbyPinIcons[pin.id];
      out.add(
        Marker(
          markerId: MarkerId('nearby_${pin.id}'),
          position: pin.position,
          icon: custom ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: Offset(0.5, custom != null ? 0.95 : 1),
          onTap: () => context.push(AppRoutes.estateDetail(pin.id)),
        ),
      );
    }
    out.add(
      Marker(
        markerId: MarkerId('listing_${_a.estateId}'),
        position: _a.target,
        icon: _listingPin ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: Offset(0.5, _listingPin != null ? 0.95 : 1),
      ),
    );
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final titleC = FigmaHantiRiyoTokens.exploreSearchTextTitle;
    final listC = FigmaHantiRiyoTokens.exploreSearchTextList;
    final s = FigmaHantiRiyoTokens.listingDetailToolbarSize;
    final r = FigmaHantiRiyoTokens.listingDetailToolbarRadius;
    final topPad = MediaQuery.paddingOf(context).top;

    final initial = CameraPosition(target: _a.target, zoom: 14.8);

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('route'),
        color: _routeGreen,
        width: 4,
        points: [_explorerPoint, _a.target],
      ),
    };

    final circles = <Circle>{
      Circle(
        circleId: const CircleId('focus'),
        center: _a.target,
        radius: 520,
        fillColor: const Color(0x2653587A),
        strokeColor: const Color(0x5953587A),
        strokeWidth: 1,
      ),
    };

    return Scaffold(
      backgroundColor: AppColors.textSecondary,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(FigmaHantiRiyoTokens.listingDetailHeroRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GoogleMap(
              initialCameraPosition: initial,
              onMapCreated: (c) {
                if (!_mapReady.isCompleted) _mapReady.complete(c);
              },
              onLongPress: (LatLng p) => _applyChosenExplorerPoint(p),
              markers: _buildMarkers(context),
              polylines: polylines,
              circles: circles,
              mapType: MapType.normal,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              liteModeEnabled: false,
              padding: EdgeInsets.only(top: topPad + 120, bottom: 200),
            ),

            if (_geocodingBusy)
              Positioned.fill(
                child: AbsorbPointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Updating location…',
                              style: GoogleFonts.raleway(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Top fader (`28:4434`)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 220,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_faderGrey, _faderGrey.withValues(alpha: 0)],
                      stops: const [0.35, 1],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom fader (`28:4435`)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 220,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [_faderGrey, _faderGrey.withValues(alpha: 0)],
                      stops: const [0.35, 1],
                    ),
                  ),
                ),
              ),
            ),

            // Header: back + public facility chips (`28:4461`–`28:4471`)
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _glassBackButton(context, s, r),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _facilityChip('1 Hospital'),
                          const SizedBox(width: 10),
                          _facilityChip('2 Gas stations'),
                          const SizedBox(width: 10),
                          _facilityChip('1 Schools'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom chrome: dropdown + recenter + location card (`28:4449`–`28:4460`)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _locationDropdownPill(context)),
                          const SizedBox(width: 12),
                          _recenterButton(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _locationDetailCard(titleC, listC),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassBackButton(BuildContext context, double s, double r) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.pop(),
        borderRadius: BorderRadius.circular(r),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: FigmaHantiRiyoTokens.listingDetailBackBlurSigma,
              sigmaY: FigmaHantiRiyoTokens.listingDetailBackBlurSigma,
            ),
            child: Container(
              width: s,
              height: s,
              color: FigmaHantiRiyoTokens.listingDetailBackBlurFill,
              alignment: Alignment.center,
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _facilityChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 17.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.raleway(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: FigmaHantiRiyoTokens.exploreSearchTextList,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _locationDropdownPill(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: () => _openSelectLocationModal(context),
        borderRadius: BorderRadius.circular(25),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: FigmaHantiRiyoTokens.listingDetailBackBlurSigma,
              sigmaY: FigmaHantiRiyoTokens.listingDetailBackBlurSigma,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(25),
                boxShadow: _cardShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined, size: 15, color: AppColors.textPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _regionPillText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.raleway(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textPrimary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _recenterButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _recenterOnListing,
        customBorder: const CircleBorder(),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: FigmaHantiRiyoTokens.listingDetailBackBlurSigma,
              sigmaY: FigmaHantiRiyoTokens.listingDetailBackBlurSigma,
            ),
            child: Container(
              width: 50,
              height: 50,
              color: FigmaHantiRiyoTokens.listingDetailReviewCardFill,
              alignment: Alignment.center,
              child: Icon(Icons.my_location_rounded, size: 22, color: Colors.white.withValues(alpha: 0.95)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationDetailCard(Color titleC, Color listC) {
    final m = haversineMeters(_explorerPoint, _a.target);
    final cardinal = compassDirection4(_explorerPoint, _a.target);
    final seconds = (_drivingLeg != null && _drivingLeg!.durationSeconds > 0)
        ? _drivingLeg!.durationSeconds
        : (_estimatedDriveMinutesFromMeters(m) * 60);
    final timeStr = formatDurationCompact(seconds);
    final hasRoute = _drivingLeg != null && _drivingLeg!.distanceText.trim().isNotEmpty;
    final distPart = hasRoute
        ? _drivingLeg!.distanceText.trim()
        : '≈ ${formatDistanceKm(m)}';
    final timeLabel = hasRoute ? '$timeStr drive' : '~$timeStr drive';

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: FigmaHantiRiyoTokens.listingDetailBackBlurSigma,
          sigmaY: FigmaHantiRiyoTokens.listingDetailBackBlurSigma,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(25),
            boxShadow: _cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _detailCardLocationName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.raleway(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  color: titleC,
                  letterSpacing: 0.39,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$cardinal · $timeLabel · $distPart',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.raleway(
                  fontSize: 12,
                  height: 1.35,
                  color: listC,
                  letterSpacing: 0.36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}