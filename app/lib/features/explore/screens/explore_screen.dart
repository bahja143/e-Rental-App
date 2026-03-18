import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/filter_modal.dart';
import '../../home/data/models/estate_item.dart';
import '../../home/data/repositories/estate_repository.dart';
import '../../home/widgets/estate_card.dart';

/// Featured Estates list screen - matches Figma node 19-1858
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _repo = EstateRepository();
  late final Future<List<EstateItem>> _estatesFuture;
  Set<String> _savedIds = <String>{};
  String _searchQuery = '';
  bool _isGrid = true;
  bool _searchFocused = false;
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _estatesFuture = _loadEstates();
    _loadSavedIds();
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  void _onSearchFocusChange() {
    if (mounted) setState(() => _searchFocused = _searchFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<List<EstateItem>> _loadEstates() async {
    final featured = await _repo.getFeaturedEstates();
    final nearby = await _repo.getNearbyEstates();
    final seen = <String>{};
    final combined = <EstateItem>[];
    for (final e in featured) {
      if (!seen.contains(e.id)) {
        seen.add(e.id);
        combined.add(e);
      }
    }
    for (final e in nearby) {
      if (!seen.contains(e.id)) {
        seen.add(e.id);
        combined.add(e);
      }
    }
    return combined;
  }

  Future<void> _loadSavedIds() async {
    final ids = await _repo.getSavedEstateIds();
    if (mounted) setState(() => _savedIds = ids);
  }

  Future<void> _toggleSaved(EstateItem estate) async {
    if (estate.id.isEmpty) return;
    final isSaved = _savedIds.contains(estate.id);
    final ok = isSaved
        ? await _repo.removeSavedEstate(estate.id)
        : await _repo.addSavedEstate(estate.id);
    if (!mounted || !ok) return;
    setState(() {
      if (isSaved) {
        _savedIds.remove(estate.id);
      } else {
        _savedIds.add(estate.id);
      }
    });
  }

  List<EstateItem> _filterEstates(List<EstateItem> estates) {
    if (_searchQuery.trim().isEmpty) return estates;
    final q = _searchQuery.toLowerCase();
    return estates
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.location.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<EstateItem>>(
        future: _estatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final allEstates = snapshot.data ?? [];
          final estates = _filterEstates(allEstates);
          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      _buildHeroImages(),
                      _buildTitle(context),
                      _buildSearchBar(context),
                      _buildListHeader(context, estates.length),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                  sliver: _isGrid
                      ? SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 7,
                            childAspectRatio: 0.63,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
                              final e = estates[i];
                              return EstateCard.vertical(
                                title: e.title,
                                location: e.location,
                                price: e.price,
                                rating: e.rating,
                                imageUrl: e.imageUrl,
                                category: e.displayCategory,
                                isSaved: _savedIds.contains(e.id),
                                onToggleSaved: () => _toggleSaved(e),
                                onTap: () =>
                                    context.push(AppRoutes.estateDetail(e.id)),
                              );
                            },
                            childCount: estates.length,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
                              final e = estates[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: EstateCard.horizontal(
                                  title: e.title,
                                  location: e.location,
                                  price: e.price,
                                  rating: e.rating,
                                  imageUrl: e.imageUrl,
                                  category: e.displayCategory,
                                  isSaved: _savedIds.contains(e.id),
                                  onToggleSaved: () => _toggleSaved(e),
                                  onTap: () =>
                                      context.push(AppRoutes.estateDetail(e.id)),
                                ),
                              );
                            },
                            childCount: estates.length,
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 21, 24, 0),
      child: Row(
        children: [
          _TransparentButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => context.pop(),
          ),
          const Spacer(),
          _TransparentButton(
            onTap: () => FilterModal.show(context),
            child: const _FilterIcon(),
          ),
        ],
      ),
    );
  }

  static const _featuredImages = [
    'assets/images/featured/featured_1.png',
    'assets/images/featured/featured_2.png',
    'assets/images/featured/featured_3.png',
  ];

  /// Image gallery - Figma node 19-1871, 19-1872, 19-1873
  /// Left: 220×224, right top: 133×137, right bottom: 131×125, gap 6px H, 4px V, radius 12
  Widget _buildHeroImages() {
    const figmaWidth = 359.0;
    const leftW = 220.0;
    const gapH = 6.0;
    const rightW = 133.0;
    const leftH = 224.0;
    const topH = 137.0;
    const gapV = 4.0;
    const bottomH = 125.0;
    const totalH = topH + gapV + bottomH;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableW = constraints.maxWidth;
          final scale = availableW / figmaWidth;
          return SizedBox(
            height: totalH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: leftW * scale,
                    height: leftH,
                    child: Image.asset(
                      _featuredImages[0],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: gapH * scale),
                SizedBox(
                  width: rightW * scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: rightW * scale,
                          height: topH,
                          child: Image.asset(
                            _featuredImages[1],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: gapV),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: (rightW - 2) * scale,
                          height: bottomH,
                          child: Image.asset(
                            _featuredImages[2],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Estates',
            style: GoogleFonts.lato(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.75,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Our recommended real estates exclusive for you.',
            style: GoogleFonts.raleway(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              letterSpacing: 0.36,
              height: 20 / 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(20),
        border: _searchFocused
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.greyBarelyMedium, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              focusNode: _searchFocusNode,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search in featured estate',
                hintStyle: GoogleFonts.raleway(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.inputPlaceholder,
                  letterSpacing: 0.36,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 22),
              ),
              style: GoogleFonts.raleway(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildListHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.54,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'estates',
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.54,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.greySoft1,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ViewToggleBtn(
                      icon: _ViewIcon.grid,
                      isActive: _isGrid,
                      onTap: () => setState(() => _isGrid = true),
                    ),
                    const SizedBox(width: 5),
                    _ViewToggleBtn(
                      icon: _ViewIcon.list,
                      isActive: !_isGrid,
                      onTap: () => setState(() => _isGrid = false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransparentButton extends StatelessWidget {
  const _TransparentButton({
    this.icon,
    this.child,
    required this.onTap,
  }) : assert(icon != null || child != null);

  final IconData? icon;
  final Widget? child;
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
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: child != null
                  ? child
                  : Icon(
                      icon!,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma: Icon / Setting node 19:1711 - filter/sliders icon (3 lines, dots: right, center, left)
class _FilterIcon extends StatelessWidget {
  const _FilterIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _FilterIconPainter(color: AppColors.textPrimary),
      ),
    );
  }
}

class _FilterIconPainter extends CustomPainter {
  _FilterIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final dotR = 1.8;
    final lineY1 = size.height * 0.28;
    final lineY2 = size.height * 0.5;
    final lineY3 = size.height * 0.72;
    final w = size.width;

    canvas.drawLine(Offset(0, lineY1), Offset(w, lineY1), linePaint);
    canvas.drawLine(Offset(0, lineY2), Offset(w, lineY2), linePaint);
    canvas.drawLine(Offset(0, lineY3), Offset(w, lineY3), linePaint);

    canvas.drawCircle(Offset(w * 0.78, lineY1), dotR, dotPaint);
    canvas.drawCircle(Offset(w * 0.5, lineY2), dotR, dotPaint);
    canvas.drawCircle(Offset(w * 0.22, lineY3), dotR, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is _FilterIconPainter && oldDelegate.color != color;
}

/// Figma: Icon / Vertical (grid) node 19:1580, Icon / Horizontal (list) node 314:1716
enum _ViewIcon { grid, list }

class _ViewToggleBtn extends StatelessWidget {
  const _ViewToggleBtn({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final _ViewIcon icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: _buildIcon(),
      ),
    );
  }

  Widget _buildIcon() {
    const size = 12.0;
    final activeColor = AppColors.textPrimary;
    final inactiveColor = AppColors.greyBarelyMedium.withOpacity(0.5);
    final color = isActive ? activeColor : inactiveColor;

    if (icon == _ViewIcon.grid) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _GridIconPainter(color: color),
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ListIconPainter(
          centerColor: isActive ? activeColor : inactiveColor,
          lineColor: isActive ? AppColors.greyBarelyMedium : inactiveColor,
        ),
      ),
    );
  }
}

class _GridIconPainter extends CustomPainter {
  _GridIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const gap = 1.0;
    final cellW = (size.width - gap) / 2;
    final cellH = (size.height - gap) / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, cellW, cellH),
      const Radius.circular(2),
    );
    canvas.drawRRect(rrect, paint);
    canvas.save();
    canvas.translate(cellW + gap, 0);
    canvas.drawRRect(rrect, paint);
    canvas.restore();
    canvas.save();
    canvas.translate(0, cellH + gap);
    canvas.drawRRect(rrect, paint);
    canvas.restore();
    canvas.save();
    canvas.translate(cellW + gap, cellH + gap);
    canvas.drawRRect(rrect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is _GridIconPainter && oldDelegate.color != color;
}

class _ListIconPainter extends CustomPainter {
  _ListIconPainter({required this.centerColor, required this.lineColor});
  final Color centerColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerPaint = Paint()..color = centerColor;
    final linePaint = Paint()..color = lineColor;
    final centerTop = h * 0.2778;
    final centerBottom = h * 0.7222;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, centerTop, w, centerBottom),
        const Radius.circular(2),
      ),
      centerPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, h * 0.0556, w, h * 0.2222),
        const Radius.circular(2),
      ),
      linePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, h * 0.7778, w, h * 0.9444),
        const Radius.circular(2),
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! _ListIconPainter) return true;
    return oldDelegate.centerColor != centerColor ||
        oldDelegate.lineColor != lineColor;
  }
}
