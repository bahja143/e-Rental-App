import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/maps/google_geocoding_client.dart';
import '../../../core/maps/maps_api_key_provider.dart';
import '../../../core/network/api_config.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/centered_header_bar.dart';
import '../../../shared/widgets/media_gallery_viewer.dart';
import '../../home/data/models/estate_item.dart';
import '../../home/data/repositories/estate_repository.dart';
import '../data/models/estate_draft.dart';
import '../data/repositories/add_estate_repository.dart';

class AddEstateScreen extends StatefulWidget {
  const AddEstateScreen({super.key, this.estateId});

  final String? estateId;

  @override
  State<AddEstateScreen> createState() => _AddEstateScreenState();
}

enum _AddEstatePublishState { none, success, error }

class _AddEstateScreenState extends State<AddEstateScreen> {
  static const _initialLatLng = LatLng(9.5624, 44.0770);
  static const _fallbackAreaLabel = 'Hargeisa, Somalia';
  static const _footerButtonHeight = 54.0;
  static const _footerBottomSpacing = 24.0;
  static const _footerTopSpacing = 24.0;
  static const _amenityOptions = <String>[
    'Balcony',
    'Parking Spaces',
    'Garden',
    'Swimming Pool',
    'Gym',
    'CCTV',
    'Elevator',
    'Pet Friendly',
  ];
  static const _categoryOptions = <String>[
    'House',
    'Apartment',
    'Hotel',
    'Villa',
    'Cottage',
  ];

  int _step = 0;
  bool _publishing = false;
  bool _lookingUpAddress = false;
  _AddEstatePublishState _publishState = _AddEstatePublishState.none;
  bool _loadingEdit = false;
  bool _editSuccessVisible = false;
  final _imagePicker = ImagePicker();
  final _scrollController = ScrollController();
  final _locationFocusNode = FocusNode();
  GoogleMapController? _mapController;

  final _titleController = TextEditingController(text: 'The Lodge House');
  final _locationController = TextEditingController();
  final _priceController = TextEditingController(text: '180000');
  final _sellPriceController = TextEditingController(text: '180000');
  final _rentPriceController = TextEditingController(text: '320');
  final _descriptionController = TextEditingController();
  final _floorAreaController = TextEditingController(text: '1200');
  final _constructionYearController = TextEditingController();

  String _listingType = 'rent';
  String _rentPeriod = 'monthly';
  String _category = 'House';
  LatLng? _selectedLatLng;
  LatLng _mapCameraTarget = _initialLatLng;
  String _mapAreaLabel = _fallbackAreaLabel;
  Timer? _locationSearchDebounce;
  List<String> _locationSuggestions = <String>[];
  final List<String> _imagePaths = <String>[];
  final List<String> _videoPaths = <String>[];
  int _bedrooms = 3;
  int _bathrooms = 2;
  int _livingRooms = 2;
  int _kitchens = 2;
  int _numberOfFloors = 2;
  bool _isFinished = true;
  final Set<String> _selectedAmenities = <String>{
    'Balcony',
    'Parking Spaces',
    'Swimming Pool',
    'Gym'
  };
  final Map<String, int> _nearbyPlaces = <String, int>{
    'Schools': 3,
    'Hospitals': 2,
    'Shopping Malls': 2,
    'Gas Stations': 2,
  };
  EstateItem? _editingItem;

