import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/figma_tokens.dart';
import '../../search/utils/map_pin_descriptor.dart';

/// Map preview on listing detail — **Figma `28:4593`** (map chrome + placement).
/// Pin art matches **`21-3729` / `map_pin_descriptor`** (teardrop, navy, gold glow, listing photo).
class ListingDetailMapPreview extends StatefulWidget {
  const ListingDetailMapPreview({
    super.key,
    required this.target,
    required this.imageUrl,
    this.onViewAllTap,
    this.height = 235,
  });

  final LatLng target;
  final String imageUrl;
  final VoidCallback? onViewAllTap;
  final double height;

  @override
  State<ListingDetailMapPreview> createState() => _ListingDetailMapPreviewState();
}

class _ListingDetailMapPreviewState extends State<ListingDetailMapPreview> {
  BitmapDescriptor? _pin;
  late CameraPosition _initial;

  @override
  void initState() {
    super.initState();
    _initial = CameraPosition(target: widget.target, zoom: 15.5);
    _loadPin();
  }

  @override
  void didUpdateWidget(ListingDetailMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.target.latitude != widget.target.latitude ||
        oldWidget.target.longitude != widget.target.longitude) {
      _initial = CameraPosition(target: widget.target, zoom: 15.5);
      _loadPin();
    }
  }

  Future<void> _loadPin() async {
    final url = widget.imageUrl.trim().isNotEmpty ? widget.imageUrl : null;
    final icon = await createMapPinDescriptor(imageUrl: url);
    if (!mounted) return;
    setState(() => _pin = icon);
  }

  @override
  Widget build(BuildContext context) {
    final rad = FigmaHantiRiyoTokens.exploreSearchRadiusLg;
    return ClipRRect(
      borderRadius: BorderRadius.circular(rad),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.greySoft1,
              child: _pin == null
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: _initial,
                      markers: {
                        Marker(
                          markerId: const MarkerId('listing_detail'),
                          position: widget.target,
                          icon: _pin!,
                          anchor: const Offset(0.5, 0.95),
                        ),
                      },
                      mapType: MapType.normal,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      myLocationButtonEnabled: false,
                      myLocationEnabled: false,
                      rotateGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      zoomGesturesEnabled: true,
                      liteModeEnabled: false,
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                      },
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 50,
              child: Material(
                color: AppColors.categoryActive.withOpacity(0.5),
                child: InkWell(
                  onTap: widget.onViewAllTap,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: FigmaHantiRiyoTokens.listingDetailMapFooterBlurSigma,
                        sigmaY: FigmaHantiRiyoTokens.listingDetailMapFooterBlurSigma,
                      ),
                      child: ColoredBox(
                        color: FigmaHantiRiyoTokens.listingDetailMapFooterFill,
                        child: Center(
                          child: Text(
                            'View all on map',
                            style: GoogleFonts.raleway(
                              fontSize: 12,
                              height: 20 / 12,
                              color: AppColors.categoryActive,
                              letterSpacing: 0.36,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
