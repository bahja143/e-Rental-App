import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../home/data/models/estate_item.dart';
import '../../home/data/repositories/estate_repository.dart';
import '../../home/widgets/estate_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController(text: 'Location');
  final _repo = EstateRepository();
  bool _grid = false;
  late Future<List<EstateItem>> _searchFuture;
  Set<String> _savedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _searchFuture = _repo.searchEstates(_searchController.text.trim());
    _loadSavedIds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch() {
    final query = _searchController.text.trim();
    setState(() {
      _searchFuture = _repo.searchEstates(query);
    });
  }

  Future<void> _loadSavedIds() async {
    final ids = await _repo.getSavedEstateIds();
    if (!mounted) return;
    setState(() => _savedIds = ids);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.home),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.greySoft1,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
                        ),
                      ),
                      Text(
                        'Search results',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 25),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.greySoft1,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(Icons.tune, size: 20, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
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
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary, fontSize: 14),
                            onSubmitted: (_) => _runSearch(),
                          ),
                        ),
                        GestureDetector(
                          onTap: _runSearch,
                          child: const Icon(Icons.search, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<List<EstateItem>>(
                    future: _searchFuture,
                    builder: (context, snapshot) {
                      final total = snapshot.data?.length ?? 0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Found $total estates',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontSize: 40,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.greySoft1,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _grid = true),
                                  child: Container(
                                    width: 32,
                                    decoration: BoxDecoration(
                                      color: _grid ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(Icons.grid_view_rounded, size: 14, color: _grid ? AppColors.textPrimary : AppColors.greyBarelyMedium),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _grid = false),
                                  child: Container(
                                    width: 32,
                                    decoration: BoxDecoration(
                                      color: !_grid ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(Icons.view_agenda_rounded, size: 14, color: !_grid ? AppColors.textPrimary : AppColors.greyBarelyMedium),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<EstateItem>>(
                future: _searchFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  final items = snapshot.data ?? const <EstateItem>[];
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No estates found',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.greyMedium),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.63,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final e = items[i];
                      return EstateCard.vertical(
                        title: e.title,
                        price: e.price,
                        rating: e.rating,
                        location: e.location,
                        imageUrl: e.imageUrl,
                        highlighted: i == 3,
                        isSaved: _savedIds.contains(e.id),
                        onToggleSaved: () => _toggleSaved(e),
                        onTap: () => context.push(AppRoutes.estateDetail(e.id)),
                      );
                    },
                  );
                },
              ),
            ),
            const AppBottomNavBar(currentIndex: 1),
          ],
        ),
      ),
    );
  }
}
