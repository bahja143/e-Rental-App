import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/notification_item.dart';
import '../data/repositories/notifications_repository.dart';
import '../widgets/notification_card.dart';

/// Notification / List - Messages, Reviews, Sold, Favorites
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';
  late Future<List<NotificationItem>> _notificationsFuture;

  static const _filters = ['All', 'Message', 'Review', 'Other'];

  @override
  void initState() {
    super.initState();
    _reloadNotifications();
  }

  void _reloadNotifications() {
    _notificationsFuture = NotificationsRepository().getNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildMenuFilter(context),
            const SizedBox(height: 20),
            _buildCategoryChips(),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<NotificationItem>>(
                future: _notificationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Could not load notifications',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.greyMedium),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setState(_reloadNotifications),
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    );
                  }
                  final allItems = snapshot.data ?? const <NotificationItem>[];
                  final items = _applyFilters(allItems);
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No notifications found',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.greyMedium),
                      ),
                    );
                  }

                  final todayItems = items.where((e) => e.period == 'Today').toList();
                  final yesterdayItems = items.where((e) => e.period == 'Yesterday').toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      if (todayItems.isNotEmpty) ...[
                        _buildSectionHeader('Today'),
                        const SizedBox(height: 12),
                        ..._buildCards(todayItems),
                      ],
                      if (yesterdayItems.isNotEmpty) ...[
                        if (todayItems.isNotEmpty) const SizedBox(height: 24),
                        _buildSectionHeader('Yesterday'),
                        const SizedBox(height: 12),
                        ..._buildCards(yesterdayItems),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
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
            'Notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.greySoft1,
              borderRadius: BorderRadius.circular(25),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.tune, size: 22, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuFilter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _MenuChip(
            label: 'All',
            isSelected: _selectedFilter == 'All',
            onTap: () => setState(() => _selectedFilter = 'All'),
          ),
          const SizedBox(width: 10),
          _MenuChip(
            label: 'Unread',
            isSelected: _selectedFilter == 'Unread',
            onTap: () => setState(() => _selectedFilter = 'Unread'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 47,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: _filters
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedFilter == f ? AppColors.primary : AppColors.greySoft1,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          f,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _selectedFilter == f ? Colors.white : AppColors.textPrimary,
                                fontWeight: _selectedFilter == f ? FontWeight.w600 : FontWeight.w400,
                              ),
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.greyBarelyMedium,
          ),
    );
  }

  List<NotificationItem> _applyFilters(List<NotificationItem> items) {
    var result = items;
    if (_selectedFilter == 'Unread') {
      result = result.where((e) => e.isUnread).toList();
    } else if (_selectedFilter != 'All') {
      result = result.where((e) => _typeMatchesFilter(e.type, _selectedFilter)).toList();
    }
    return result;
  }

  bool _typeMatchesFilter(NotificationType type, String filter) {
    switch (filter) {
      case 'Message':
        return type == NotificationType.message;
      case 'Review':
        return type == NotificationType.review;
      case 'Other':
        return type == NotificationType.sold || type == NotificationType.favorite;
      default:
        return true;
    }
  }

  List<Widget> _buildCards(List<NotificationItem> items) {
    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      widgets.add(
        NotificationCard(
          type: item.type,
          title: item.title,
          body: item.body,
          time: item.time,
          avatarText: item.avatarText,
          imageUrl: item.imageUrl,
          onTap: () {},
        ),
      );
      if (i != items.length - 1) widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }
}

class _MenuChip extends StatelessWidget {
  const _MenuChip({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.greySoft1,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}
