import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/remote_image.dart';

enum NotificationType { message, review, sold, favorite }

/// Figma 21-2989: Card / Notification - Message, Review, Sold, Favorite
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.avatarText,
    this.imageUrl,
    this.avatarUrl,
    this.bodyBoldParts = const [],
    this.onTap,
    this.onDelete,
  });

  final NotificationType type;
  final String title;
  final String body;
  final String time;
  final String avatarText;
  final String? imageUrl;
  final String? avatarUrl;
  final List<String> bodyBoldParts;
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
          borderRadius: BorderRadius.circular(type == NotificationType.message ? 25 : 20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 9),
                  Text(
                    title,
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
                  _buildBody(),
                  const SizedBox(height: 4),
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
                ],
              ),
            ),
            if (imageUrl != null && type != NotificationType.message) ...[
              const SizedBox(width: 10),
              _buildThumbnail(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl!.trim().isNotEmpty
                  ? RemoteImage(
                      url: avatarUrl!,
                      fit: BoxFit.cover,
                      errorWidget: _avatarPlaceholder,
                      placeholder: _avatarPlaceholder,
                    )
                  : _avatarPlaceholder,
            ),
          ),
          if (type == NotificationType.review)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primaryBackground.withValues(alpha: 0.69),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Center(
                  child: Text('⭐', style: TextStyle(fontSize: 10)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget get _avatarPlaceholder => Container(
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

  Widget _buildBody() {
    if (bodyBoldParts.isEmpty) {
      return Text(
        body,
        style: GoogleFonts.raleway(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.greyMedium,
          letterSpacing: 0.3,
          height: 20 / 10,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }
    return _RichBody(
      body: body,
      boldParts: bodyBoldParts,
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 60,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: RemoteImage(
          url: imageUrl!,
          fit: BoxFit.cover,
          errorWidget: Container(color: AppColors.greySoft2),
          placeholder: Container(color: AppColors.greySoft2),
        ),
      ),
    );
  }
}

class _RichBody extends StatelessWidget {
  const _RichBody({required this.body, required this.boldParts});

  final String body;
  final List<String> boldParts;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    var remaining = body;
    while (remaining.isNotEmpty) {
      String? matchedBold;
      int matchStart = remaining.length;
      for (final part in boldParts) {
        if (part.isEmpty) continue;
        final idx = remaining.indexOf(part);
        if (idx >= 0 && idx < matchStart) {
          matchStart = idx;
          matchedBold = part;
        }
      }
      if (matchedBold != null && matchStart < remaining.length) {
        if (matchStart > 0) {
          spans.add(TextSpan(
            text: remaining.substring(0, matchStart),
            style: GoogleFonts.raleway(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.greyMedium,
              letterSpacing: 0.3,
              height: 20 / 10,
            ),
          ));
        }
        spans.add(TextSpan(
          text: matchedBold,
          style: GoogleFonts.raleway(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
            height: 20 / 10,
          ),
        ));
        remaining = remaining.substring(matchStart + matchedBold.length);
      } else {
        spans.add(TextSpan(
          text: remaining,
          style: GoogleFonts.raleway(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.greyMedium,
            letterSpacing: 0.3,
            height: 20 / 10,
          ),
        ));
        break;
      }
    }
    return RichText(
      text: TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
