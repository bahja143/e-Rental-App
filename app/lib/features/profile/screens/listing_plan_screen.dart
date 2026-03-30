import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/centered_header_bar.dart';

class ListingPlanScreen extends StatelessWidget {
  const ListingPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const plans = <_ListingPlanData>[
      _ListingPlanData(
        title: 'Starter Pack',
        priceLabel: '\$3/month',
        benefits: [
          'Up to 3 listings per month',
          'Ideal For: New users or occasional sellers',
        ],
      ),
      _ListingPlanData(
        title: 'Growth Pack',
        priceLabel: '\$7/month',
        benefits: [
          'Up to 10 listings per month',
          'Ideal For: Active users with moderate needs',
        ],
      ),
      _ListingPlanData(
        title: 'Pro Pack',
        priceLabel: '\$35/month',
        benefits: [
          'Up to 30 listings per month',
          'Ideal For: Power users and businesses',
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          itemCount: plans.length + 1,
          separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 35 : 24),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const CenteredHeaderBar(
                title: 'Chose Listing Plan',
                titleSpacing: 0.42,
              );
            }
            return _ListingPlanCard(data: plans[index - 1]);
          },
        ),
      ),
    );
  }
}

class _ListingPlanCard extends StatelessWidget {
  const _ListingPlanCard({required this.data});

  final _ListingPlanData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF6F8EA6),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'What you\'ll get',
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFD0D0D0),
              letterSpacing: 0.36,
            ),
          ),
          const SizedBox(height: 10),
          for (final benefit in data.benefits) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    benefit,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      letterSpacing: 0.42,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            if (benefit != data.benefits.last) const SizedBox(height: 6),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 140,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                data.priceLabel,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.42,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingPlanData {
  const _ListingPlanData({
    required this.title,
    required this.priceLabel,
    required this.benefits,
  });

  final String title;
  final String priceLabel;
  final List<String> benefits;
}
