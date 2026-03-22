import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../data/repositories/transaction_repository.dart';

class SubmitReviewScreen extends StatefulWidget {
  const SubmitReviewScreen({super.key, required this.listingId});

  final String listingId;

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  final _commentController = TextEditingController();
  final _picker = ImagePicker();
  final List<String> _imagePaths = <String>[];
  int _rating = 0;
  bool _submitting = false;
  bool _showSuccess = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() => _imagePaths.add(image.path));
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      _showSnack('Please select a rating.');
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      _showSnack('Please write a short review.');
      return;
    }
    setState(() => _submitting = true);
    final ok = await TransactionRepository().submitReview(
      listingId: widget.listingId,
      rating: _rating,
      comment: _commentController.text,
      imagePaths: _imagePaths,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _showSuccess = ok;
    });
    if (!ok) {
      _showSnack('Could not submit your review. Please try again.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    children: [
                      _ReviewHeader(onBack: () => context.pop()),
                      const SizedBox(height: 50),
                      Text(
                        'How Was Your Experience\nWith Us?',
                        style: GoogleFonts.lato(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.6,
                          letterSpacing: 0.75,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'We’d love to hear your thoughts,\nyour feedback helps us improve and serve you better.',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.greyMedium,
                          height: 1.7,
                          letterSpacing: 0.36,
                        ),
                      ),
                      const SizedBox(height: 34),
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 7,
                              children: List.generate(
                                5,
                                (index) => GestureDetector(
                                  onTap: () => setState(() => _rating = index + 1),
                                  child: Icon(
                                    index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                                    size: 40,
                                    color: const Color(0xFFFFB938),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _rating == 0 ? '0.0' : '${_rating.toStringAsFixed(1)}',
                            style: GoogleFonts.lato(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.75,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      _ReviewCommentBox(controller: _commentController),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 9,
                        runSpacing: 14,
                        children: [
                          ..._imagePaths.map(
                            (path) => _ReviewImageTile(
                              path: path,
                              onRemove: () => setState(() => _imagePaths.remove(path)),
                            ),
                          ),
                          _AddImageTile(onTap: _pickImage),
                        ],
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(70),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _submitting ? 'Submitting...' : 'Submit',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.48,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showSuccess)
            _ReviewSuccessOverlay(
              onClose: () {
                setState(() => _showSuccess = false);
                context.pop();
              },
            ),
        ],
      ),
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Add Review',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Positioned(
            left: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.greySoft1,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCommentBox extends StatelessWidget {
  const _ReviewCommentBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        maxLines: 4,
        style: GoogleFonts.lato(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.5,
          letterSpacing: 0.36,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
          border: InputBorder.none,
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 10, bottom: 68),
            child: Icon(Icons.message_outlined, size: 20, color: AppColors.textPrimary),
          ),
          prefixIconConstraints: const BoxConstraints(minHeight: 20, minWidth: 20),
          hintText: 'Write your experience in here (optional)',
          hintStyle: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.greyBarelyMedium,
            letterSpacing: 0.36,
          ),
        ),
      ),
    );
  }
}

class _ReviewImageTile extends StatelessWidget {
  const _ReviewImageTile({
    required this.path,
    required this.onRemove,
  });

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 159,
      height: 161,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greySoft1, width: 3),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Image.file(
                File(path),
                width: 159,
                height: 161,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: AppColors.greySoft1,
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(
            Icons.add_rounded,
            size: 28,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ReviewSuccessOverlay extends StatelessWidget {
  const _ReviewSuccessOverlay({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: const Color(0xB01F4C6B)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 467,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 27, 24, 24),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6E6A99),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 58),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, size: 34, color: Colors.white),
                    ),
                    const SizedBox(height: 56),
                    Text(
                      'Handover is completed\nSuccessfully!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.6,
                        letterSpacing: 0.75,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Love the estate?',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.54,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onClose,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(70),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.48,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
