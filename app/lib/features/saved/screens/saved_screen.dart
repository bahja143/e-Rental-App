import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../home/data/models/estate_item.dart';
import '../../home/data/repositories/estate_repository.dart';
import '../../home/widgets/estate_card.dart';

/// Favorite / Saved — Figma `34:5930` (empty), `34:5908` (filled), `34:5888` (delete).
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

enum _FavoriteViewMode { grid, list }

class _SavedScreenState extends State<SavedScreen> {
  final _repo = EstateRepository();
  final Set<String> _removingIds = <String>{};

  List<EstateItem> _items = const <EstateItem>[];
  bool _loading = true;
  _FavoriteViewMode _viewMode = _FavoriteViewMode.grid;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() => _loading = true);
    }
    final items = await _repo.getSavedEstates();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
      if (_items.isEmpty) {
        _viewMode = _FavoriteViewMode.grid;
      }
    });
  }

  Future<void> _refreshSaved() => _loadSaved(showSpinner: false);

  String _itemId(EstateItem item, int index) {
    if (item.id.isNotEmpty) return item.id;
    return '${item.title}-$index';
  }

  Future<bool> _removeSaved(EstateItem item, int index) async {
    final listingId = _itemId(item, index);
    if (_removingIds.contains(listingId)) return false;

    setState(() => _removingIds.add(listingId));
    final ok = await _repo.removeSavedEstate(listingId);
    if (!mounted) return false;

    setState(() {
      _removingIds.remove(listingId);
      if (ok) {
        final nextItems = List<EstateItem>.from(_items);
        if (index >= 0 && index < nextItems.length && _itemId(nextItems[index], index) == listingId) {
          nextItems.removeAt(index);
        } else {
          nextItems.removeWhere((e) => e.id == item.id && e.title == item.title);
        }
        _items = nextItems;
        if (_items.isEmpty) {
          _viewMode = _FavoriteViewMode.grid;
        }
      }
    });

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not remove saved property.',
            style: GoogleFonts.lato(),
          ),
        ),
      );
    }
    return ok;
  }

  Future<void> _showClearAllDialog() async {
    if (_items.isEmpty) return;
    final count = _items.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Clear all favorites?',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Remove all $count saved ${count == 1 ? 'property' : 'properties'} from your favorite list?',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: AppColors.greyMedium,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greyMedium,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBackground,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Clear all',
                style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final ids = <String>[
      for (var i = 0; i < _items.length; i++) _itemId(_items[i], i),
    ];
    setState(() {
      _loading = true;
      _removingIds.addAll(ids);
    });
    final ok = await _repo.clearSavedEstates(ids);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _removingIds.clear();
      if (ok) {
        _items = const <EstateItem>[];
        _viewMode = _FavoriteViewMode.grid;
      }
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not clear all favorites.',
            style: GoogleFonts.lato(),
          ),
        ),
      );
      await _loadSaved(showSpinner: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _FavoriteHeader(
              hasItems: total > 0,
              onDeletePressed: total == 0
                  ? null
                  : _showClearAllDialog,
            ),
            _FavoriteSummaryBar(
              total: total,
              viewMode: _viewMode,
              onModeChanged: (mode) => setState(() => _viewMode = mode),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _items.isEmpty
                      ? _FavoriteEmpty(onExplore: () => context.go(AppRoutes.home))
                      : _viewMode == _FavoriteViewMode.grid
                          ? _FavoriteListingGrid(
                              items: _items,
                              removingIds: _removingIds,
                              onOpenDetail: (id) => context.push(AppRoutes.estateDetail(id)),
                              onRemove: _removeSaved,
                              onRefresh: _refreshSaved,
                              itemId: _itemId,
                            )
                          : _FavoriteListingList(
                              items: _items,
                              removingIds: _removingIds,
                              onOpenDetail: (id) => context.push(AppRoutes.estateDetail(id)),
                              onRemove: _removeSaved,
                              onRefresh: _refreshSaved,
                              itemId: _itemId,
                            ),
            ),
            const AppBottomNavBar(currentIndex: 2),
          ],
        ),
      ),
    );
  }
}

/// Figma `34:5908` / `34:5930` — centered "My favorite" with a right-side trash button.
class _FavoriteHeader extends StatelessWidget {
  const _FavoriteHeader({
    required this.hasItems,
    required this.onDeletePressed,
  });

