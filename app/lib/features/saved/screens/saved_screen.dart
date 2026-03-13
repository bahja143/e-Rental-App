import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../home/data/models/estate_item.dart';
import '../../home/data/repositories/estate_repository.dart';
import '../../home/widgets/estate_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final _repo = EstateRepository();
  late Future<List<EstateItem>> _savedFuture;
  final Set<String> _removingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _savedFuture = _repo.getSavedEstates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<EstateItem>>(
          future: _savedFuture,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <EstateItem>[];
            final loading = snapshot.connectionState == ConnectionState.waiting;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : items.isEmpty
                          ? _buildEmpty(context)
                          : _buildList(context, items),
                ),
                const AppBottomNavBar(currentIndex: 2),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 80, color: AppColors.greyBarelyMedium),
            const SizedBox(height: 24),
            Text(
              'No saved properties yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the heart icon on any property to save it here.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Explore Properties'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<EstateItem> items) {
    return GridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.7,
      children: List.generate(items.length, (i) {
        final item = items[i];
        final id = item.id.isEmpty ? '${i + 1}' : item.id;
        final removing = _removingIds.contains(id);
        return Stack(
          children: [
            Positioned.fill(
              child: EstateCard.vertical(
                title: item.title,
                location: item.location,
                price: item.price,
                imageUrl: item.imageUrl,
                rating: item.rating,
                onTap: () => context.push(AppRoutes.estateDetail(id)),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: removing ? null : () => _removeSaved(id),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: removing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.favorite, size: 16, color: Colors.redAccent),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _removeSaved(String listingId) async {
    setState(() => _removingIds.add(listingId));
    final ok = await _repo.removeSavedEstate(listingId);
    if (!mounted) return;
    setState(() {
      _removingIds.remove(listingId);
      if (ok) {
        _savedFuture = _repo.getSavedEstates();
      }
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove saved property.')),
      );
    }
  }
}
