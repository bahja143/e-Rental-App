import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../explore/widgets/filter_modal.dart';
import '../data/models/estate_item.dart';
import '../data/repositories/estate_repository.dart';
import '../widgets/estate_card.dart';
import '../../../shared/widgets/remote_image.dart';

/// Location detail screen – Figma 1pH0qfybRFvvBbWUCcN5Lm (Hanti riyo – Copy) node 19-1791
class LocationDetailScreen extends StatefulWidget {
  const LocationDetailScreen({super.key, this.locationName = 'Mogadishu', this.rank});

  final String locationName;
  final int? rank;

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  final _repo = EstateRepository();
  late final Future<List<EstateItem>> _estatesFuture;
  Set<String> _savedIds = {};
  String _searchQuery = '';
  bool _isGrid = false; // Figma 19-1791: list view default
  bool _searchFocused = false;
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _estatesFuture = _repo.searchEstates(widget.locationName);
    _loadSavedIds();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() => _searchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSavedIds() async {
    final ids = await _repo.getSavedEstateIds();
    if (mounted) setState(() => _savedIds = ids);
  }

  Future<void> _toggleSaved(EstateItem e) async {
    if (e.id.isEmpty) return;
    final saved = _savedIds.contains(e.id);
    final ok = saved ? await _repo.removeSavedEstate(e.id) : await _repo.addSavedEstate(e.id);
    if (!mounted || !ok) return;
    setState(() {
      if (saved) _savedIds.remove(e.id);
      else _savedIds.add(e.id);
    });
  }

