import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../utils/listing_performance_data.dart';

class ListingPerformanceSheet extends StatelessWidget {
  const ListingPerformanceSheet({
    super.key,
    required this.data,
  });

  final ListingPerformanceData data;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    child: Container(
                      width: 60,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Listing Performance',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.54,
                    ),
                  ),
                  const SizedBox(height: 54),
                  Text(
                    data.title,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.48,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.greyMedium),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.greyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  Text(
                    'Summary Stats',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 28,
                    runSpacing: 12,
                    children: [
                      _LegendMetric(
                        color: const Color(0xFF0062FF),
                        label: 'Total Views',
                        value: formatPerformanceCompact(data.totalViews),
                      ),
                      _LegendMetric(
                        color: const Color(0xFFFF974A),
                        label: 'Inquiries',
                        value: formatPerformanceCompact(data.inquiries),
                      ),
                      _LegendMetric(
                        color: const Color(0xFF3DD598),
                        label: 'Saves',
                        value: formatPerformanceCompact(data.saves),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xB2EEEEEE),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: const Icon(Icons.track_changes_rounded, color: AppColors.primary),
                        ),
                        const SizedBox(width: 22),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data.conversionRate}%',
                              style: GoogleFonts.raleway(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF171725),
                              ),
                            ),
                            Text(
                              'Conversion Rate',
                              style: GoogleFonts.raleway(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF696974),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    'Traffic Sources',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TrafficRow(color: const Color(0xFF0062FF), label: 'App', value: formatPerformanceCompact(data.appTraffic)),
                  const SizedBox(height: 10),
                  _TrafficRow(color: const Color(0xFFFF974A), label: 'Share', value: formatPerformanceCompact(data.shareTraffic)),
                  const SizedBox(height: 10),
                  _TrafficRow(color: const Color(0xFFFFC542), label: 'Ads', value: formatPerformanceCompact(data.adsTraffic)),
                  const SizedBox(height: 30),
                  Text(
                    'Promotion information',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < data.promotions.length; i++) ...[
                          _PromotionRow(info: data.promotions[i]),
                          if (i != data.promotions.length - 1) const SizedBox(height: 18),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(63),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: Text(
                        'Promote Your Listing',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.54,
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

class _LegendMetric extends StatelessWidget {
  const _LegendMetric({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF44444F),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: GoogleFonts.raleway(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TrafficRow extends StatelessWidget {
  const _TrafficRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.raleway(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF44444F),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF44444F),
          ),
        ),
      ],
    );
  }
}

class _PromotionRow extends StatelessWidget {
  const _PromotionRow({required this.info});

  final PromotionInfo info;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.2)),
          ),
          child: const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${info.title}\n',
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF44444F),
                    letterSpacing: 0.42,
                  ),
                ),
                TextSpan(
                  text: 'Expire:  ${info.expiry}',
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF44444F),
                    letterSpacing: 0.42,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String formatPerformanceCompact(int value) {
  if (value >= 1000) {
    final compact = value / 1000;
    final text = compact % 1 == 0 ? compact.toStringAsFixed(0) : compact.toStringAsFixed(1);
    return '${text}k';
  }
  return '$value';
}