  bool get _isEditMode => (widget.estateId ?? '').trim().isNotEmpty;
  String get _screenTitle => _isEditMode ? 'Edit Listing' : 'Add Listing';
  bool get _hasLocationSelection =>
      _locationController.text.trim().isNotEmpty || _selectedLatLng != null;
  String get _locationSummaryText {
    final typedLocation = _locationController.text.trim();
    if (typedLocation.isNotEmpty) return typedLocation;
    if (_mapAreaLabel.isNotEmpty) return _mapAreaLabel;
    return 'Search for a city or tap the map to choose a location.';
  }

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadEditListing();
    } else {
      unawaited(_setInitialLocationView());
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _scrollController.dispose();
    _locationSearchDebounce?.cancel();
    _locationFocusNode.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _sellPriceController.dispose();
    _rentPriceController.dispose();
    _descriptionController.dispose();
    _floorAreaController.dispose();
    _constructionYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingEdit) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    final mediaQuery = MediaQuery.of(context);
    final safeBottom = mediaQuery.padding.bottom;
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final footerBottomPadding = _footerBottomSpacing + safeBottom;
    final formBottomPadding =
        _footerTopSpacing + _footerButtonHeight + footerBottomPadding + keyboardInset;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: CenteredHeaderBar(
                      title: _screenTitle,
                      onBack: _handleBack,
                      titleSize: 15,
                      titleSpacing: 0,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        24,
                        22,
                        24,
                        formBottomPadding,
                      ),
                      child: _isEditMode
                          ? _buildEditForm()
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: switch (_step) {
                                0 => _buildFormDetailStep(),
                                1 => _buildLocationStep(),
                                2 => _buildPhotosStep(),
                                _ => _buildExtraInformationStep(),
                              },
                            ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      0,
                      24,
                      footerBottomPadding,
                    ),
                    child: _isEditMode
                        ? _PrimaryWizardButton(
                            label: _publishing ? 'Updating...' : 'Update',
                            onTap: _publishing ? null : _updateEstateListing,
                          )
                        : _step == 2
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _CircleActionButton(
                                    icon: Icons.arrow_back_ios_new_rounded,
                                    onTap: _handleBack,
                                    iconSize: 20,
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 190,
                                    child: _PrimaryWizardButton(
                                      label: 'Next',
                                      onTap: _publishing ? null : _handleNext,
                                    ),
                                  ),
                                ],
                              )
                            : _PrimaryWizardButton(
                                label: _step == 3
                                    ? (_publishing ? 'Publishing...' : 'Finish')
                                    : 'Next',
                                onTap: _publishing ? null : _handleNext,
                              ),
                  ),
                ],
              ),
              if (_editSuccessVisible)
                Positioned.fill(
                  child: _EditListingSuccessOverlay(
                    onClose: () {
                      setState(() => _editSuccessVisible = false);
                      context.pop();
                    },
                  ),
                ),
              if (_publishState != _AddEstatePublishState.none)
                Positioned.fill(
                  child: _AddEstateResultOverlay(
                    success: _publishState == _AddEstatePublishState.success,
                    onPrimaryTap: _publishState == _AddEstatePublishState.success
                        ? () => context.go(AppRoutes.home)
                        : _retryPublish,
                    onSecondaryTap:
                        _publishState == _AddEstatePublishState.success
                            ? _addMore
                            : () => setState(
                                () => _publishState = _AddEstatePublishState.none),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormDetailStep() {
    return Column(
      key: const ValueKey<int>(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroTitle(
          normalText: 'Hi Josh, Fill detail of your ',
          accentText: 'real estate',
        ),
        const SizedBox(height: 34),
        _InputCard(
          controller: _titleController,
          hint: 'The Lodge House',
          trailing:
              const Icon(Icons.home_outlined, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 34),
        _SectionTitle('Listing type'),
        const SizedBox(height: 22),
        Wrap(
          spacing: 9,
          runSpacing: 10,
          children: [
            _ChoiceChipButton(
              label: 'Rent',
              active: _listingType == 'rent',
              onTap: () => setState(() => _listingType = 'rent'),
            ),
            _ChoiceChipButton(
              label: 'Sell',
              active: _listingType == 'sell',
              onTap: () => setState(() => _listingType = 'sell'),
            ),
          ],
        ),
        const SizedBox(height: 34),
        _SectionTitle('Property category'),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 14,
          children: [
            for (final category in _categoryOptions)
              _ChoiceChipButton(
                label: category,
                active: _category == category,
                onTap: () => setState(() => _category = category),
              ),
          ],
        ),
        const SizedBox(height: 140),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      key: const ValueKey<String>('edit'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditPreviewCard(),
        const SizedBox(height: 28),
        _SectionTitle('Listing Title'),
        const SizedBox(height: 12),
        _InputCard(
          controller: _titleController,
          hint: 'Schoolview House',
          trailing:
              const Icon(Icons.home_outlined, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 24),
        _SectionTitle('Listing type'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 9,
          runSpacing: 10,
          children: [
            _ChoiceChipButton(
              label: 'Rent',
              active: _listingType == 'rent',
              onTap: () => setState(() => _listingType = 'rent'),
            ),
            _ChoiceChipButton(
              label: 'Sell',
              active: _listingType == 'sell',
              onTap: () => setState(() => _listingType = 'sell'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle('Property category'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 14,
          children: [
            for (final category in _categoryOptions)
              _ChoiceChipButton(
                label: category,
                active: _category == category,
                onTap: () => setState(() => _category = category),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle('Location'),
        const SizedBox(height: 12),
        _buildLocationInfoCard(),
        const SizedBox(height: 12),
        _InputCard(
          controller: _locationController,
          focusNode: _locationFocusNode,
          hint: 'Search city or area',
          textInputAction: TextInputAction.search,
          onChanged: _handleLocationQueryChanged,
          onSubmitted: (_) => _searchAddress(),
          trailing: _lookingUpAddress
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                )
              : IconButton(
                  onPressed: _searchAddress,
                  icon: const Icon(Icons.search_rounded,
                      color: AppColors.textPrimary),
                ),
        ),
        if (_locationSuggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildLocationSuggestions(),
        ],
        const SizedBox(height: 12),
        _buildMapCard(height: 200),
        const SizedBox(height: 24),
        _buildMediaManager(sectionTitle: 'Listing Media'),
        const SizedBox(height: 24),
        _SectionTitle('Sell Price'),
        const SizedBox(height: 12),
        _InputCard(
          controller: _sellPriceController,
          hint: '\$ 150,000',
          keyboardType: TextInputType.number,
          trailing: const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.attach_money_rounded,
                color: AppColors.textPrimary, size: 18),
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle('Rent Price'),
        const SizedBox(height: 12),
        _InputCard(
          controller: _rentPriceController,
          hint: '\$ 320 / month',
          keyboardType: TextInputType.number,
          trailing: const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.attach_money_rounded,
                color: AppColors.textPrimary, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _ChoiceChipButton(
              label: 'Monthly',
              active: _rentPeriod == 'monthly',
              onTap: () => setState(() => _rentPeriod = 'monthly'),
            ),
            _ChoiceChipButton(
              label: 'Yearly',
              active: _rentPeriod == 'yearly',
              onTap: () => setState(() => _rentPeriod = 'yearly'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle('Property Features'),
        const SizedBox(height: 16),
        _CounterInput(
          label: 'Bedroom',
          value: _bedrooms,
          onChanged: (value) => setState(() => _bedrooms = value),
        ),
        const SizedBox(height: 15),
        _CounterInput(
          label: 'Bathroom',
          value: _bathrooms,
          onChanged: (value) => setState(() => _bathrooms = value),
        ),
        const SizedBox(height: 15),
        _CounterInput(
          label: 'Living Room',
          value: _livingRooms,
          onChanged: (value) => setState(() => _livingRooms = value),
        ),
        const SizedBox(height: 15),
        _CounterInput(
          label: 'Kitchen',
          value: _kitchens,
          onChanged: (value) => setState(() => _kitchens = value),
        ),
        const SizedBox(height: 15),
        _CounterInput(
          label: 'Number of Floors',
          value: _numberOfFloors,
          onChanged: (value) => setState(() => _numberOfFloors = value),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _InputCard(
                controller: _floorAreaController,
                hint: '1200',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InputCard(
                controller: _constructionYearController,
                hint: 'Construction Year',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _StatusToggle(
              label: 'Finished',
              active: _isFinished,
              onTap: () => setState(() => _isFinished = true),
            ),
            const SizedBox(width: 20),
            _StatusToggle(
              label: 'Unfinished',
              active: !_isFinished,
              onTap: () => setState(() => _isFinished = false),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle('Property Description'),
        const SizedBox(height: 12),
        _DescriptionBox(controller: _descriptionController),
        const SizedBox(height: 24),
        _SectionTitle('Amenities and Facilities'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final amenity in _amenityOptions)
              _ChoiceChipButton(
                label: amenity,
                active: _selectedAmenities.contains(amenity),
                onTap: () => setState(() {
                  if (_selectedAmenities.contains(amenity)) {
                    _selectedAmenities.remove(amenity);
                  } else {
                    _selectedAmenities.add(amenity);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle('Nearby Places'),
        const SizedBox(height: 16),
        for (final entry in _nearbyPlaces.entries) ...[
          _CounterInput(
            label: entry.key,
            value: entry.value,
            onChanged: (value) =>
                setState(() => _nearbyPlaces[entry.key] = value),
          ),
          const SizedBox(height: 15),
        ],
      ],
    );
  }

  Widget _buildEditPreviewCard() {
    final item = _editingItem;
    final previewRating = item?.rating;
    final mediaPath = _imagePaths.isNotEmpty
        ? _imagePaths.first
        : _videoPaths.isNotEmpty
            ? _videoPaths.first
            : (item?.imageUrl.trim().isNotEmpty ?? false)
                ? item!.imageUrl
                : null;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              width: 168,
              height: 104,
              child: _ListingImage(imagePath: mediaPath),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleController.text.trim().isEmpty
                      ? 'Listing'
                      : _titleController.text.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    height: 18 / 12,
                    letterSpacing: 0.36,
                  ),
                ),
                const SizedBox(height: 8),
                if ((previewRating ?? 0) > 0) ...[
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 9, color: AppColors.primary),
                      const SizedBox(width: 2),
                      Text(
                        previewRating!.toStringAsFixed(1),
                        style: GoogleFonts.montserrat(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 9, color: AppColors.greyMedium),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        _locationController.text.trim(),
                        maxLines: 2,
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
    );
  }

  Widget _buildLocationInfoCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: AppColors.greySoft1,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_on_outlined,
              color: AppColors.greyMedium),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            _locationSummaryText,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.greyMedium,
              height: 20 / 12,
              letterSpacing: 0.36,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard({required double height}) {
    final selectedLatLng = _selectedLatLng;
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _mapCameraTarget, zoom: 14),
              onMapCreated: (controller) {
                _mapController?.dispose();
                _mapController = controller;
                unawaited(_animateMapToSelectedLocation());
              },
              onTap: _selectMapLocation,
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              markers: selectedLatLng == null
                  ? const <Marker>{}
                  : {
                      Marker(
                        markerId: const MarkerId('estate'),
                        position: selectedLatLng,
                        draggable: true,
                        onDragEnd: _selectMapLocation,
                      ),
                    },
            ),
            Positioned(
              top: 14,
              right: 14,
              child: _MapFloatingActionButton(
                icon: Icons.my_location_rounded,
                onTap: _selectCurrentLocationFromMap,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(25)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 50,
                    color: Colors.white.withValues(alpha: 0.5),
                    alignment: Alignment.center,
                    child: Text(
                      _mapAreaLabel.isEmpty
                          ? 'Tap on the map or search above'
                          : _mapAreaLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.36,
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

  Widget _buildLocationStep() {
    return Column(
      key: const ValueKey<int>(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroTitle(
          normalText: 'Where is the ',
          accentText: 'location',
          trailingText: '?',
        ),
        const SizedBox(height: 34),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.greySoft1,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_outlined,
                  color: AppColors.greyMedium),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _locationSummaryText,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.greyMedium,
                  height: 20 / 12,
                  letterSpacing: 0.36,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _InputCard(
          controller: _locationController,
          focusNode: _locationFocusNode,
          hint: 'Search city or area',
          textInputAction: TextInputAction.search,
          onChanged: _handleLocationQueryChanged,
          onSubmitted: (_) => _searchAddress(),
          trailing: _lookingUpAddress
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                )
              : IconButton(
                  onPressed: _searchAddress,
                  icon: const Icon(Icons.search_rounded,
                      color: AppColors.textPrimary),
                ),
        ),
        if (_locationSuggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildLocationSuggestions(),
        ],
        const SizedBox(height: 18),
        _buildMapCard(height: 356),
      ],
    );
  }

  Widget _buildPhotosStep() {
    return Column(
      key: const ValueKey<int>(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroTitle(
          normalText: 'Add ',
          accentText: 'photos',
          trailingText: ' to your\nlisting',
        ),
        const SizedBox(height: 24),
        _buildMediaManager(),
      ],
    );
  }

  Widget _buildExtraInformationStep() {
    return Column(
      key: const ValueKey<int>(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroTitle(
          normalText: 'Almost ',
          accentText: 'finish',
          trailingText: ', complete\nthe listing',
        ),
        const SizedBox(height: 28),
        _SectionTitle(_listingType == 'sell' ? 'Sell Price' : 'Rent Price'),
        const SizedBox(height: 12),
        _InputCard(
          controller: _priceController,
          hint: _listingType == 'sell' ? '\$ 180,000' : '\$ 315 / month',
          keyboardType: TextInputType.number,
          trailing: const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.attach_money_rounded,
                color: AppColors.textPrimary, size: 18),
          ),
        ),
        if (_listingType == 'rent') ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _ChoiceChipButton(
                label: 'Monthly',
                active: _rentPeriod == 'monthly',
                onTap: () => setState(() => _rentPeriod = 'monthly'),
              ),
              _ChoiceChipButton(
                label: 'Yearly',
                active: _rentPeriod == 'yearly',
                onTap: () => setState(() => _rentPeriod = 'yearly'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 28),
        _SectionTitle('Property Features'),
        const SizedBox(height: 16),
        _CounterInput(
          label: 'Bedroom',
          value: _bedrooms,
          onChanged: (value) => setState(() => _bedrooms = value),
        ),
        const SizedBox(height: 15),
        _CounterInput(
          label: 'Bathroom',
          value: _bathrooms,
          onChanged: (value) => setState(() => _bathrooms = value),
        ),
        const SizedBox(height: 15),
        _CounterInput(
          label: 'Living Room',
          value: _livingRooms,
          onChanged: (value) => setState(() => _livingRooms = value),
        ),
        const SizedBox(height: 15),
        _CounterInput(
          label: 'Kitchen',
          value: _kitchens,
          onChanged: (value) => setState(() => _kitchens = value),
        ),
        const SizedBox(height: 15),
        _CounterInput(
          label: 'Number of Floors',
          value: _numberOfFloors,
          onChanged: (value) => setState(() => _numberOfFloors = value),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _InputCard(
                controller: _floorAreaController,
                hint: '1200',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InputCard(
                controller: _constructionYearController,
                hint: 'Construction Year',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _StatusToggle(
              label: 'Finished',
              active: _isFinished,
              onTap: () => setState(() => _isFinished = true),
            ),
            const SizedBox(width: 20),
            _StatusToggle(
              label: 'Unfinished',
              active: !_isFinished,
              onTap: () => setState(() => _isFinished = false),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _SectionTitle('Property Description'),
        const SizedBox(height: 12),
        _DescriptionBox(controller: _descriptionController),
        const SizedBox(height: 28),
        _SectionTitle('Amenities and Facilities'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final amenity in _amenityOptions)
              _ChoiceChipButton(
                label: amenity,
                active: _selectedAmenities.contains(amenity),
                onTap: () => setState(() {
                  if (_selectedAmenities.contains(amenity)) {
                    _selectedAmenities.remove(amenity);
                  } else {
                    _selectedAmenities.add(amenity);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 28),
        _SectionTitle('Nearby Places'),
        const SizedBox(height: 16),
        for (final entry in _nearbyPlaces.entries) ...[
          _CounterInput(
            label: entry.key,
            value: entry.value,
            onChanged: (value) =>
                setState(() => _nearbyPlaces[entry.key] = value),
          ),
          const SizedBox(height: 15),
        ],
      ],
    );
  }

  Widget _buildLocationSuggestions() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          for (final suggestion in _locationSuggestions.take(6))
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectLocationSuggestion(suggestion),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.greyMedium,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.36,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _toAreaLabel(String rawAddress) {
    final address = rawAddress.trim();
    if (address.isEmpty) return '';
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first;
    return '${parts.first}, ${parts[1]}';
  }

  Future<List<String>> _autocompleteLocationSuggestions(String input) async {
    final key = (await MapsApiKeyProvider.resolve()).trim();
    final query = input.trim();
    if (key.isEmpty || query.isEmpty) return const <String>[];

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': query,
        'types': 'geocode',
        'key': key,
      },
    );
    try {
      final res = await http.get(uri).timeout(ApiConfig.connectTimeout);
      if (res.statusCode != 200) return const <String>[];
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final predictions = json['predictions'] as List<dynamic>?;
      if (predictions == null || predictions.isEmpty) {
        return const <String>[];
      }
      return predictions
          .whereType<Map<String, dynamic>>()
          .map((item) => '${item['description'] ?? ''}'.trim())
          .where((item) => item.isNotEmpty)
          .take(6)
          .toList();
    } catch (_) {
      return const <String>[];
    }
  }

  void _handleLocationQueryChanged(String value) {
    _locationSearchDebounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      if (_locationSuggestions.isEmpty) return;
      setState(() => _locationSuggestions = <String>[]);
      return;
    }

    _locationSearchDebounce = Timer(const Duration(milliseconds: 280), () async {
      final currentQuery = _locationController.text.trim();
      if (currentQuery.isEmpty || currentQuery != query) return;
      final suggestions = await _autocompleteLocationSuggestions(currentQuery);
      if (!mounted || _locationController.text.trim() != currentQuery) return;
      setState(() {
        _locationSuggestions = suggestions;
      });
    });
  }

  Future<void> _selectCurrentLocationFromMap() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Please enable location services.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _showSnack('Location permission is required to use current location.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (!mounted) return;
      await _selectMapLocation(
        LatLng(position.latitude, position.longitude),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not load your current location.');
    }
  }

  Future<void> _setInitialLocationView() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (!mounted || _selectedLatLng != null) return;

      final currentLatLng = LatLng(position.latitude, position.longitude);
      setState(() => _mapCameraTarget = currentLatLng);
      await _animateMapToSelectedLocation();

      final address = await GoogleGeocodingClient.reverseGeocode(currentLatLng);
      if (!mounted || _selectedLatLng != null) return;
      if (address != null && address.trim().isNotEmpty) {
        setState(() => _mapAreaLabel = _toAreaLabel(address));
      }
    } catch (_) {
      // Keep the Hargeisa fallback when current location cannot be resolved.
    }
  }

  Future<void> _animateMapToSelectedLocation() async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _mapCameraTarget, zoom: 14),
      ),
    );
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _handleBack() {
    if (_editSuccessVisible) {
      setState(() => _editSuccessVisible = false);
      return;
    }
    if (_publishState != _AddEstatePublishState.none) {
      setState(() => _publishState = _AddEstatePublishState.none);
      return;
    }
    if (_isEditMode) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.profile);
      }
      return;
    }
    if (_step == 0) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.profile);
      }
      return;
    }
    setState(() => _step -= 1);
    _scrollToTop();
  }

  Future<void> _handleNext() async {
    switch (_step) {
      case 0:
        if (_titleController.text.trim().isEmpty) {
          _showSnack('Please enter a listing title.');
          return;
        }
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _step = 1);
        _scrollToTop();
        return;
      case 1:
        if (!_hasLocationSelection) {
          _showSnack('Please choose a location.');
          return;
        }
        if (!await _ensureResolvedLocation()) {
          return;
        }
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _step = 2);
        _scrollToTop();
        return;
      case 2:
        if (_totalMediaCount < 1) {
          _showSnack('Please add at least 1 photo or video.');
          return;
        }
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _step = 3);
        _scrollToTop();
        return;
      default:
        await _publishEstate();
    }
  }

  Future<void> _searchAddress() async {
    final query = _locationController.text.trim();
    if (query.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _lookingUpAddress = true;
      _locationSuggestions = <String>[];
    });
    try {
      final place = await GoogleGeocodingClient.geocodeAddress(query);
      if (!mounted) return;
      if (place == null) {
        setState(() => _lookingUpAddress = false);
        _showSnack('Could not find that location.');
        return;
      }
      setState(() {
        _lookingUpAddress = false;
        _mapCameraTarget = place.location;
        _selectedLatLng = place.location;
        _locationController.text = place.formattedAddress;
        _mapAreaLabel = _toAreaLabel(place.formattedAddress);
      });
      await _animateMapToSelectedLocation();
    } catch (_) {
      if (!mounted) return;
      setState(() => _lookingUpAddress = false);
      _showSnack('Could not search that location right now.');
    }
  }

  Future<bool> _ensureResolvedLocation() async {
    if (_selectedLatLng != null) return true;

    final query = _locationController.text.trim();
    if (query.isEmpty) {
      _showSnack('Please choose a location.');
      return false;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _lookingUpAddress = true;
      _locationSuggestions = <String>[];
    });

    try {
      final place = await GoogleGeocodingClient.geocodeAddress(query);
      if (!mounted) return false;
      if (place == null) {
        setState(() => _lookingUpAddress = false);
        _showSnack('Please choose a valid location from search or map.');
        return false;
      }

      setState(() {
        _lookingUpAddress = false;
        _selectedLatLng = place.location;
        _mapCameraTarget = place.location;
        _locationController.text = place.formattedAddress;
        _mapAreaLabel = _toAreaLabel(place.formattedAddress);
      });
      await _animateMapToSelectedLocation();
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(() => _lookingUpAddress = false);
      _showSnack('Could not resolve that location right now.');
      return false;
    }
  }

  Future<void> _selectMapLocation(LatLng position) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedLatLng = position;
      _mapCameraTarget = position;
      _lookingUpAddress = true;
      _locationSuggestions = <String>[];
    });
    await _animateMapToSelectedLocation();
    try {
      final address = await GoogleGeocodingClient.reverseGeocode(position);
      if (!mounted) return;
      setState(() {
        _lookingUpAddress = false;
        if (address != null && address.trim().isNotEmpty) {
          _mapAreaLabel = _toAreaLabel(address);
          _locationController.text = address.trim();
        } else {
          _mapAreaLabel = 'Selected location';
          _locationController.clear();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _lookingUpAddress = false);
      _showSnack('Could not load the selected location.');
    }
  }

  Future<void> _selectLocationSuggestion(
    String suggestion,
  ) async {
    setState(() {
      _locationController.text = suggestion;
      _locationSuggestions = <String>[];
    });
    await _searchAddress();
  }

  bool _isVideoPath(String path) {
    final value = path.toLowerCase();
    return value.endsWith('.mp4') ||
        value.endsWith('.mov') ||
        value.endsWith('.webm') ||
        value.endsWith('.avi') ||
        value.endsWith('.mkv') ||
        value.endsWith('.m4v');
  }

  Future<void> _pickGalleryMedia() async {
    try {
      final media = await _imagePicker.pickMultipleMedia(
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (!mounted || media.isEmpty) return;
      final imagePaths = <String>[];
      final videoPaths = <String>[];
      for (final item in media) {
        final path = item.path.trim();
        if (path.isEmpty) continue;
        if (_isVideoPath(path)) {
          videoPaths.add(path);
        } else {
          imagePaths.add(path);
        }
      }
      setState(() {
        _imagePaths.addAll(
          imagePaths.where((path) => !_imagePaths.contains(path)),
        );
        _videoPaths.addAll(
          videoPaths.where((path) => !_videoPaths.contains(path)),
        );
      });
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not open gallery media.');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (!mounted || result == null || result.files.isEmpty) return;
      final path = result.files.single.path?.trim() ?? '';
      if (path.isEmpty) {
        _showSnack('Could not open gallery video.');
        return;
      }
      setState(() {
        if (!_videoPaths.contains(path)) {
          _videoPaths.add(path);
        }
      });
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not open gallery video.');
    }
  }

  void _removeImage(int index) {
    if (index < 0 || index >= _imagePaths.length) return;
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  void _removeVideo(int index) {
    if (index < 0 || index >= _videoPaths.length) return;
    setState(() {
      _videoPaths.removeAt(index);
    });
  }

  Future<void> _publishEstate() async {
    if (!await _ensureResolvedLocation()) {
      return;
    }
    final price =
        double.tryParse(_priceController.text.trim().replaceAll(',', '')) ?? 0;
    final floorArea = double.tryParse(_floorAreaController.text.trim());
    final constructionYear =
        int.tryParse(_constructionYearController.text.trim());
    final draft = EstateDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      pricePerMonth: price,
      listingType: _listingType == 'rent' ? _rentPeriod : _listingType,
      category: _category,
      lat: _selectedLatLng?.latitude,
      lng: _selectedLatLng?.longitude,
      imagePaths: List<String>.from(_imagePaths),
      videoPaths: List<String>.from(_videoPaths),
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      livingRooms: _livingRooms,
      kitchens: _kitchens,
      numberOfFloors: _numberOfFloors,
      floorArea: floorArea,
      constructionYear: constructionYear,
      isFinished: _isFinished,
      amenities: _selectedAmenities.toList(),
      nearbyPlaces: Map<String, int>.from(_nearbyPlaces),
    );
    if (draft.title.isEmpty || draft.pricePerMonth <= 0) {
      _showSnack('Please complete title and price.');
      return;
    }
    if (!_hasLocationSelection) {
      _showSnack('Please choose a location.');
      return;
    }
    if (draft.imagePaths.length + draft.videoPaths.length < 1) {
      _showSnack('Please add at least 1 photo or video.');
      return;
    }

    setState(() => _publishing = true);
    final ok = await AddEstateRepository().publishEstate(draft);
    if (!mounted) return;
    setState(() {
      _publishing = false;
      _publishState =
          ok ? _AddEstatePublishState.success : _AddEstatePublishState.error;
    });
    if (ok) return;
  }

  Future<void> _retryPublish() async {
    if (_publishing) return;
    setState(() => _publishState = _AddEstatePublishState.none);
    await _publishEstate();
  }

  Future<void> _loadEditListing() async {
    final id = widget.estateId?.trim() ?? '';
    if (id.isEmpty) return;
    setState(() => _loadingEdit = true);
    try {
      final estateRepository = EstateRepository();
      final addEstateRepository = AddEstateRepository();
      final results = await Future.wait<dynamic>([
        estateRepository.getEstateById(id),
        addEstateRepository.getListingPlaces(id),
      ]);
      if (!mounted) return;
      final rawListing = results[0] as Map<String, dynamic>?;
      final listingPlaces = results[1] as List<Map<String, dynamic>>;
      if (rawListing != null) {
        final imagePaths = _extractImagePaths(rawListing);
        final videoPaths = _extractVideoPaths(rawListing);
        final imagePath = imagePaths.isNotEmpty ? imagePaths.first : '';
        final category = _extractListingCategory(rawListing);
        final sellPrice = _readDouble(rawListing['sell_price']);
        final rentPrice = _readDouble(rawListing['rent_price']);
        final title = _readString(rawListing['title'], fallback: 'Listing');
        final location = _readString(rawListing['address'], fallback: '');
        final lat = _readNullableDouble(rawListing['lat']);
        final lng = _readNullableDouble(rawListing['lng']);

        setState(() {
          _editingItem = EstateItem(
            id: _readString(rawListing['id'], fallback: id),
            title: title,
            location: location,
            price: sellPrice > 0 ? sellPrice : rentPrice,
            imageUrl: imagePath,
            category: category,
            lat: lat,
            lng: lng,
          );
          _titleController.text = title;
          _locationController.text = location;
          _mapAreaLabel = _toAreaLabel(location);
          _descriptionController.text =
              _readString(rawListing['description'], fallback: '');
          _category = category;
          if (lat != null && lng != null) {
            _selectedLatLng = LatLng(lat, lng);
            _mapCameraTarget = LatLng(lat, lng);
          }
          _listingType = sellPrice > 0 ? 'sell' : 'rent';
          _rentPeriod =
              _readString(rawListing['rent_type'], fallback: 'monthly')
                          .toLowerCase() ==
                      'yearly'
                  ? 'yearly'
                  : 'monthly';
          _sellPriceController.text =
              sellPrice > 0 ? sellPrice.round().toString() : '';
          _rentPriceController.text =
              rentPrice > 0 ? rentPrice.round().toString() : '';
          _imagePaths
            ..clear()
            ..addAll(imagePaths);
          _videoPaths
            ..clear()
            ..addAll(videoPaths);
          _applyListingFeatures(
            rawListing['listingFeatures'] ?? rawListing['listing_features'],
          );
          _applyListingFacilities(
            rawListing['listingFacilities'] ?? rawListing['listing_facilities'],
          );
          _applyNearbyPlaces(listingPlaces);
        });
        if (lat == null || lng == null) {
          final query = _locationController.text.trim();
          if (query.isNotEmpty) {
            final place = await GoogleGeocodingClient.geocodeAddress(query);
            if (mounted && place != null) {
              setState(() => _mapCameraTarget = place.location);
            }
          }
        } else if (_mapAreaLabel.isEmpty) {
          final address =
              await GoogleGeocodingClient.reverseGeocode(LatLng(lat, lng));
          if (mounted && address != null && address.trim().isNotEmpty) {
            setState(() => _mapAreaLabel = _toAreaLabel(address));
          }
        }
        unawaited(_animateMapToSelectedLocation());
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Could not load this listing.');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingEdit = false);
      }
    }
  }

  Future<void> _updateEstateListing() async {
    final estateId = widget.estateId?.trim() ?? '';
    if (estateId.isEmpty) return;
    if (!await _ensureResolvedLocation()) {
      return;
    }
    final sellPrice =
        double.tryParse(_sellPriceController.text.trim().replaceAll(',', '')) ??
            0;
    final rentPrice =
        double.tryParse(_rentPriceController.text.trim().replaceAll(',', '')) ??
            0;
    final floorArea = double.tryParse(_floorAreaController.text.trim());
    final constructionYear =
        int.tryParse(_constructionYearController.text.trim());
    final selectedPrice = _listingType == 'sell' ? sellPrice : rentPrice;
    final draft = EstateDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      pricePerMonth: selectedPrice,
      listingType: _listingType == 'rent' ? _rentPeriod : _listingType,
      category: _category,
      lat: _selectedLatLng?.latitude,
      lng: _selectedLatLng?.longitude,
      imagePaths: List<String>.from(_imagePaths),
      videoPaths: List<String>.from(_videoPaths),
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      livingRooms: _livingRooms,
      kitchens: _kitchens,
      numberOfFloors: _numberOfFloors,
      floorArea: floorArea,
      constructionYear: constructionYear,
      isFinished: _isFinished,
      amenities: _selectedAmenities.toList(),
      nearbyPlaces: Map<String, int>.from(_nearbyPlaces),
    );
    if (draft.title.isEmpty || selectedPrice <= 0) {
      _showSnack('Please complete title and price.');
      return;
    }
    if (!_hasLocationSelection) {
      _showSnack('Please choose a location.');
      return;
    }
    setState(() => _publishing = true);
    final ok = await AddEstateRepository().updateEstate(estateId, draft);
    if (!mounted) return;
    setState(() => _publishing = false);
    if (ok) {
      setState(() => _editSuccessVisible = true);
      return;
    }
    _showSnack('Could not update listing. Please try again.');
  }

  void _addMore() {
    setState(() {
      _publishState = _AddEstatePublishState.none;
      _step = 0;
      _publishing = false;
      _titleController.text = 'The Lodge House';
      _locationController.clear();
      _mapAreaLabel = _fallbackAreaLabel;
      _locationSuggestions = <String>[];
      _priceController.text = '180000';
      _descriptionController.clear();
      _floorAreaController.text = '1200';
      _constructionYearController.clear();
      _imagePaths.clear();
      _videoPaths.clear();
      _selectedLatLng = null;
      _mapCameraTarget = _initialLatLng;
      _listingType = 'rent';
      _rentPeriod = 'monthly';
      _category = 'House';
      _bedrooms = 3;
      _bathrooms = 2;
      _livingRooms = 2;
      _kitchens = 2;
      _numberOfFloors = 2;
      _isFinished = true;
      _selectedAmenities
        ..clear()
        ..addAll(<String>{'Balcony', 'Parking Spaces', 'Swimming Pool', 'Gym'});
      _nearbyPlaces
        ..clear()
        ..addAll(<String, int>{
          'Schools': 3,
          'Hospitals': 2,
          'Shopping Malls': 2,
          'Gas Stations': 2,
        });
    });
    unawaited(_setInitialLocationView());
  }

  List<String> _extractImagePaths(Map<String, dynamic> rawListing) {
    final images = rawListing['images'];
    if (images is! List) return const <String>[];
    return images
        .map((image) => '$image'.trim())
        .where((image) => image.isNotEmpty)
        .cast<String>()
        .toList();
  }

  List<String> _extractVideoPaths(Map<String, dynamic> rawListing) {
    final videos = rawListing['videos'];
    if (videos is! List) return const <String>[];
    return videos
        .map((video) => '$video'.trim())
        .where((video) => video.isNotEmpty)
        .cast<String>()
        .toList();
  }

  String _extractListingCategory(Map<String, dynamic> rawListing) {
    final propertyCategories =
        rawListing['propertyCategories'] ?? rawListing['property_categories'];
    if (propertyCategories is List) {
      for (final row in propertyCategories.whereType<Map<String, dynamic>>()) {
        final name = _readString(row['name_en'],
            fallback: _readString(row['name_so'], fallback: ''));
        if (name.isNotEmpty) return name;
      }
    }

    final listingTypes = rawListing['listingTypes'] ?? rawListing['listing_types'];
    if (listingTypes is List) {
      for (final row in listingTypes.whereType<Map<String, dynamic>>()) {
        final name = _readString(row['name_en'],
            fallback: _readString(row['name_so'], fallback: ''));
        if (_categoryOptions.contains(name)) return name;
      }
    }

    return _category;
  }

  void _applyListingFeatures(dynamic rawFeatures) {
    _bedrooms = 0;
    _bathrooms = 0;
    _livingRooms = 0;
    _kitchens = 0;
    _numberOfFloors = 0;
    _floorAreaController.clear();
    _constructionYearController.clear();
    _isFinished = true;

    if (rawFeatures is! List) return;
    for (final row in rawFeatures.whereType<Map<String, dynamic>>()) {
      final propertyFeature = row['propertyFeature'] ?? row['property_feature'];
      if (propertyFeature is! Map<String, dynamic>) continue;
      final name = _normalizeLabel(
        _readString(propertyFeature['name_en'],
            fallback: _readString(propertyFeature['name_so'], fallback: '')),
      );
      final value = _readString(row['value'], fallback: '');
      final numericValue = _readInt(row['value']);

      switch (name) {
        case 'bedroom':
        case 'bedrooms':
          _bedrooms = numericValue;
          break;
        case 'bathroom':
        case 'bathrooms':
          _bathrooms = numericValue;
          break;
        case 'living room':
        case 'living rooms':
          _livingRooms = numericValue;
          break;
        case 'kitchen':
        case 'kitchens':
          _kitchens = numericValue;
          break;
        case 'number of floors':
        case 'floors':
        case 'stories':
          _numberOfFloors = numericValue;
          break;
        case 'floor area':
        case 'area':
          _floorAreaController.text = value;
          break;
        case 'construction year':
        case 'year built':
          _constructionYearController.text =
              numericValue > 0 ? '$numericValue' : value;
          break;
        case 'finish state':
        case 'finished':
        case 'status':
          _isFinished = !_normalizeLabel(value).contains('unfinished');
          break;
      }
    }
  }

  void _applyListingFacilities(dynamic rawFacilities) {
    _selectedAmenities.clear();
    if (rawFacilities is! List) return;
    for (final row in rawFacilities.whereType<Map<String, dynamic>>()) {
      final facility =
          row['facility'] ?? row['listingFacility'] ?? row['listing_facility'];
      if (facility is! Map<String, dynamic>) continue;
      final name = _normalizeLabel(
        _readString(facility['name_en'],
            fallback: _readString(facility['name_so'], fallback: '')),
      );
      final label = switch (name) {
        'balcony' => 'Balcony',
        'parking' || 'parking space' || 'parking spaces' => 'Parking Spaces',
        'garden' => 'Garden',
        'swimming pool' => 'Swimming Pool',
        'gym' => 'Gym',
        'cctv' => 'CCTV',
        'elevator' => 'Elevator',
        'pet friendly' => 'Pet Friendly',
        _ => null,
      };
      if (label != null) {
        _selectedAmenities.add(label);
      }
    }
  }

  void _applyNearbyPlaces(List<Map<String, dynamic>> listingPlaces) {
    _nearbyPlaces
      ..clear()
      ..addAll(<String, int>{
        'Schools': 0,
        'Hospitals': 0,
        'Shopping Malls': 0,
        'Gas Stations': 0,
      });

    for (final row in listingPlaces) {
      final nearbyPlace = row['nearbyPlace'] ?? row['nearby_place'];
      if (nearbyPlace is! Map<String, dynamic>) continue;
      final name = _normalizeLabel(
        _readString(nearbyPlace['name_en'],
            fallback: _readString(nearbyPlace['name_so'], fallback: '')),
      );
      final label = switch (name) {
        'school' || 'schools' => 'Schools',
        'hospital' || 'hospitals' => 'Hospitals',
        'shopping mall' ||
        'shopping malls' ||
        'mall' ||
        'malls' =>
          'Shopping Malls',
        'gas station' || 'gas stations' => 'Gas Stations',
        _ => null,
      };
      if (label != null) {
        _nearbyPlaces[label] = _readInt(row['value']);
      }
    }
  }

  String _readString(dynamic value, {required String fallback}) {
    final text = '$value'.trim();
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  double? _readNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return (double.tryParse('$value') ?? 0).round();
  }

  String _normalizeLabel(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  int get _totalMediaCount => _imagePaths.length + _videoPaths.length;
  List<MediaGalleryItem> get _mediaItems => [
        for (final path in _imagePaths)
          MediaGalleryItem(source: path, isVideo: false),
        for (final path in _videoPaths)
          MediaGalleryItem(source: path, isVideo: true),
      ];

  Future<void> _showAddMediaOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add media',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.54,
                  ),
                ),
                const SizedBox(height: 16),
                _MediaOptionButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose Media',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickGalleryMedia();
                  },
                ),
                const SizedBox(height: 12),
                _MediaOptionButton(
                  icon: Icons.videocam_outlined,
                  label: 'Choose Videos',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickVideo();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openMediaViewer({required int initialIndex}) {
    final items = _mediaItems;
    if (items.isEmpty) return;
    showMediaGalleryViewer(
      context,
      items: items,
      initialIndex: initialIndex,
    );
  }

  Widget _buildMediaManager({String? sectionTitle}) {
    final items = _mediaItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sectionTitle != null) ...[
          _SectionTitle(sectionTitle),
          const SizedBox(height: 12),
        ],
        if (items.isEmpty)
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _AddMediaTile(
                    onTap: _showAddMediaOptions,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 159,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Add media',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.42,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 9,
            runSpacing: 10,
            children: [
              for (var index = 0; index < _imagePaths.length; index += 1)
                _MediaTile(
                  mediaPath: _imagePaths[index],
                  onOpen: () => _openMediaViewer(initialIndex: index),
                  onRemove: () => _removeImage(index),
                ),
              for (var index = 0; index < _videoPaths.length; index += 1)
                _MediaTile(
                  mediaPath: _videoPaths[index],
                  onOpen: () =>
                      _openMediaViewer(initialIndex: _imagePaths.length + index),
                  onRemove: () => _removeVideo(index),
                ),
              _AddMediaTile(
                onTap: _showAddMediaOptions,
              ),
            ],
          ),
        if (sectionTitle != null && items.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Unlimited photos and videos.',
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.greyMedium,
              letterSpacing: 0.36,
            ),
          ),
        ],
      ],
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle({
    required this.normalText,
    required this.accentText,
    this.trailingText = '',
  });

  final String normalText;
  final String accentText;
  final String trailingText;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: normalText,
            style: GoogleFonts.lato(
              fontSize: 25,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 40 / 25,
              letterSpacing: 0.75,
            ),
          ),
          TextSpan(
            text: accentText,
            style: GoogleFonts.lato(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              height: 40 / 25,
              letterSpacing: 0.75,
            ),
          ),
          if (trailingText.isNotEmpty)
            TextSpan(
              text: trailingText,
              style: GoogleFonts.lato(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 40 / 25,
                letterSpacing: 0.75,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.lato(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.54,
      ),
    );
  }
}