  final bool hasItems;
  final VoidCallback? onDeletePressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 40),
            Text(
              'My favorite',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDeletePressed,
                borderRadius: BorderRadius.circular(25),
                child: Opacity(
                  opacity: hasItems ? 1 : 0.7,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.greySoft1,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 22,
                      color: AppColors.textPrimary,
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

/// Figma `34:5908` / `34:5930` — count row + grid/list toggle pill.
class _FavoriteSummaryBar extends StatelessWidget {
  const _FavoriteSummaryBar({
    required this.total,
    required this.viewMode,
    required this.onModeChanged,
  });

  final int total;
  final _FavoriteViewMode viewMode;
  final ValueChanged<_FavoriteViewMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.lato(
      fontSize: 18,
      color: AppColors.textPrimary,
      letterSpacing: 0.54,
      height: 1,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            RichText(
              text: TextSpan(
                style: titleStyle,
                children: [
                  TextSpan(text: '$total', style: titleStyle.copyWith(fontWeight: FontWeight.w700)),
                  TextSpan(text: ' estates', style: titleStyle.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.greySoft1,
                borderRadius: BorderRadius.all(Radius.circular(100)),
              ),
              child: Row(
                children: [
                  _ViewModeButton(
                    active: viewMode == _FavoriteViewMode.grid,
                    icon: Icons.grid_view_rounded,
                    onTap: () => onModeChanged(_FavoriteViewMode.grid),
                  ),
                  const SizedBox(width: 5),
                  _ViewModeButton(
                    active: viewMode == _FavoriteViewMode.list,
                    icon: Icons.view_agenda_rounded,
                    onTap: () => onModeChanged(_FavoriteViewMode.list),
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

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.active,
    required this.icon,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Icon(
            icon,
            size: 12,
            color: active ? AppColors.textPrimary : AppColors.greyBarelyMedium.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

/// Figma `34:5930` — empty state with glowing plus CTA.
class _FavoriteEmpty extends StatelessWidget {
  const _FavoriteEmpty({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(24, 40, 24, MediaQuery.paddingOf(context).bottom + 24),
          children: [
            SizedBox(
              height: constraints.maxHeight - 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onExplore,
                    child: Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.34),
                            blurRadius: 42,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+',
                          style: GoogleFonts.montserrat(
                            fontSize: 30,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            letterSpacing: 0.9,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 297,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.lato(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.75,
                          height: 1.6,
                        ),
                        children: [
                          const TextSpan(text: 'Your favorite page is\n'),
                          TextSpan(
                            text: 'empty',
                            style: GoogleFonts.lato(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.75,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 297,
                    child: Text(
                      'Click add button above to start exploring and choose your favorite estates.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
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
            ),
          ],
        );
      },
    );
  }
}

/// Figma `34:5908` — filled grid view.
class _FavoriteListingGrid extends StatelessWidget {
  const _FavoriteListingGrid({
    required this.items,
    required this.removingIds,
    required this.onOpenDetail,
    required this.onRemove,
    required this.onRefresh,
    required this.itemId,
  });

  final List<EstateItem> items;
  final Set<String> removingIds;
  final void Function(String id) onOpenDetail;
  final Future<bool> Function(EstateItem item, int index) onRemove;
  final Future<void> Function() onRefresh;
  final String Function(EstateItem item, int index) itemId;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.61,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final id = itemId(item, index);
          final removing = removingIds.contains(id);
          return Stack(
            children: [
              Positioned.fill(
                child: AbsorbPointer(
                  absorbing: removing,
                  child: EstateCard.vertical(
                    title: item.title,
                    location: item.location,
                    price: item.price,
                    imageUrl: item.imageUrl,
                    rating: item.rating,
                    category: item.displayCategory,
                    isSaved: true,
                    onTap: () => onOpenDetail(id),
                    onToggleSaved: () => onRemove(item, index),
                  ),
                ),
              ),
              if (removing)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Figma `34:5888` — horizontal list with swipe-to-delete reveal state.
class _FavoriteListingList extends StatelessWidget {
  const _FavoriteListingList({
    required this.items,
    required this.removingIds,
    required this.onOpenDetail,
    required this.onRemove,
    required this.onRefresh,
    required this.itemId,
  });

  final List<EstateItem> items;
  final Set<String> removingIds;
  final void Function(String id) onOpenDetail;
  final Future<bool> Function(EstateItem item, int index) onRemove;
  final Future<void> Function() onRefresh;
  final String Function(EstateItem item, int index) itemId;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final id = itemId(item, index);
          final removing = removingIds.contains(id);

          return Dismissible(
            key: ValueKey(id),
            direction: removing ? DismissDirection.none : DismissDirection.endToStart,
            background: const _FavoriteDeleteBackground(),
            dismissThresholds: const {DismissDirection.endToStart: 0.32},
            confirmDismiss: (_) => onRemove(item, index),
            child: IgnorePointer(
              ignoring: removing,
              child: Stack(
                children: [
                  EstateCard.horizontal(
                    title: item.title,
                    location: item.location,
                    price: item.price,
                    imageUrl: item.imageUrl,
                    rating: item.rating,
                    category: item.displayCategory,
                    isSaved: true,
                    fullWidth: true,
                    onTap: () => onOpenDetail(id),
                    onToggleSaved: () => onRemove(item, index),
                  ),
                  if (removing)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.68),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteDeleteBackground extends StatelessWidget {
  const _FavoriteDeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      decoration: const BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.all(Radius.circular(25)),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 28),
      child: const Icon(
        Icons.delete_outline_rounded,
        size: 22,
        color: Colors.white,
      ),
    );
  }
}
