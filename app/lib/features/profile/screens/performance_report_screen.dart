import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/remote_image.dart';
import '../../home/data/models/estate_item.dart';
import '../../home/data/repositories/estate_repository.dart';
import '../data/models/profile_user.dart';
import '../data/repositories/profile_repository.dart';
import '../utils/listing_performance_data.dart';
import '../utils/profile_avatar_letter.dart';
import '../widgets/listing_performance_sheet.dart';

class PerformanceReportScreen extends StatefulWidget {
  const PerformanceReportScreen({super.key, this.estateId});

  final String? estateId;

  @override
  State<PerformanceReportScreen> createState() => _PerformanceReportScreenState();
}

class _PerformanceReportScreenState extends State<PerformanceReportScreen> {
  late final Future<_PerformanceReportPageData> _pageFuture;
  PerformanceRange _selectedRange = PerformanceRange.monthly;

  @override
  void initState() {
    super.initState();
    _pageFuture = _loadPage();
  }

  Future<_PerformanceReportPageData> _loadPage() async {
    final profile = await ProfileRepository().getMyProfile();
    final listings = await EstateRepository().getFeaturedEstates();
    final selected = listings.cast<EstateItem?>().firstWhere(
          (item) => item?.id == widget.estateId,
          orElse: () => listings.isNotEmpty ? listings.first : null,
        ) ??
        const EstateItem(
          id: '1',
          title: 'Fairview Apartment',
          location: 'Jakarta, Indonesia',
          price: 370,
          imageUrl: '',
          rating: 4.9,
        );
    return _PerformanceReportPageData(profile: profile, selectedListing: selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<_PerformanceReportPageData>(
          future: _pageFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            final pageData = snapshot.data ?? _PerformanceReportPageData.fallback();
            final metrics = buildListingPerformanceData(
              pageData.selectedListing,
              insightsCount: 18,
              range: _selectedRange,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 19, 24, 24),
              children: [
                SizedBox(
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        'Performance Report',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.54,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.pop(),
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
                ),
                const SizedBox(height: 20),
                _ProfileMiniCard(profile: pageData.profile),
                const SizedBox(height: 28),
                _RangeToggle(
                  selected: _selectedRange,
                  onSelected: (range) => setState(() => _selectedRange = range),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.savings_outlined,
                        title: 'Earnings',
                        value: '\$${metrics.earnings}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.home_outlined,
                        title: 'Properties',
                        value: '${metrics.properties}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.hourglass_bottom_rounded,
                        title: 'Pending',
                        value: '\$${metrics.pending}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Balance',
                        value: '\$${metrics.balance}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _EarningsChartCard(data: metrics),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }
}

class _PerformanceReportPageData {
  const _PerformanceReportPageData({
    required this.profile,
    required this.selectedListing,
  });

  final ProfileUser profile;
  final EstateItem selectedListing;

  factory _PerformanceReportPageData.fallback() {
    return const _PerformanceReportPageData(
      profile: ProfileUser(name: 'Mathew Adam', email: 'mathew@email.com'),
      selectedListing: EstateItem(
        id: '1',
        title: 'Fairview Apartment',
        location: 'Jakarta, Indonesia',
        price: 370,
        imageUrl: '',
        rating: 4.9,
      ),
    );
  }
}

class _ProfileMiniCard extends StatelessWidget {
  const _ProfileMiniCard({required this.profile});

  final ProfileUser profile;

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatarUrl?.trim() ?? '';
    final letter = profileAvatarLetterFromName(profile.name);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: SizedBox(
            width: 50,
            height: 50,
            child: avatar.isNotEmpty
                ? RemoteImage(
                    url: avatar,
                    fit: BoxFit.cover,
                    errorWidget: _AvatarFallback(letter: letter),
                  )
                : _AvatarFallback(letter: letter),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.name.isEmpty ? 'Mathew Adam' : profile.name,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.42,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.email.isEmpty ? 'mathew@email.com' : profile.email,
              style: GoogleFonts.lato(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.greyMedium,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.greySoft2,
      alignment: Alignment.center,
      child: Text(
        letter.isEmpty ? 'U' : letter,
        style: GoogleFonts.lato(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({
    required this.selected,
    required this.onSelected,
  });

  final PerformanceRange selected;
  final ValueChanged<PerformanceRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          for (final range in PerformanceRange.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(range),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 50,
                  decoration: BoxDecoration(
                    color: selected == range ? AppColors.primary : AppColors.primary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    range.label,
                    style: GoogleFonts.raleway(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF052224),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.greySoft1,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: 0.48,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.42,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsChartCard extends StatelessWidget {
  const _EarningsChartCard({required this.data});

  final ListingPerformanceData data;

  @override
  Widget build(BuildContext context) {
    const maxAxis = 15;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5D4),
        borderRadius: BorderRadius.circular(36),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Earnings',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF093030),
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _AxisText('15k'),
                    _AxisText('10k'),
                    _AxisText('5k'),
                    _AxisText('1k'),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            for (var i = 0; i < 4; i++)
                              Positioned.fill(
                                top: i * 38.0,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFFBDE3FF),
                                  ),
                                ),
                              ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                for (var i = 0; i < data.chartViews.length; i++)
                                  _BarGroup(
                                    blueHeight: data.chartViews[i] / maxAxis,
                                    greenHeight: data.chartConversions[i] / maxAxis,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(height: 1.5, color: const Color(0xFF67828C)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          _WeekText('1st Week'),
                          _WeekText('2nd Week'),
                          _WeekText('3rd Week'),
                          _WeekText('4th Week'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarGroup extends StatelessWidget {
  const _BarGroup({
    required this.blueHeight,
    required this.greenHeight,
  });

  final double blueHeight;
  final double greenHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Bar(heightFactor: greenHeight.clamp(0.08, 1), color: const Color(0xFF00D09E)),
          const SizedBox(width: 6),
          _Bar(heightFactor: blueHeight.clamp(0.12, 1), color: const Color(0xFF0068FF)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.heightFactor,
    required this.color,
  });

  final double heightFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: heightFactor,
        child: Container(
          width: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(31)),
          ),
        ),
      ),
    );
  }
}

class _AxisText extends StatelessWidget {
  const _AxisText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.leagueSpartan(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF6DB6FE),
      ),
    );
  }
}

class _WeekText extends StatelessWidget {
  const _WeekText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.leagueSpartan(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF0E3E3E),
      ),
    );
  }
}