class _MapFloatingActionButton extends StatelessWidget {
  const _MapFloatingActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.controller,
    required this.hint,
    this.trailing,
    this.keyboardType,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.36,
              ),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                hintStyle: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.greyMedium,
                  letterSpacing: 0.36,
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _DescriptionBox extends StatelessWidget {
  const _DescriptionBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        style: GoogleFonts.lato(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.36,
        ),
        decoration: InputDecoration(
          hintText: 'Write Property Description',
          border: InputBorder.none,
          hintStyle: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.greyBarelyMedium,
            letterSpacing: 0.36,
          ),
        ),
      ),
    );
  }
}

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17.5),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryBackground : AppColors.greySoft1,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? Colors.white : AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterInput extends StatelessWidget {
  const _CounterInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.36,
              ),
            ),
          ),
          _SmallRoundButton(
            icon: Icons.remove_rounded,
            onTap: () => onChanged((value - 1).clamp(0, 999)),
          ),
          const SizedBox(width: 18),
          Text(
            '$value',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.48,
            ),
          ),
          const SizedBox(width: 18),
          _SmallRoundButton(
            icon: Icons.add_rounded,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : const Color(0xFFC0C2D3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: active
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.greyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.mediaPath,
    this.onOpen,
    this.onRemove,
  });

  final String mediaPath;
  final VoidCallback? onOpen;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isVideo = mediaPath.toLowerCase().endsWith('.mp4') ||
        mediaPath.toLowerCase().endsWith('.mov') ||
        mediaPath.toLowerCase().endsWith('.webm') ||
        mediaPath.toLowerCase().endsWith('.avi') ||
        mediaPath.toLowerCase().endsWith('.mkv') ||
        mediaPath.toLowerCase().endsWith('.m4v');
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: 159,
        height: 161,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.greySoft1, width: 3),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: onOpen,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: _ListingImage(imagePath: mediaPath),
                ),
              ),
            ),
            if (isVideo)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7FB239),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath?.trim() ?? '';
    if (path.isEmpty) {
      return Container(color: AppColors.greySoft2);
    }
    final isVideo = path.toLowerCase().endsWith('.mp4') ||
        path.toLowerCase().endsWith('.mov') ||
        path.toLowerCase().endsWith('.webm') ||
        path.toLowerCase().endsWith('.avi') ||
        path.toLowerCase().endsWith('.mkv') ||
        path.toLowerCase().endsWith('.m4v');
    return Stack(
      fit: StackFit.expand,
      children: [
        MediaThumbnail(
          item: MediaGalleryItem(source: path, isVideo: isVideo),
        ),
        if (isVideo)
          Container(
            color: Colors.black.withValues(alpha: 0.16),
            alignment: Alignment.center,
            child: const Icon(
              Icons.play_circle_fill_rounded,
              size: 42,
              color: Colors.white,
            ),
          ),
      ],
    );
  }
}

