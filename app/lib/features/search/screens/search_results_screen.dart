import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/figma_tokens.dart';
import '../../explore/widgets/filter_modal.dart';
import '../../home/data/models/estate_item.dart';
import '../../home/data/repositories/estate_repository.dart';
import '../../home/widgets/estate_card.dart';

/// Figma `24:3566` — Search / Result (with listings).
/// Figma `24:3583` — Search / Empty (no listings).
/// Figma `24:3484` — Search / Result - Filter (active chips + list layout + filter button active).
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, this.initialQuery});

  /// Optional query from route `?q=`.
  final String? initialQuery;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final _repo = EstateRepository();
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  List<EstateItem> _listings = [];
  Set<String> _savedIds = {};
  bool _loading = true;
  bool _gridView = true;

  /// Applied filters (Figma 24:3484). Empty = defaults / no filter API.
  String _filterPropertyType = 'All';
  bool _filterPreferRent = true;
  String? _filterPriceMin;
  String? _filterPriceMax;
  String? _filterAreaMin;
  String? _filterAreaMax;

  /// `true` = force empty UI (Figma 24:3583). Run:
  /// `flutter run --dart-define=SEARCH_RESULTS_SIMULATE_EMPTY=true`
  static const _simulateEmpty =
      bool.fromEnvironment('SEARCH_RESULTS_SIMULATE_EMPTY', defaultValue: false);

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery?.trim() ?? '';
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _filterPropertyType != 'All' ||
      (_filterPriceMin != null && _filterPriceMin!.trim().isNotEmpty) ||
      (_filterPriceMax != null && _filterPriceMax!.trim().isNotEmpty) ||
      (_filterAreaMin != null && _filterAreaMin!.trim().isNotEmpty) ||
      (_filterAreaMax != null && _filterAreaMax!.trim().isNotEmpty) ||
      !_filterPreferRent;

  Future<void> _openFilterModal() async {
    await FilterModal.show(
      context,
      initialPropertyType: _filterPropertyType,
      initialPreferRent: _filterPreferRent,
      initialPriceMin: _filterPriceMin,
      initialPriceMax: _filterPriceMax,
      initialAreaMin: _filterAreaMin,
      initialAreaMax: _filterAreaMax,
      onApply: ({
        String propertyType = 'All',
        bool preferRent = true,
        String? priceMin,
        String? priceMax,
        String? areaMin,
        String? areaMax,
      }) {
        if (!mounted) return;
        setState(() {
          _filterPropertyType = propertyType;
          _filterPreferRent = preferRent;
          _filterPriceMin = priceMin;
          _filterPriceMax = priceMax;
          _filterAreaMin = areaMin;
          _filterAreaMax = areaMax;
          // Figma 24:3484: filtered results as horizontal list cards.
          _gridView = false;
        });
        _load();
      },
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final q = _searchController.text.trim();
    List<EstateItem> list;
    if (_simulateEmpty) {
      list = [];
    } else if (_hasActiveFilters || q.isNotEmpty) {
      list = await _repo.queryPublicListings(
        search: q.isEmpty ? null : q,
        limit: 40,
        preferRent: _filterPreferRent,
        propertyType: _filterPropertyType,
        rentPriceMin: _filterPreferRent ? _filterPriceMin : null,
        rentPriceMax: _filterPreferRent ? _filterPriceMax : null,
        sellPriceMin: !_filterPreferRent ? _filterPriceMin : null,
        sellPriceMax: !_filterPreferRent ? _filterPriceMax : null,
      );
    } else if (q.isEmpty) {
      list = await _repo.getNearbyEstates();
    } else {
      list = await _repo.searchEstates(q);
    }
    final saved = await _repo.getSavedEstateIds();
    if (!mounted) return;
    setState(() {
      _listings = list;
      _savedIds = saved.toSet();
      _loading = false;
      if (_hasActiveFilters) {
        _gridView = false;
      } else {
        _gridView = list.isNotEmpty;
      }
    });
  }

  Future<void> _toggleSaved(EstateItem e) async {
    if (e.id.isEmpty) return;
    final saved = _savedIds.contains(e.id);
    final ok = saved ? await _repo.removeSavedEstate(e.id) : await _repo.addSavedEstate(e.id);
    if (!mounted || !ok) return;
    setState(() {
      if (saved) {
        _savedIds.remove(e.id);
      } else {
        _savedIds.add(e.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pinned: status bar + app header (Figma 24:3591) — does not scroll.
          SizedBox(height: top),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: _buildHeader(context),
          ),
          // Scrollable: search, "Found" row, and results / empty / loading.
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSearchField(context),
                              const SizedBox(height: 20),
                              _buildFoundRow(context),
                              if (_hasActiveFilters) ...[
                                const SizedBox(height: 16),
                                _buildAppliedFilterChips(context),
                              ],
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      ..._buildResultSlivers(context),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Grid, list, or empty state as slivers (below the scrollable chrome).
  List<Widget> _buildResultSlivers(BuildContext context) {
    if (_listings.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyStateContent(context),
        ),
      ];
    }
    if (_gridView) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 144 / 258,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final e = _listings[i];
                final highlighted = _listings.length > 3 && i == 3;
                return EstateCard.vertical(
                  title: e.title,
                  location: e.location,
                  price: e.price,
                  imageUrl: e.imageUrl,
                  rating: e.rating,
                  category: e.displayCategory,
                  isSaved: _savedIds.contains(e.id),
                  onToggleSaved: () => _toggleSaved(e),
                  onTap: () => context.push(AppRoutes.estateDetail(e.id)),
                  highlighted: highlighted,
                );
              },
              childCount: _listings.length,
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index.isOdd) return const SizedBox(height: 12);
              final i = index ~/ 2;
              final e = _listings[i];
              return EstateCard.horizontal(
                title: e.title,
                location: e.location,
                price: e.price,
                imageUrl: e.imageUrl,
                rating: e.rating,
                category: e.displayCategory,
                isSaved: _savedIds.contains(e.id),
                onToggleSaved: () => _toggleSaved(e),
                onTap: () => context.push(AppRoutes.estateDetail(e.id)),
                fullWidth: true,
                // Figma 24:3484 — taller horizontal cards when filters applied.
                compact: !_hasActiveFilters,
                withBlur: false,
              );
            },
            childCount: _listings.length * 2 - 1,
          ),
        ),
      ),
    ];
  }

  /// Figma 24:3591 — back 50, title, filter 50.
  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _ChromeIconButton(
              onTap: () => context.pop(),
              child: const Icon(Icons.chevron_left, size: 22, color: AppColors.textPrimary),
            ),
          ),
          Text(
            'Search results',
            style: GoogleFonts.raleway(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.42,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _ChromeIconButton(
              active: _hasActiveFilters,
              onTap: _openFilterModal,
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: _hasActiveFilters ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Figma 24:3590 — 70px, #F5F4F8, r20.
  Widget _buildSearchField(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: GoogleFonts.raleway(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.36,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Location',
                hintStyle: GoogleFonts.raleway(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.36,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
            ),
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.search, size: 20, color: AppColors.greyBarelyMedium),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  /// Figma `24:3486` — horizontal "Button / Filter - Rounded" chips under the found row.
  Widget _buildAppliedFilterChips(BuildContext context) {
    final chips = <Widget>[];

    if (_filterPropertyType != 'All') {
      chips.add(_filterChipPill(
        label: _filterPropertyType,
        onRemove: () {
          setState(() => _filterPropertyType = 'All');
          _load();
        },
      ));
    }

    final minP = _filterPriceMin?.trim() ?? '';
    final maxP = _filterPriceMax?.trim() ?? '';
    if (minP.isNotEmpty || maxP.isNotEmpty) {
      final a = minP.isEmpty ? '—' : minP;
      final b = maxP.isEmpty ? '—' : maxP;
      chips.add(_filterChipPill(
        label: '${_filterPreferRent ? 'Rent' : 'Buy'} \$${a}–\$${b}',
        onRemove: () {
          setState(() {
            _filterPriceMin = null;
            _filterPriceMax = null;
          });
          _load();
        },
      ));
    } else if (!_filterPreferRent) {
      chips.add(_filterChipPill(
        label: 'Buy',
        onRemove: () {
          setState(() => _filterPreferRent = true);
          _load();
        },
      ));
    }

    final minA = _filterAreaMin?.trim() ?? '';
    final maxA = _filterAreaMax?.trim() ?? '';
    if (minA.isNotEmpty || maxA.isNotEmpty) {
      chips.add(_filterChipPill(
        label: 'Area ${minA.isEmpty ? '—' : minA}–${maxA.isEmpty ? '—' : maxA} m²',
        onRemove: () {
          setState(() {
            _filterAreaMin = null;
            _filterAreaMax = null;
          });
          _load();
        },
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  /// Figma `24:3487` — “Button / Filter - Rounded” (cream pill, primary circle + white X left, label).
  Widget _filterChipPill({required String label, required VoidCallback onRemove}) {
    final useMontserrat = label.contains(r'$') ||
        label.toLowerCase().contains('area') ||
        label.toLowerCase().contains('m²');
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
        decoration: BoxDecoration(
          color: FigmaHantiRiyoTokens.exploreSearchFilterChipFill,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(Icons.close, size: 11, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: GestureDetector(
                onTap: _openFilterModal,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: useMontserrat
                      ? GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        )
                      : GoogleFonts.raleway(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Figma `24:3577` — Item / Header - Text - View (Lato + toggle with grid/list icons).
  Widget _buildFoundRow(BuildContext context) {
    final count = _listings.length;
    final base = GoogleFonts.lato(
      fontSize: 18,
      color: AppColors.textPrimary,
      letterSpacing: 0.54,
      height: 1.2,
    );
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: base.copyWith(fontWeight: FontWeight.w500),
                children: [
                  const TextSpan(text: 'Found '),
                  TextSpan(
                    text: '$count',
                    style: base.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF234F68),
                    ),
                  ),
                  TextSpan(
                    text: ' estates',
                    style: base.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          _ViewToggle(
            gridActive: _gridView,
            onGrid: () => setState(() => _gridView = true),
            onList: () => setState(() => _gridView = false),
          ),
        ],
      ),
    );
  }

  /// Figma 24:3583 — alert + title + subtitle (used inside [SliverFillRemaining]).
  Widget _buildEmptyStateContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 36,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              '!',
              style: GoogleFonts.montserrat(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.75,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Search',
                  style: GoogleFonts.lato(
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.75,
                    height: 40 / 25,
                  ),
                ),
                TextSpan(
                  text: ' not found ',
                  style: GoogleFonts.lato(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF234F68),
                    letterSpacing: 0.75,
                    height: 40 / 25,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 297,
            child: Text(
              "Sorry, we can't find the real estates you are looking for. Maybe, a little spelling mistake?",
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.greyMedium,
                height: 20 / 12,
                letterSpacing: 0.36,
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({
    required this.onTap,
    required this.child,
    this.active = false,
  });

  final VoidCallback onTap;
  final Widget child;
  /// Figma `24:3498` — filter control highlighted when filters are applied.
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFF234F68) : AppColors.greySoft1,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Center(
            child: Transform.translate(
              offset: const Offset(0, -0.5),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma `24:3577` — `Button / Show - Group` (grid + list). Uses Material icons so glyphs
/// stay visible; the old 12×12 custom squares were easy to lose on `#F5F4F8`.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.gridActive,
    required this.onGrid,
    required this.onList,
  });

  final bool gridActive;
  final VoidCallback onGrid;
  final VoidCallback onList;

  static const _iconSize = 20.0;
  static const _activeColor = AppColors.textPrimary;
  static const _inactiveColor = AppColors.greyBarelyMedium;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _segment(
            active: gridActive,
            onTap: onGrid,
            icon: Icons.grid_view_rounded,
            label: 'Grid view',
          ),
          const SizedBox(width: 5),
          _segment(
            active: !gridActive,
            onTap: onList,
            icon: Icons.view_list_rounded,
            label: 'List view',
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required bool active,
    required VoidCallback onTap,
    required IconData icon,
    required String label,
  }) {
    final color = active ? _activeColor : _inactiveColor;
    return Material(
      color: active ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        // Fixed box + Center so the glyph sits optically in the middle of the pill (not low).
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            // Material icons sit slightly low in the box; nudge for optical center.
            child: Transform.translate(
              offset: const Offset(0, -1),
              child: Icon(icon, size: _iconSize, color: color, semanticLabel: label),
            ),
          ),
        ),
      ),
    );
  }
}
