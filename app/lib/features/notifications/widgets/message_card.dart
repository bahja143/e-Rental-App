import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/remote_image.dart';

/// Figma 21-2961: Card / Message, Card / Message - New
class MessageCard extends StatelessWidget {
  const MessageCard({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    required this.avatarText,
    this.avatarUrl,
    this.unreadCount = 0,
    this.hasOnlineIndicator = false,
    this.onTap,
    this.onDelete,
  });

  final String name;
  final String message;
  final String time;
  final String avatarText;
  final String? avatarUrl;
  final int unreadCount;
  final bool hasOnlineIndicator;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.greySoft1,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 9),
                        Text(
                          name,
                          style: GoogleFonts.raleway(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.36,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: GoogleFonts.raleway(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.greyMedium,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 9),
                      Text(
                        time,
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: AppColors.greyBarelyMedium,
                          letterSpacing: -0.16,
                          height: 17 / 8,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(19),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$unreadCount',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl!.trim().isNotEmpty
                  ? RemoteImage(
                      url: avatarUrl!,
                      fit: BoxFit.cover,
                      errorWidget: _placeholder,
                      placeholder: _placeholder,
                    )
                  : _placeholder,
            ),
          ),
        ),
        if (hasOnlineIndicator)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget get _placeholder => Container(
        color: AppColors.greySoft2,
        child: Center(
          child: Text(
            avatarText.isNotEmpty ? avatarText[0].toUpperCase() : '?',
            style: GoogleFonts.raleway(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.greyMedium,
            ),
          ),
        ),
      );
}
