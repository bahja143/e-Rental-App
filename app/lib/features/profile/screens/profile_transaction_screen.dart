import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/centered_header_bar.dart';
import '../../../shared/widgets/remote_image.dart';
import '../data/models/profile_user.dart';
import '../data/repositories/profile_repository.dart';
import '../utils/profile_avatar_letter.dart';

class ProfileTransactionScreen extends StatefulWidget {
  const ProfileTransactionScreen({super.key});

  @override
  State<ProfileTransactionScreen> createState() => _ProfileTransactionScreenState();
}

class _ProfileTransactionScreenState extends State<ProfileTransactionScreen> {
  late final Future<ProfileUser> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileRepository().getMyProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<ProfileUser>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final profile = snapshot.data ?? const ProfileUser(name: 'Mathew Adam', email: 'mathew@email.com');
          final avatar = profile.avatarUrl?.trim() ?? '';
          final letter = profileAvatarLetterFromName(profile.name);

          return SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 19, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CenteredHeaderBar(
                    title: 'Profile',
                    titleSpacing: 0.42,
                  ),
                  const SizedBox(height: 20),
                  Row(
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
                                  errorWidget: _TransactionAvatarFallback(letter: letter),
                                )
                              : _TransactionAvatarFallback(letter: letter),
                        ),
                      ),
                      const SizedBox(width: 31),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name.isEmpty ? 'User' : profile.name,
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.42,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.email.isEmpty ? 'email@example.com' : profile.email,
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
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: _BalanceCard(
                          value: profile.availableBalance > 0 ? profile.availableBalance : 50000,
                          label: 'Available Balance',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BalanceCard(
                          value: profile.pendingBalance > 0 ? profile.pendingBalance : 30000,
                          label: 'Pending Balance',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.greySoft2, height: 1),
                  const SizedBox(height: 32),
                  _TransactionMenuItem(
                    icon: Icons.grid_view_rounded,
                    title: 'Listing Plan',
                    subtitle: 'Starter Pack',
                    subtitleColor: AppColors.primary,
                    onTap: () => context.push(AppRoutes.listingPlan),
                  ),
                  const SizedBox(height: 25),
                  _TransactionMenuItem(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Transaction History',
                    onTap: () => context.push(AppRoutes.transactionHistory),
                  ),
                  const SizedBox(height: 25),
                  _TransactionMenuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Withdraw Balance',
                    onTap: () => context.push(AppRoutes.withdrawBalance),
                  ),
                  const SizedBox(height: 25),
                  _TransactionMenuItem(
                    icon: Icons.show_chart_rounded,
                    title: 'Performance Report',
                    onTap: () => context.push(AppRoutes.performanceReport),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }
}

class _TransactionAvatarFallback extends StatelessWidget {
  const _TransactionAvatarFallback({required this.letter});

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

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.value,
    required this.label,
  });

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greySoft2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '\$${value.toStringAsFixed(0)}',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.42,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.greyMedium,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionMenuItem extends StatelessWidget {
  const _TransactionMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.greySoft1,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 24),
            ),
            const SizedBox(width: 21),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.48,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor ?? AppColors.greyMedium,
                        letterSpacing: 0.42,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 32,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.greySoft1,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
