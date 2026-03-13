import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/remote_image.dart';

enum NotificationType { message, review, sold, favorite }

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.avatarText,
    this.imageUrl,
    this.onTap,
  });

  final NotificationType type;
  final String title;
  final String body;
  final String time;
  final String avatarText;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: _colorForType(type),
                child: Text(
                  avatarText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            height: 1.4,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                            color: AppColors.greyBarelyMedium,
                          ),
                    ),
                  ],
                ),
              ),
              if (imageUrl != null)
                const SizedBox(width: 8),
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: RemoteImage(
                    url: imageUrl!,
                    width: 60,
                    height: 50,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      width: 60,
                      height: 50,
                      color: AppColors.greySoft1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return AppColors.primary;
      case NotificationType.review:
        return const Color(0xFF34A853);
      case NotificationType.sold:
        return const Color(0xFF4285F4);
      case NotificationType.favorite:
        return const Color(0xFFEA4335);
    }
  }
}
