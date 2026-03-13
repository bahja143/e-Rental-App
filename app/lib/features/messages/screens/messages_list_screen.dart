import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/chat_thread.dart';
import '../data/repositories/messages_repository.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  late Future<List<ChatThread>> _threadsFuture;

  @override
  void initState() {
    super.initState();
    _reloadThreads();
  }

  void _reloadThreads() {
    _threadsFuture = MessagesRepository().getThreads();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Messages', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<List<ChatThread>>(
        future: _threadsFuture,
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
                    'Could not load conversations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.greyMedium),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(_reloadThreads),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          }
          final chats = snapshot.data ?? const <ChatThread>[];
          if (chats.isEmpty) {
            return Center(
              child: Text(
                'No conversations yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.greyMedium),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            itemBuilder: (_, i) {
              final chat = chats[i];
              return ListTile(
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                  child: Text(chat.name[0], style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chat.time,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppColors.greyBarelyMedium),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (chat.unread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${chat.unread}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                  ],
                ),
                onTap: () {
                  final id = chat.id.isEmpty ? '$i' : chat.id;
                  context.push(AppRoutes.chatDetail(id, name: chat.name));
                },
              );
            },
          );
        },
      ),
    );
  }
}
