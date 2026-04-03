import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/theme/app_colors.dart';
import 'remote_image.dart';

class MediaGalleryItem {
  const MediaGalleryItem({
    required this.source,
    required this.isVideo,
  });

  final String source;
  final bool isVideo;

  bool get isRemote =>
      source.startsWith('http://') || source.startsWith('https://');

  static bool isVideoPath(String source) {
    final value = source.toLowerCase();
    return value.endsWith('.mp4') ||
        value.endsWith('.mov') ||
        value.endsWith('.webm') ||
        value.endsWith('.avi') ||
        value.endsWith('.mkv') ||
        value.endsWith('.m4v');
  }
}

Future<void> showMediaGalleryViewer(
  BuildContext context, {
  required List<MediaGalleryItem> items,
  int initialIndex = 0,
  String? footerTitle,
  String? footerAvatarUrl,
  double? footerRating,
}) async {
  if (items.isEmpty) return;
  await Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.white,
      pageBuilder: (_, __, ___) => MediaGalleryViewerPage(
        items: items,
        initialIndex: initialIndex.clamp(0, items.length - 1).toInt(),
        footerTitle: footerTitle,
        footerAvatarUrl: footerAvatarUrl,
        footerRating: footerRating,
      ),
    ),
  );
}

class MediaGalleryViewerPage extends StatefulWidget {
  const MediaGalleryViewerPage({
    super.key,
    required this.items,
    required this.initialIndex,
    this.footerTitle,
    this.footerAvatarUrl,
    this.footerRating,
  });

  final List<MediaGalleryItem> items;
  final int initialIndex;
  final String? footerTitle;
  final String? footerAvatarUrl;
  final double? footerRating;

  @override
  State<MediaGalleryViewerPage> createState() => _MediaGalleryViewerPageState();
}

class _MediaGalleryViewerPageState extends State<MediaGalleryViewerPage> {
  late final PageController _pageController;
  late int _index;
  VideoPlayerController? _videoController;
  bool _videoReady = false;

  MediaGalleryItem get _currentItem => widget.items[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
    _loadCurrentVideo();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _disposeVideoController();
    super.dispose();
  }