class _AddMediaTile extends StatelessWidget {
  const _AddMediaTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          width: 159,
          height: 161,
          decoration: BoxDecoration(
            color: AppColors.greySoft1,
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Center(
            child: Icon(
              Icons.add,
              size: 30,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaOptionButton extends StatelessWidget {
  const _MediaOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.greySoft1,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textPrimary),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.42,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditListingSuccessOverlay extends StatelessWidget {
  const _EditListingSuccessOverlay({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: const Color(0xB01F4C6B)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 44),
                const _ResultIcon(success: true),
                const SizedBox(height: 56),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Your listing just\n',
                        style: GoogleFonts.lato(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 40 / 25,
                          letterSpacing: 0.75,
                        ),
                      ),
                      TextSpan(
                        text: 'successfully updated',
                        style: GoogleFonts.lato(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          height: 40 / 25,
                          letterSpacing: 0.75,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Your changes have been saved.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.greyMedium,
                    height: 20 / 12,
                    letterSpacing: 0.36,
                  ),
                ),
                const SizedBox(height: 44),
                SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.48,
                      ),
                    ),
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

class _AddEstateResultOverlay extends StatelessWidget {
  const _AddEstateResultOverlay({
    required this.success,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
  });

  final bool success;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: const Color(0xB01F4C6B)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 44),
                _ResultIcon(success: success),
                const SizedBox(height: 70),
                Text.rich(
                  TextSpan(
                    children: success
                        ? [
                            TextSpan(
                              text: 'Your listing is now\n',
                              style: GoogleFonts.lato(
                                fontSize: 25,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                                height: 40 / 25,
                                letterSpacing: 0.75,
                              ),
                            ),
                            TextSpan(
                              text: 'published',
                              style: GoogleFonts.lato(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                                height: 40 / 25,
                                letterSpacing: 0.75,
                              ),
                            ),
                          ]
                        : [
                            TextSpan(
                              text: 'Aw snap, Something\n',
                              style: GoogleFonts.lato(
                                fontSize: 25,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                                height: 40 / 25,
                                letterSpacing: 0.75,
                              ),
                            ),
                            TextSpan(
                              text: 'error',
                              style: GoogleFonts.lato(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                                height: 40 / 25,
                                letterSpacing: 0.75,
                              ),
                            ),
                            TextSpan(
                              text: ' happened',
                              style: GoogleFonts.lato(
                                fontSize: 25,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                                height: 40 / 25,
                                letterSpacing: 0.75,
                              ),
                            ),
                          ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 52),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 70,
                        child: ElevatedButton(
                          onPressed: onSecondaryTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.greySoft1,
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text(
                            success ? 'Add More' : 'Close',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.48,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: SizedBox(
                        height: 70,
                        child: ElevatedButton(
                          onPressed: onPrimaryTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text(
                            success ? 'Finish' : 'Retry',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultIcon extends StatelessWidget {
  const _ResultIcon({required this.success});

  final bool success;

  @override
  Widget build(BuildContext context) {
    final fill = success ? AppColors.primary : AppColors.textSecondary;
    final glow = success ? const Color(0x55E7B904) : const Color(0x551F4C6B);
    final symbol = success ? '✓' : '!';
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glow,
            blurRadius: 40,
            spreadRadius: 12,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        symbol,
        style: GoogleFonts.montserrat(
          fontSize: 25,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.75,
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
    this.background = Colors.white,
    this.iconSize = 24,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x55E7B904),
                blurRadius: 40,
                offset: Offset(0, 17),
              ),
            ],
          ),
          child: Icon(icon, size: iconSize, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _SmallRoundButton extends StatelessWidget {
  const _SmallRoundButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFB0B4CF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _PrimaryWizardButton extends StatelessWidget {
  const _PrimaryWizardButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ),
    );
  }
}
