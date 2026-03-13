import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/estate_item.dart';
import '../data/repositories/estate_repository.dart';
import '../../../shared/widgets/remote_image.dart';

class LocationDetailScreen extends StatefulWidget {
  const LocationDetailScreen({super.key, this.locationName = 'Mogadishu'});

  final String locationName;

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  final _repo = EstateRepository();
  late final Future<List<EstateItem>> _estatesFuture;
  Set<String> _savedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _estatesFuture = _load();
    _loadSavedIds();
  }

  Future<List<EstateItem>> _load() async {
    final list = await _repo.searchEstates(widget.locationName);
    return list;
  }

  Future<void> _loadSavedIds() async {
    final ids = await _repo.getSavedEstateIds();
    if (!mounted) return;
    setState(() => _savedIds = ids);
  }

  Future<void> _toggleSaved(String listingId) async {
    if (listingId.isEmpty) return;
    final isSaved = _savedIds.contains(listingId);
    final ok = isSaved ? await _repo.removeSavedEstate(listingId) : await _repo.addSavedEstate(listingId);
    if (!mounted || !ok) return;
    setState(() {
      if (isSaved) {
        _savedIds.remove(listingId);
      } else {
        _savedIds.add(listingId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return FutureBuilder<List<EstateItem>>(
      future: _estatesFuture,
      builder: (context, snapshot) {
        final estates = snapshot.data ?? const <EstateItem>[];
        final primary = estates.isNotEmpty ? estates.first : null;
        final second = estates.length > 1 ? estates[1] : primary;
        final third = estates.length > 2 ? estates[2] : primary;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 325,
                child: Row(
                  children: [
                    Expanded(
                      flex: 68,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: RemoteImage(
                                url: primary?.imageUrl ?? 'https://www.figma.com/api/mcp/asset/077f5a9e-4cc0-4723-94ea-214604b0e5ba',
                                fit: BoxFit.cover,
                                errorWidget: Container(color: AppColors.greySoft1),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 14,
                            top: 14,
                            child: _circleButton(Icons.arrow_back_ios_new, onTap: context.pop),
                          ),
                          Positioned(
                            left: 14,
                            bottom: 14,
                            child: Container(
                              width: 53,
                              height: 53,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7B904),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '#3',
                                style: text.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 32,
                      child: Column(
                        children: [
                          Expanded(
                            flex: 65,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: RemoteImage(
                                      url: second?.imageUrl ?? 'https://www.figma.com/api/mcp/asset/8bcbc523-1adc-4ae2-ae9b-43ebf0b16662',
                                      fit: BoxFit.cover,
                                      errorWidget: Container(color: AppColors.greySoft1),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 14,
                                  right: 14,
                                  child: _circleButton(Icons.tune_rounded, onTap: () {}),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            flex: 35,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: RemoteImage(
                                url: third?.imageUrl ?? 'https://www.figma.com/api/mcp/asset/68972832-a0a8-46ff-a2e5-99cff01b00ff',
                                fit: BoxFit.cover,
                                errorWidget: Container(color: AppColors.greySoft1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.locationName,
                style: text.headlineMedium?.copyWith(
                  fontSize: 46,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Our recommended real estates in ${widget.locationName}',
                style: text.bodyMedium?.copyWith(color: AppColors.greyMedium, fontSize: 20),
              ),
              const SizedBox(height: 20),
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(color: AppColors.greySoft1, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Modern House',
                        style: text.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.search_rounded, color: AppColors.textPrimary),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Found ',
                          style: text.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: '${estates.length} ',
                          style: text.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text: 'estates',
                          style: text.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppColors.greySoft1, borderRadius: BorderRadius.circular(22)),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 30,
                          height: 30,
                          child: Icon(Icons.grid_view_rounded, color: AppColors.greyBarelyMedium, size: 17),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.view_agenda_outlined, color: AppColors.textPrimary, size: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  _FilterChip(label: 'House'),
                  SizedBox(width: 10),
                  _FilterChip(label: r'$250 - $450'),
                ],
              ),
              const SizedBox(height: 20),
              _HorizontalEstateCard(
                imageUrl: primary?.imageUrl ?? 'https://www.figma.com/api/mcp/asset/287cbe40-257d-4858-9e2e-9a8c01de893a',
                title: primary?.title ?? 'Flower Heaven House',
                price: '\$ ${(primary?.price ?? 370).toInt()}',
                location: primary?.location ?? widget.locationName,
                rating: primary?.rating ?? 4.7,
                isSaved: _savedIds.contains(primary?.id ?? ''),
                onToggleSaved: () => _toggleSaved(primary?.id ?? ''),
                onTap: () => context.push(AppRoutes.estateDetail(primary?.id ?? '1')),
              ),
            ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _circleButton(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Ink(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: const Color(0xFFEDE8C2), borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(color: Color(0xFFE7B904), shape: BoxShape.circle),
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: text.bodySmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HorizontalEstateCard extends StatelessWidget {
  const _HorizontalEstateCard({
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.location,
    required this.rating,
    required this.isSaved,
    required this.onToggleSaved,
    required this.onTap,
  });

  final String imageUrl;
  final String title;
  final String price;
  final String location;
  final double rating;
  final bool isSaved;
  final VoidCallback onToggleSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.greySoft1, borderRadius: BorderRadius.circular(25)),
        child: Row(
          children: [
            SizedBox(
              width: 168,
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RemoteImage(
                        url: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: Container(color: AppColors.greySoft2),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xAA234F68),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'House',
                          style: text.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: GestureDetector(
                        onTap: onToggleSaved,
                        child: Container(
                          width: 25,
                          height: 25,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(
                            isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFC42D), size: 12),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1), style: text.bodySmall?.copyWith(color: AppColors.greyMedium, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.greyMedium, size: 11),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            location,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(color: AppColors.greyMedium, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: text.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                        Text('/month', style: text.bodySmall?.copyWith(color: AppColors.greyMedium, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