  Future<void> _loadCurrentVideo() async {
    _disposeVideoController();
    if (!_currentItem.isVideo) return;

    final controller = _currentItem.isRemote
        ? VideoPlayerController.networkUrl(Uri.parse(_currentItem.source))
        : VideoPlayerController.file(File(_currentItem.source));
    setState(() => _videoReady = false);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _videoController = controller;
        _videoReady = true;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _videoController = null;
        _videoReady = false;
      });
    }
  }

  void _disposeVideoController() {
    final controller = _videoController;
    _videoController = null;
    _videoReady = false;
    controller?.dispose();
  }

  void _goTo(int nextIndex) {
    if (nextIndex < 0 || nextIndex >= widget.items.length) return;
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height;
    final width = mediaQuery.size.width;
    final showFooter =
        (widget.footerTitle?.trim().isNotEmpty ?? false) || widget.footerRating != null;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: Colors.white),
                  ),
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.items.length,
                    onPageChanged: (value) {
                      setState(() => _index = value);
                      _loadCurrentVideo();
                    },
                    itemBuilder: (_, pageIndex) {
                      final item = widget.items[pageIndex];
                      final isActive = pageIndex == _index;
                      return _ViewerMediaFrame(
                        item: item,
                        videoController:
                            isActive && item.isVideo ? _videoController : null,
                        videoReady: isActive && item.isVideo && _videoReady,
                      );
                    },
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _ViewerCircleButton(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (widget.items.length > 1) ...[
                    Positioned(
                      left: 0,
                      top: math.max(120, height * 0.38 - mediaQuery.padding.top),
                      child: _ViewerSideButton(
                        onTap: () => _goTo(_index - 1),
                        alignment: Alignment.centerLeft,
                        icon: Icons.chevron_left_rounded,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: math.max(120, height * 0.38 - mediaQuery.padding.top),
                      child: _ViewerSideButton(
                        onTap: () => _goTo(_index + 1),
                        alignment: Alignment.centerRight,
                        icon: Icons.chevron_right_rounded,
                      ),
                    ),
                  ],
                  Positioned(
                    right: 14,
                    bottom: 24,
                    child: SizedBox(
                      width: 58,
                      height: math.min(221, widget.items.length * 71),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: widget.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, thumbIndex) {
                          final item = widget.items[thumbIndex];
                          final selected = thumbIndex == _index;
                          return GestureDetector(
                            onTap: () => _goTo(thumbIndex),
                            child: Container(
                              width: 58,
                              height: 63,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: selected ? AppColors.primary : Colors.white,
                                  width: selected ? 3.5 : 3,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    MediaThumbnail(item: item),
                                    if (item.isVideo)
                                      Container(
                                        color: Colors.black.withValues(alpha: 0.16),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.play_circle_fill_rounded,
                                          size: 22,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (showFooter)
                    Positioned(
                      left: 18,
                      bottom: 18,
                      child: _ViewerFooterPill(
                        title: widget.footerTitle?.trim().isNotEmpty == true
                            ? widget.footerTitle!.trim()
                            : 'Listing media',
                        avatarUrl: widget.footerAvatarUrl,
                        rating: widget.footerRating,
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: Center(
                      child: Text(
                        '${_index + 1}/${widget.items.length}',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.36,
                        ),
                      ),
                    ),
                  ),
                  if (_currentItem.isVideo && _videoController != null && _videoReady)
                    Positioned(
                      bottom: 96,
                      left: 0,
                      right: width * 0.2,
                      child: Center(
                        child: _ViewerCircleButton(
                          onTap: () async {
                            final controller = _videoController;
                            if (controller == null) return;
                            if (controller.value.isPlaying) {
                              await controller.pause();
                            } else {
                              await controller.play();
                            }
                            if (!mounted) return;
                            setState(() {});
                          },
                          fillColor: Colors.white.withValues(alpha: 0.25),
                          child: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 26,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    super.key,
    required this.item,
    this.fit = BoxFit.cover,
  });

  final MediaGalleryItem item;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (!item.isVideo) {
      if (item.isRemote) {
        return RemoteImage(
          url: item.source,
          fit: fit,
          errorWidget: Container(color: AppColors.greySoft2),
        );
      }
      return Image.file(
        File(item.source),
        fit: fit,
        errorBuilder: (_, __, ___) => Container(color: AppColors.greySoft2),
      );
    }
    return _VideoThumbnailView(source: item.source, fit: fit);
  }
}

class _ViewerMediaFrame extends StatelessWidget {
  const _ViewerMediaFrame({
    required this.item,
    required this.videoController,
    required this.videoReady,
  });

  final MediaGalleryItem item;
  final VideoPlayerController? videoController;
  final bool videoReady;

  @override
  Widget build(BuildContext context) {
    if (!item.isVideo) {
      return ColoredBox(
        color: Colors.white,
        child: MediaThumbnail(item: item, fit: BoxFit.cover),
      );
    }
    if (!videoReady || videoController == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.white),
          MediaThumbnail(item: item, fit: BoxFit.cover),
          Container(
            color: Colors.black.withValues(alpha: 0.2),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: Colors.white),
          ),
        ],
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: videoController!.value.size.width,
        height: videoController!.value.size.height,
        child: VideoPlayer(videoController!),
      ),
    );
  }
}

class _VideoThumbnailView extends StatefulWidget {
  const _VideoThumbnailView({
    required this.source,
    required this.fit,
  });

  final String source;
  final BoxFit fit;

  @override
  State<_VideoThumbnailView> createState() => _VideoThumbnailViewState();
}

class _VideoThumbnailViewState extends State<_VideoThumbnailView> {
  late Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant _VideoThumbnailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _thumbnailFuture = _loadThumbnail();
    }
  }

  Future<Uint8List?> _loadThumbnail() async {
    try {
      return await VideoThumbnail.thumbnailData(
        video: widget.source,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 70,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data != null) {
          return Image.memory(data, fit: widget.fit, gaplessPlayback: true);
        }
        return Container(
          color: AppColors.textSecondary.withValues(alpha: 0.12),
          alignment: Alignment.center,
          child: const Icon(
            Icons.play_circle_fill_rounded,
            size: 36,
            color: AppColors.textSecondary,
          ),
        );
      },
    );
  }
}

class _ViewerCircleButton extends StatelessWidget {
  const _ViewerCircleButton({
    required this.onTap,
    required this.child,
    this.fillColor,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fillColor ?? Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(25),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewerSideButton extends StatelessWidget {
  const _ViewerSideButton({
    required this.onTap,
    required this.alignment,
    required this.icon,
  });

  final VoidCallback onTap;
  final Alignment alignment;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(isLeft ? 18 : 0),
            left: Radius.circular(isLeft ? 0 : 18),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              width: 40,
              height: 83,
              alignment: alignment,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(isLeft ? 18 : 0),
                  left: Radius.circular(isLeft ? 0 : 18),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: isLeft ? 8 : 0,
                  right: isLeft ? 0 : 8,
                ),
                child: Icon(icon, size: 26, color: AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewerFooterPill extends StatelessWidget {
  const _ViewerFooterPill({
    required this.title,
    this.avatarUrl,
    this.rating,
  });

  final String title;
  final String? avatarUrl;
  final double? rating;

  @override
  Widget build(BuildContext context) {
    final avatar = avatarUrl?.trim() ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.greySoft1,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: avatar.isEmpty
                    ? const Icon(
                        Icons.photo_camera_outlined,
                        color: AppColors.textPrimary,
                      )
                    : MediaGalleryItem.isVideoPath(avatar)
                        ? const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.textPrimary,
                          )
                        : avatar.startsWith('http://') || avatar.startsWith('https://')
                            ? RemoteImage(
                                url: avatar,
                                fit: BoxFit.cover,
                                errorWidget: const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.textPrimary,
                                ),
                              )
                            : Image.file(
                                File(avatar),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.textPrimary,
                                ),
                              ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.36,
                    ),
                  ),
                  if (rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        final active = index < rating!.round().clamp(0, 5).toInt();
                        return Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: active
                              ? const Color(0xFFF6B52A)
                              : const Color(0xFFD8DBE8),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
