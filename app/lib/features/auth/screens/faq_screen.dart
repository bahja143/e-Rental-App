import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// Login / FAQ - Find answers, search FAQ, info links
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _searchController = TextEditingController();
  final _faqItems = [
    ('What is Rise Real Estate?', ''),
    ('Why choose buy in Rise?', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut. aliquip ex ea commodo consequat. Duis aute irure dolor.'),
    ('What is Safar?', ''),
  ];
  int _expandedIndex = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'FAQ',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      '& Support',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Find answer to your problem using this app.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    _buildInfoSection(),
                    const SizedBox(height: 24),
                    _buildSearchBar(),
                    const SizedBox(height: 20),
                    _buildRoleSwitch(),
                    const SizedBox(height: 16),
                    _buildFaqList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
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
              alignment: Alignment.center,
              child: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.greyBarelyMedium),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Try find "how to"',
                border: InputBorder.none,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        _infoRow(Icons.language, 'Visit our website'),
        const Divider(height: 1),
        _infoRow(Icons.email_outlined, 'Email us'),
        const Divider(height: 1),
        _infoRow(Icons.description_outlined, 'Terms of service'),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRoleSwitch() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Buyer',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Estate Agent',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.greyBarelyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqList() {
    return Column(
      children: List.generate(_faqItems.length, (i) {
        final (q, a) = _faqItems[i];
        final isExpanded = _expandedIndex == i;
        return _FaqItem(
          question: q,
          answer: a,
          isExpanded: isExpanded,
          onTap: () => setState(() => _expandedIndex = isExpanded ? i : i),
        );
      }),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.remove : Icons.add,
                  size: 20,
                  color: isExpanded ? const Color(0xFFB9D537) : const Color(0xFF9ACB32),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
            ),
          ),
      ],
    );
  }
}
