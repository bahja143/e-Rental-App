import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/maps/google_geocoding_client.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/remote_image.dart';
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
  static const _initialLatLng = LatLng(-6.9175, 107.6191);
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

  final _titleController = TextEditingController(text: 'The Lodge House');
  final _locationController = TextEditingController(
    text: 'Jl. Cisangkuy, Citarum, Kec. Bandung Wetan, Kota Bandung, Jawa Barat 40115',
  );
  final _priceController = TextEditingController(text: '180000');
  final _sellPriceController = TextEditingController(text: '180000');
  final _rentPriceController = TextEditingController(text: '320');
  final _descriptionController = TextEditingController();
  final _floorAreaController = TextEditingController(text: '1200');
  final _constructionYearController = TextEditingController();

  String _listingType = 'rent';
  String _rentPeriod = 'monthly';
  String _category = 'House';
  LatLng _selectedLatLng = _initialLatLng;
  final List<String> _imagePaths = <String>[];
  int _bedrooms = 3;
  int _bathrooms = 2;
  int _livingRooms = 2;
  int _kitchens = 2;
  int _numberOfFloors = 2;
  bool _isFinished = true;
  final Set<String> _selectedAmenities = <String>{'Balcony', 'Parking Spaces', 'Swimming Pool', 'Gym'};
  final Map<String, int> _nearbyPlaces = <String, int>{
    'Schools': 3,
    'Hospitals': 2,
    'Shopping Malls': 2,
    'Gas Stations': 2,
  };
  EstateItem? _editingItem;

  bool get _isEditMode => (widget.estateId ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadEditListing();
    }
  }

  @override
  void dispose() {
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
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 8),
                _AddEstateHeader(onBack: _handleBack),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
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
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).padding.bottom),
                  child: _isEditMode
                      ? _PrimaryWizardButton(
                          label: _publishing ? 'Updating...' : 'Update',
                          onTap: _publishing ? null : _updateEstateListing,
                        )
                      : Row(
                          children: [
                            _CircleActionButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: _handleBack,
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: _PrimaryWizardButton(
                                label: _step == 3 ? (_publishing ? 'Publishing...' : 'Finish') : 'Next',
                                onTap: _publishing ? null : _handleNext,
                              ),
                            ),
                          ],
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
                  onSecondaryTap: _publishState == _AddEstatePublishState.success
                      ? _addMore
                      : () => setState(() => _publishState = _AddEstatePublishState.none),
                ),
              ),
          ],
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
          trailing: const Icon(Icons.home_outlined, color: AppColors.textPrimary),
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
          trailing: const Icon(Icons.home_outlined, color: AppColors.textPrimary),
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
          hint: 'Search address',
          trailing: _lookingUpAddress
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : IconButton(
                  onPressed: _searchAddress,
                  icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
                ),
        ),
        const SizedBox(height: 12),
        _buildMapCard(height: 200),
        const SizedBox(height: 24),
        _SectionTitle('Listing Photos'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 159 / 161,
          ),
          itemBuilder: (context, index) {
            final hasImage = index < _imagePaths.length;
            return _PhotoTile(
              imagePath: hasImage ? _imagePaths[index] : null,
              onTap: () => _pickImage(index),
              onRemove: hasImage ? () => _removeImage(index) : null,
            );
          },
        ),
        const SizedBox(height: 24),
        _SectionTitle('Sell Price'),
        const SizedBox(height: 12),
        _InputCard(
          controller: _sellPriceController,
          hint: '\$ 150,000',
          keyboardType: TextInputType.number,
          trailing: const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.attach_money_rounded, color: AppColors.textPrimary, size: 18),
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
            child: Icon(Icons.attach_money_rounded, color: AppColors.textPrimary, size: 18),
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
            onChanged: (value) => setState(() => _nearbyPlaces[entry.key] = value),
          ),
          const SizedBox(height: 15),
        ],
      ],
    );
  }

  Widget _buildEditPreviewCard() {
    final item = _editingItem;
    final imagePath = _imagePaths.isNotEmpty
        ? _imagePaths.first
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
              child: _ListingImage(imagePath: imagePath),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleController.text.trim().isEmpty ? 'Listing' : _titleController.text.trim(),
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
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 9, color: AppColors.primary),
                    const SizedBox(width: 2),
                    Text(
                      ((item?.rating) ?? 4.6).toStringAsFixed(1),
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 9, color: AppColors.greyMedium),
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
          child: const Icon(Icons.location_on_outlined, color: AppColors.greyMedium),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            _locationController.text.trim().isEmpty ? 'Tap the map or search an address.' : _locationController.text.trim(),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _selectedLatLng, zoom: 14),
              onTap: _selectMapLocation,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('estate'),
                  position: _selectedLatLng,
                  draggable: true,
                  onDragEnd: _selectMapLocation,
                ),
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 50,
                    color: Colors.white.withValues(alpha: 0.5),
                    alignment: Alignment.center,
                    child: Text(
                      'Select on the map',
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
              child: const Icon(Icons.location_on_outlined, color: AppColors.greyMedium),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _locationController.text.trim().isEmpty ? 'Tap the map or search an address.' : _locationController.text.trim(),
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
          hint: 'Search address',
          trailing: _lookingUpAddress
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : IconButton(
                  onPressed: _searchAddress,
                  icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
                ),
        ),
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
        const SizedBox(height: 34),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 159 / 161,
          ),
          itemBuilder: (context, index) {
            final hasImage = index < _imagePaths.length;
            return _PhotoTile(
              imagePath: hasImage ? _imagePaths[index] : null,
              onTap: () => _pickImage(index),
              onRemove: hasImage ? () => _removeImage(index) : null,
            );
          },
        ),
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
            child: Icon(Icons.attach_money_rounded, color: AppColors.textPrimary, size: 18),
          ),
        ),
        if (_listingType == 'rent') ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: const [
              _StaticChoiceChip(label: 'Monthly', active: true),
              _StaticChoiceChip(label: 'Yearly'),
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
            onChanged: (value) => setState(() => _nearbyPlaces[entry.key] = value),
          ),
          const SizedBox(height: 15),
        ],
      ],
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
      context.pop();
      return;
    }
    if (_step == 0) {
      context.pop();
      return;
    }
    setState(() => _step -= 1);
  }

  Future<void> _handleNext() async {
    switch (_step) {
      case 0:
        if (_titleController.text.trim().isEmpty) {
          _showSnack('Please enter a listing title.');
          return;
        }
        setState(() => _step = 1);
        return;
      case 1:
        if (_locationController.text.trim().isEmpty) {
          _showSnack('Please select a location.');
          return;
        }
        setState(() => _step = 2);
        return;
      case 2:
        if (_imagePaths.length < 3) {
          _showSnack('Please add at least 3 photos.');
          return;
        }
        setState(() => _step = 3);
        return;
      default:
        await _publishEstate();
    }
  }

  Future<void> _searchAddress() async {
    final query = _locationController.text.trim();
    if (query.isEmpty) return;
    setState(() => _lookingUpAddress = true);
    final place = await GoogleGeocodingClient.geocodeAddress(query);
    if (!mounted) return;
    setState(() => _lookingUpAddress = false);
    if (place == null) {
      _showSnack('Could not find that address.');
      return;
    }
    setState(() {
      _selectedLatLng = place.location;
      _locationController.text = place.formattedAddress;
    });
  }

  Future<void> _selectMapLocation(LatLng position) async {
    setState(() {
      _selectedLatLng = position;
      _lookingUpAddress = true;
    });
    final address = await GoogleGeocodingClient.reverseGeocode(position);
    if (!mounted) return;
    setState(() {
      _lookingUpAddress = false;
      if (address != null && address.trim().isNotEmpty) {
        _locationController.text = address.trim();
      }
    });
  }

  Future<void> _pickImage(int index) async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() {
      if (index < _imagePaths.length) {
        _imagePaths[index] = image.path;
      } else {
        _imagePaths.add(image.path);
      }
    });
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  Future<void> _publishEstate() async {
    final price = double.tryParse(_priceController.text.trim().replaceAll(',', '')) ?? 0;
    final floorArea = double.tryParse(_floorAreaController.text.trim());
    final constructionYear = int.tryParse(_constructionYearController.text.trim());
    final draft = EstateDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      pricePerMonth: price,
      listingType: _listingType,
      category: _category,
      lat: _selectedLatLng.latitude,
      lng: _selectedLatLng.longitude,
      imagePaths: List<String>.from(_imagePaths),
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
    if (draft.title.isEmpty || draft.location.isEmpty || draft.pricePerMonth <= 0) {
      _showSnack('Please complete title, location, and price.');
      return;
    }
    if (draft.imagePaths.length < 3) {
      _showSnack('Please add at least 3 photos.');
      return;
    }

    setState(() => _publishing = true);
    final ok = await AddEstateRepository().publishEstate(draft);
    if (!mounted) return;
    setState(() {
      _publishing = false;
      _publishState = ok ? _AddEstatePublishState.success : _AddEstatePublishState.error;
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
    final item = await EstateRepository().getEstateItemById(id);
    if (!mounted) return;
    if (item != null) {
      _editingItem = item;
      _titleController.text = item.title;
      _locationController.text = item.location;
      _category = item.displayCategory ?? _category;
      _selectedLatLng = item.hasCoordinates ? LatLng(item.lat!, item.lng!) : _selectedLatLng;
      _sellPriceController.text = item.price.toInt().toString();
      _rentPriceController.text = item.price.toInt().toString();
      _imagePaths
        ..clear()
        ..add(item.imageUrl);
    }
    setState(() => _loadingEdit = false);
  }

  Future<void> _updateEstateListing() async {
    final estateId = widget.estateId?.trim() ?? '';
    if (estateId.isEmpty) return;
    final sellPrice = double.tryParse(_sellPriceController.text.trim().replaceAll(',', '')) ?? 0;
    final rentPrice = double.tryParse(_rentPriceController.text.trim().replaceAll(',', '')) ?? 0;
    final floorArea = double.tryParse(_floorAreaController.text.trim());
    final constructionYear = int.tryParse(_constructionYearController.text.trim());
    final selectedPrice = _listingType == 'sell' ? sellPrice : rentPrice;
    final draft = EstateDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      pricePerMonth: selectedPrice,
      listingType: _listingType == 'rent' ? _rentPeriod : _listingType,
      category: _category,
      lat: _selectedLatLng.latitude,
      lng: _selectedLatLng.longitude,
      imagePaths: List<String>.from(_imagePaths),
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
    if (draft.title.isEmpty || draft.location.isEmpty || selectedPrice <= 0) {
      _showSnack('Please complete title, location, and price.');
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
      _locationController.text = 'Jl. Cisangkuy, Citarum, Kec. Bandung Wetan, Kota Bandung, Jawa Barat 40115';
      _priceController.text = '180000';
      _descriptionController.clear();
      _floorAreaController.text = '1200';
      _constructionYearController.clear();
      _imagePaths.clear();
      _selectedLatLng = _initialLatLng;
      _listingType = 'rent';
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
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AddEstateHeader extends StatelessWidget {
  const _AddEstateHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Add Listing',
            style: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Positioned(
            left: 24,
            child: _CircleActionButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack,
              background: AppColors.greySoft1,
              iconSize: 18,
            ),
          ),
        ],
      ),
    );
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

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.controller,
    required this.hint,
    this.trailing,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final Widget? trailing;
  final TextInputType? keyboardType;

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
              keyboardType: keyboardType,
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

class _StaticChoiceChip extends StatelessWidget {
  const _StaticChoiceChip({
    required this.label,
    this.active = false,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryBackground : AppColors.greySoft1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
          fontSize: 10,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? Colors.white : AppColors.greyMedium,
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
            child: active ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
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

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.imagePath,
    required this.onTap,
    this.onRemove,
  });

  final String? imagePath;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.greySoft1,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: hasImage
                      ? _ListingImage(imagePath: imagePath)
                      : Center(
                          child: Icon(
                            Icons.add_rounded,
                            size: 36,
                            color: AppColors.textPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                ),
              ),
              if (hasImage)
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
                      child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
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
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return RemoteImage(
        url: path,
        fit: BoxFit.cover,
        errorWidget: Container(color: AppColors.greySoft2),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: AppColors.greySoft2),
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
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