  List<EstateItem> _filter(List<EstateItem> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((e) => e.title.toLowerCase().contains(q) || e.location.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<EstateItem>>(
        future: _estatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final all = snapshot.data ?? [];
          final list = _filter(all);
          final img1 = all.isNotEmpty ? all[0].imageUrl : '';
          final img2 = all.length > 1 ? all[1].imageUrl : img1;
          final img3 = all.length > 2 ? all[2].imageUrl : img1;
          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroGallery(
                        img1: img1,
                        img2: img2,
                        img3: img3,
                        rank: widget.rank,
                        onBack: () => context.pop(),
                        onFilter: () => FilterModal.show(context),
                      ),
                      _TitleSection(locationName: widget.locationName),
                      _SearchBar(
                        hint: 'Modern House',
                        focusNode: _searchFocusNode,
                        focused: _searchFocused,
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                      _ListHeader(
                        count: list.length,
                        isGrid: _isGrid,
                        onGridTap: () => setState(() => _isGrid = true),
                        onListTap: () => setState(() => _isGrid = false),
                      ),
                      _FilterChips(onFilter: () => FilterModal.show(context)),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                  sliver: _isGrid
                      ? SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 7,
                            childAspectRatio: 0.63,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _EstateCard(
                              estate: list[i],
                              isSaved: _savedIds.contains(list[i].id),
                              onToggleSaved: () => _toggleSaved(list[i]),
                              onTap: () => context.push(AppRoutes.estateDetail(list[i].id)),
                              isGrid: true,
                            ),
                            childCount: list.length,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _EstateCard(
                                estate: list[i],
                                isSaved: _savedIds.contains(list[i].id),
                                onToggleSaved: () => _toggleSaved(list[i]),
                                onTap: () => context.push(AppRoutes.estateDetail(list[i].id)),
                                isGrid: false,
                              ),
                            ),
                            childCount: list.length,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Figma 19-1791: Hero gallery – asymmetric 3-image layout ─────────────────────

class _HeroGallery extends StatelessWidget {
  const _HeroGallery({
    required this.img1,
    required this.img2,
    required this.img3,
    this.rank,
    required this.onBack,
    required this.onFilter,
  });

  final String img1;
  final String img2;
  final String img3;
  final int? rank;
  final VoidCallback onBack;
  final VoidCallback onFilter;

  static const _borderWhite = BorderRadius.only(
    topLeft: Radius.circular(50),
    topRight: Radius.circular(25),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(25),
  );
  static const _rightTop = BorderRadius.only(
    topLeft: Radius.circular(25),
    topRight: Radius.circular(50),
    bottomLeft: Radius.circular(25),
    bottomRight: Radius.circular(25),
  );
  static const _rightBottom = BorderRadius.only(
    topLeft: Radius.circular(25),
    topRight: Radius.circular(25),
    bottomLeft: Radius.circular(25),
    bottomRight: Radius.circular(50),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: SizedBox(
        height: 330,
        child: Row(
          children: [
            Expanded(
              flex: 68,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: _borderWhite,
                      child: RemoteImage(
                        url: img1,
                        fit: BoxFit.cover,
                        errorWidget: Container(color: AppColors.greySoft1),
                      ),
                    ),
                  ),
                  Positioned(left: 24, top: 24, child: _CircleBtn(icon: Icons.arrow_back_ios_new, onTap: onBack)),
                  if (rank != null)
                    Positioned(
                      left: 24,
                      bottom: 24,
                      child: Container(
                        width: 53,
                        height: 53,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '#$rank',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
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
            const SizedBox(width: 10),
            Expanded(
              flex: 32,
              child: Column(
                children: [
                  Expanded(
                    flex: 22,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: _rightTop,
                            child: RemoteImage(
                              url: img2,
                              fit: BoxFit.cover,
                              errorWidget: Container(color: AppColors.greySoft1),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 26,
                          right: 0,
                          child: _CircleBtn(icon: Icons.tune_rounded, onTap: onFilter),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    flex: 12,
                    child: ClipRRect(
                      borderRadius: _rightBottom,
                      child: RemoteImage(
                        url: img3,
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
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

// ─── Figma 19-1799: Title section ──────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.locationName});

  final String locationName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locationName,
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
              'Our recommended real estates in $locationName',
              style: GoogleFonts.raleway(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.greyMedium,
                letterSpacing: 0.36,
                height: 20 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search bar ─────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.hint,
    required this.focusNode,
    required this.focused,
    required this.onChanged,
  });

  final String hint;
  final FocusNode focusNode;
  final bool focused;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(20),
        border: focused ? Border.all(color: AppColors.primary, width: 1.5) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: focusNode,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.raleway(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.36,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 22),
              ),
              style: GoogleFonts.raleway(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.36,
              ),
            ),
          ),
          const Icon(Icons.search, color: AppColors.textPrimary, size: 20),
        ],
      ),
    );
  }
}

// ─── Figma 19-1656: ItemHeaderTextView – Found X estates + view toggle ───────────

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.count,
    required this.isGrid,
    required this.onGridTap,
    required this.onListTap,
  });

  final int count;
  final bool isGrid;
  final VoidCallback onGridTap;
  final VoidCallback onListTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Found ',
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.54,
                  ),
                ),
                TextSpan(
                  text: '$count ',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.54,
                  ),
                ),
                TextSpan(
                  text: 'estates',
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.54,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.greySoft1,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ViewBtn(
                  icon: Icons.grid_view_rounded,
                  active: isGrid,
                  onTap: onGridTap,
                ),
                const SizedBox(width: 5),
                _ViewBtn(
                  icon: Icons.view_agenda_outlined,
                  active: !isGrid,
                  onTap: onListTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewBtn extends StatelessWidget {
  const _ViewBtn({required this.icon, required this.active, required this.onTap});

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Icon(
          icon,
          size: icon == Icons.grid_view_rounded ? 17 : 16,
          color: active ? AppColors.textPrimary : AppColors.greyBarelyMedium,
        ),
      ),
    );
  }
}

// ─── Figma 19-1795: Filter chips ─────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.onFilter});

  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Row(
        children: [
          _Chip(label: 'House', fontStyle: ChipFontStyle.raleway, onTap: onFilter),
          const SizedBox(width: 10),
          _Chip(label: r'$250 - $450', fontStyle: ChipFontStyle.montserrat, onTap: onFilter),
        ],
      ),
    );
  }
}

enum ChipFontStyle { raleway, montserrat }

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.fontStyle, required this.onTap});

  final String label;
  final ChipFontStyle fontStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE8C2),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(Icons.close, size: 10.8, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: fontStyle == ChipFontStyle.raleway
                  ? GoogleFonts.raleway(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    )
                  : GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Estate card wrapper (grid vs list) ──────────────────────────────────────────

class _EstateCard extends StatelessWidget {
  const _EstateCard({
    required this.estate,
    required this.isSaved,
    required this.onToggleSaved,
    required this.onTap,
    required this.isGrid,
  });

  final EstateItem estate;
  final bool isSaved;
  final VoidCallback onToggleSaved;
  final VoidCallback onTap;
  final bool isGrid;

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return EstateCard.vertical(
        title: estate.title,
        location: estate.location,
        price: estate.price,
        rating: estate.rating,
        imageUrl: estate.imageUrl,
        category: estate.displayCategory,
        isSaved: isSaved,
        onToggleSaved: onToggleSaved,
        onTap: onTap,
      );
    }
    return EstateCard.horizontal(
      title: estate.title,
      location: estate.location,
      price: estate.price,
      rating: estate.rating,
      imageUrl: estate.imageUrl,
      category: estate.displayCategory,
      isSaved: isSaved,
      onToggleSaved: onToggleSaved,
      onTap: onTap,
      fullWidth: true,
    );
  }
}
