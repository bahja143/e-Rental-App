import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/top_agent_item.dart';
import '../data/repositories/estate_repository.dart';
import '../../../shared/widgets/remote_image.dart';

/// Top Estate Agent grid – Figma 19-1764 (Hanti riyo – Copy)
/// ButtonBackSolid 50px, Title Lato 25px, Subtitle Raleway 12px.
/// Estates Card / User: 160×206, bg #F5F4F8, rounded 25, rank badge gold, avatar 100×100, name + stats.
class TopAgentsScreen extends StatefulWidget {
  const TopAgentsScreen({super.key});

  @override
  State<TopAgentsScreen> createState() => _TopAgentsScreenState();
}

class _TopAgentsScreenState extends State<TopAgentsScreen> {
  final _repo = EstateRepository();
  late final Future<List<TopAgentItem>> _agentsFuture;

  @override
  void initState() {
    super.initState();
    _agentsFuture = _repo.getTopAgents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<List<TopAgentItem>>(
          future: _agentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final agents = snapshot.data ?? [];
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.greySoft1,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Top Estate Agent',
                          style: GoogleFonts.lato(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.75,
                            height: 40 / 25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 327,
                          child: Text(
                            'Find the best recommendations place to live',
                            style: GoogleFonts.raleway(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.greyMedium,
                              letterSpacing: 0.36,
                              height: 20 / 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 7,
                      childAspectRatio: 160 / 206,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final agent = agents[i];
                        final rank = i + 1;
                        return _AgentCard(
                          agent: agent,
                          rank: rank,
                          onTap: () => context.push(AppRoutes.agentProfile(agent.id, rank: rank)),
                        );
                      },
                      childCount: agents.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({
    required this.agent,
    required this.rank,
    required this.onTap,
  });

  final TopAgentItem agent;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rating = agent.rating ?? 4.9;
    final sold = agent.soldCount ?? 112;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.greySoft1,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$rank',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.36,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 41,
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipOval(
                    child: agent.avatarUrl.trim().isNotEmpty
                        ? RemoteImage(
                            url: agent.avatarUrl,
                            fit: BoxFit.cover,
                            placeholder: _avatarPlaceholder,
                            errorWidget: _avatarPlaceholder,
                          )
                        : _avatarPlaceholder,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 154,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    agent.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.42,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, size: 9, color: AppColors.primary),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greyMedium,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.home_rounded, size: 9, color: AppColors.greyMedium),
                      const SizedBox(width: 2),
                      Text(
                        '$sold Sold',
                        style: GoogleFonts.raleway(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: AppColors.greyMedium,
                          height: 1.25,
                        ),
                      ),
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

  Widget get _avatarPlaceholder => Container(
        color: AppColors.greySoft2,
        child: Center(
          child: Text(
            agent.name.isNotEmpty ? agent.name[0].toUpperCase() : '?',
            style: GoogleFonts.raleway(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppColors.greyMedium,
            ),
          ),
        ),
      );
}
