import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../messages/data/models/chat_thread.dart';
import '../../messages/data/repositories/messages_repository.dart';
import '../data/models/notification_item.dart';
import '../data/repositories/notifications_repository.dart';
import '../widgets/message_card.dart';
import '../widgets/notification_card.dart';

/// Notification page – Figma 21-2989, 21-2973, 21-2961
/// Tabs: Notification | Messages. Filters: All, Review, Sold, House. Swipe-to-delete.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.initialTab = 'notification'});

  /// 'notification' or 'messages'
  final String initialTab;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late bool _showNotifications;
  String _notificationFilter = 'All';
  late Future<List<NotificationItem>> _notificationsFuture;
  late Future<List<ChatThread>> _messagesFuture;
  final List<String> _deletedNotificationIds = [];
  final List<String> _deletedMessageIds = [];
  bool _clearedAllNotifications = false;
  bool _clearedAllMessages = false;

  static const _notificationFilters = ['All', 'Review', 'Sold', 'House'];

  @override
  void initState() {
    super.initState();
    _showNotifications = widget.initialTab != 'messages';
    _reload();
  }

  void _reload() {
    _notificationsFuture = NotificationsRepository().getNotifications();
    _messagesFuture = MessagesRepository().getThreads();
  }

  bool _typeMatchesFilter(NotificationType type, String filter) {
    switch (filter) {
      case 'Review':
        return type == NotificationType.review;
      case 'Sold':
        return type == NotificationType.sold;
      case 'House':
        return type == NotificationType.favorite;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildTabBar(),
            const SizedBox(height: 20),
            if (_showNotifications) _buildFilterChips(),
            if (_showNotifications) const SizedBox(height: 20),
            Expanded(
              child: _showNotifications
                  ? _buildNotificationList()
                  : _buildMessagesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
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
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _onTrashTap,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.greySoft1,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTrashTap() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all?'),
        content: Text(
          _showNotifications
              ? 'Remove all notifications?'
              : 'Remove all messages?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                if (_showNotifications) {
                  _clearedAllNotifications = true;
                } else {
                  _clearedAllMessages = true;
                }
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.greySoft1,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showNotifications = true),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _showNotifications ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: _showNotifications
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Notification',
                    style: GoogleFonts.raleway(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _showNotifications
                          ? AppColors.textPrimary
                          : AppColors.greyBarelyMedium,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showNotifications = false),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: !_showNotifications ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: !_showNotifications
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Messages',
                    style: GoogleFonts.raleway(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: !_showNotifications
                          ? AppColors.textPrimary
                          : AppColors.greyBarelyMedium,
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

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: _notificationFilters
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _notificationFilter = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 17.5,
                    ),
                    decoration: BoxDecoration(
                      color: _notificationFilter == f
                          ? AppColors.primaryBackground
                          : AppColors.greySoft1,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        f,
                        style: GoogleFonts.raleway(
                          fontSize: 10,
                          fontWeight: _notificationFilter == f
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _notificationFilter == f
                              ? AppColors.greySoft1
                              : AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildNotificationList() {
    return FutureBuilder<List<NotificationItem>>(
      future: _notificationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.greyMedium,
                      ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(_reload),
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        if (_clearedAllNotifications) {
          return Center(
            child: Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.greyMedium,
                  ),
            ),
          );
        }
        var items = snapshot.data ?? const <NotificationItem>[];
        items = items
            .where((e) => !_deletedNotificationIds.contains(e.id))
            .where((e) => _notificationFilter == 'All' || _typeMatchesFilter(e.type, _notificationFilter))
            .toList();
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.greyMedium,
                  ),
            ),
          );
        }
        final today = items.where((e) => e.period == 'Today').toList();
        final older = items.where((e) => e.period != 'Today').toList();
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            if (today.isNotEmpty) ...[
              _buildSectionHeader('Today'),
              const SizedBox(height: 12),
              ...today.map((item) => _buildNotificationCard(item)),
            ],
            if (older.isNotEmpty) ...[
              if (today.isNotEmpty) const SizedBox(height: 24),
              _buildSectionHeader('Older notifications'),
              const SizedBox(height: 12),
              ...older.map((item) => _buildNotificationCard(item)),
            ],
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.raleway(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.54,
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return Dismissible(
      key: Key('notif-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        setState(() => _deletedNotificationIds.add(item.id));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: NotificationCard(
          type: item.type,
          title: item.title,
          body: item.body,
          time: item.time,
          avatarText: item.avatarText,
          imageUrl: item.imageUrl,
          avatarUrl: item.avatarUrl,
          bodyBoldParts: item.bodyBoldParts,
          onTap: () {},
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return FutureBuilder<List<ChatThread>>(
      future: _messagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load messages',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.greyMedium,
                      ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(_reload),
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        if (_clearedAllMessages) {
          return Center(
            child: Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.greyMedium,
                  ),
            ),
          );
        }
        var threads = snapshot.data ?? const <ChatThread>[];
        threads = threads
            .where((t) => !_deletedMessageIds.contains(t.id))
            .toList();
        if (threads.isEmpty) {
          return Center(
            child: Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.greyMedium,
                  ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            _buildSectionHeader('All chats'),
            const SizedBox(height: 12),
            ...threads.asMap().entries.map((e) {
              final thread = e.value;
              final isFirst = e.key == 0;
              return _buildMessageCard(thread, hasOnlineIndicator: isFirst);
            }),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildMessageCard(ChatThread thread, {bool hasOnlineIndicator = false}) {
    return Dismissible(
      key: Key('msg-${thread.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        setState(() => _deletedMessageIds.add(thread.id));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: MessageCard(
          name: thread.name,
          message: thread.message,
          time: thread.time,
          avatarText: thread.name.isNotEmpty ? thread.name[0] : '?',
          unreadCount: thread.unread,
          hasOnlineIndicator: hasOnlineIndicator && thread.unread > 0,
          onTap: () => context.push(AppRoutes.chatDetail(thread.id, name: thread.name)),
        ),
      ),
    );
  }
}
