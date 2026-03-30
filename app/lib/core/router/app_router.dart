import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../network/api_session.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/onboarding/screens/choice_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/login_option_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/phone_verification_screen.dart';
import '../../features/auth/screens/faq_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/estate_detail_screen.dart';
import '../../features/home/screens/listing_reviews_screen.dart';
import '../../features/home/screens/listing_full_map_screen.dart';
import '../../features/home/screens/agent_profile_screen.dart';
import '../../features/home/screens/location_detail_screen.dart';
import '../../features/home/screens/top_locations_screen.dart';
import '../../features/home/screens/top_agents_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/profile_transaction_screen.dart';
import '../../features/profile/screens/profile_all_reviews_screen.dart';
import '../../features/profile/screens/performance_report_screen.dart';
import '../../features/profile/screens/listing_plan_screen.dart';
import '../../features/profile/screens/withdraw_balance_screen.dart';
import '../../features/profile/screens/withdraw_summary_screen.dart';
import '../../features/profile/screens/withdraw_success_screen.dart';
import '../../features/account_setup/screens/user_setup_screen.dart';
import '../../features/account_setup/screens/location_setup_screen.dart';
import '../../features/account_setup/screens/intent_setup_screen.dart';
import '../../features/account_setup/screens/preferable_setup_screen.dart';
import '../../features/account_setup/screens/payment_setup_screen.dart';
import '../../features/account_setup/screens/account_success_screen.dart';
import '../../features/saved/screens/saved_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/search/screens/search_results_screen.dart';
import '../../features/explore/screens/explore_screen.dart';
import '../../features/messages/screens/chat_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/transaction/screens/transaction_summary_screen.dart';
import '../../features/transaction/screens/booking_success_screen.dart';
import '../../features/transaction/screens/transaction_history_screen.dart';
import '../../features/transaction/screens/transaction_detail_screen.dart';
import '../../features/transaction/screens/dispute_detail_screen.dart';
import '../../features/transaction/screens/submit_review_screen.dart';
import '../../features/add_estate/screens/add_estate_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

bool _isFirstRedirect = true;

GoRouter createAppRouter() {
  final isAuth = ApiSession.isAuthenticated;
  // On fresh app open: home if logged in, welcome if not. No path storage.
  final startLocation = isAuth ? AppRoutes.home : AppRoutes.welcome;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: startLocation,
    refreshListenable: ApiSession.authState,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final basePath = path.split('?').first;
      final isPublic = _publicPaths.contains(path) ||
          path.startsWith('${AppRoutes.estate}/') ||
          path.startsWith('${AppRoutes.location}/');
      final isAuthenticated = ApiSession.isAuthenticated;

      // On app start: if unauthenticated and on registration route, go to welcome
      if (_isFirstRedirect) {
        _isFirstRedirect = false;
        if (!isAuthenticated &&
            _registrationFlowPaths.any((p) => basePath == p || basePath.startsWith('$p/'))) {
          return AppRoutes.welcome;
        }
      }

      if (!isAuthenticated && !isPublic) {
        return AppRoutes.loginOption;
      }

      if (isAuthenticated && _authOnlyPaths.contains(path)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.welcome, builder: (_, __) => const WelcomeScreen()),
      GoRoute(
        path: AppRoutes.choice,
        builder: (_, state) => ChoiceScreen(
          fromOtp: state.uri.queryParameters['fromOtp'] == '1',
        ),
      ),
      GoRoute(path: AppRoutes.loginOption, builder: (_, __) => const LoginOptionScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, state) {
          final name = state.uri.queryParameters['name'] ?? '';
          final email = state.uri.queryParameters['email'] ?? '';
          final phone = state.uri.queryParameters['phone'] ?? '';
          final profilePictureUrl = state.uri.queryParameters['profilePictureUrl'] ?? '';
          final emailDisabled = state.uri.queryParameters['emailDisabled'] == '1';
          return RegisterScreen(
            initialName: name.isNotEmpty ? name : null,
            initialEmail: email.isNotEmpty ? email : null,
            initialPhone: phone.isNotEmpty ? phone : null,
            initialProfilePictureUrl: profilePictureUrl.isNotEmpty ? profilePictureUrl : null,
            emailDisabled: emailDisabled,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, state) => OtpScreen(
          email: state.uri.queryParameters['email'] ?? 'jonathan@email.com',
        ),
      ),
      GoRoute(
        path: AppRoutes.phoneVerification,
        builder: (_, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          final name = state.uri.queryParameters['name'] ?? '';
          final email = state.uri.queryParameters['email'] ?? '';
          final profilePictureUrl = state.uri.queryParameters['profilePictureUrl'] ?? '';
          final isLoginMode = state.uri.queryParameters['mode'] == 'login';
          return PhoneVerificationScreen(
            phone: phone,
            name: name,
            email: email,
            profilePictureUrl: profilePictureUrl.isNotEmpty ? profilePictureUrl : null,
            isLoginMode: isLoginMode,
          );
        },
      ),
      GoRoute(path: AppRoutes.faq, builder: (_, __) => const FaqScreen()),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(path: AppRoutes.search, builder: (_, __) => const SearchScreen()),
      GoRoute(
        path: AppRoutes.listingMap,
        builder: (_, state) {
          final extra = state.extra;
          if (extra is ListingMapRouteArgs) {
            return ListingFullMapScreen(args: extra);
          }
          return const ListingFullMapScreen(
            args: ListingMapRouteArgs(
              estateId: '',
              title: 'Map',
              locationLabel: '',
              imageUrl: '',
              latitude: 2.0469,
              longitude: 45.3182,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.searchResults,
        builder: (_, state) => SearchResultsScreen(
          initialQuery: state.uri.queryParameters['q'],
        ),
      ),
      GoRoute(path: AppRoutes.saved, builder: (_, __) => const SavedScreen()),
      GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, state) {
          final tab = state.uri.queryParameters['tab'] ?? 'notification';
          return NotificationsScreen(initialTab: tab);
        },
      ),
      GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: AppRoutes.editProfile, builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: AppRoutes.profileTransaction, builder: (_, __) => const ProfileTransactionScreen()),
      GoRoute(path: AppRoutes.profileReviews, builder: (_, __) => const ProfileAllReviewsScreen()),
      GoRoute(path: AppRoutes.listingPlan, builder: (_, __) => const ListingPlanScreen()),
      GoRoute(
        path: AppRoutes.performanceReport,
        builder: (_, state) => PerformanceReportScreen(
          estateId: state.uri.queryParameters['estateId'],
        ),
      ),
      GoRoute(path: AppRoutes.withdrawBalance, builder: (_, __) => const WithdrawBalanceScreen()),
      GoRoute(
        path: AppRoutes.withdrawSummary,
        builder: (_, state) => WithdrawSummaryScreen(
          amount: state.uri.queryParameters['amount'] ?? '5000',
          method: state.uri.queryParameters['method'] ?? 'paypal',
        ),
      ),
      GoRoute(path: AppRoutes.withdrawSuccess, builder: (_, __) => const WithdrawSuccessScreen()),
      GoRoute(
        path: '${AppRoutes.estate}/:id/reviews',
        builder: (_, state) {
          final id = state.pathParameters['id'] ?? '1';
          final title = state.uri.queryParameters['title'];
          return ListingReviewsScreen(estateId: id, listingTitle: title);
        },
      ),
      GoRoute(
        path: '${AppRoutes.estate}/:id',
        builder: (_, state) => EstateDetailScreen(
          estateId: state.pathParameters['id'] ?? '1',
        ),
      ),
      GoRoute(
        path: '${AppRoutes.agent}/:id',
        builder: (_, state) {
          final id = state.pathParameters['id'] ?? '1';
          final rank = int.tryParse(state.uri.queryParameters['rank'] ?? '');
          return AgentProfileScreen(
            agentId: id,
            rank: rank != null && rank > 0 ? rank : null,
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.location}/:name',
        builder: (_, state) {
          final name = state.pathParameters['name'] ?? 'Mogadishu';
          final rank = int.tryParse(state.uri.queryParameters['rank'] ?? '');
          return LocationDetailScreen(
            locationName: name,
            rank: rank,
          );
        },
      ),
      GoRoute(path: AppRoutes.explore, builder: (_, __) => const ExploreScreen()),
      GoRoute(path: AppRoutes.topLocations, builder: (_, __) => const TopLocationsScreen()),
      GoRoute(path: AppRoutes.topAgents, builder: (_, __) => const TopAgentsScreen()),
      GoRoute(
        path: AppRoutes.messages,
        builder: (_, __) => const NotificationsScreen(initialTab: 'messages'),
      ),
      GoRoute(
        path: '${AppRoutes.chat}/:id',
        builder: (_, state) {
          final threadId = state.pathParameters['id'] ?? '0';
          final fallbackNames = ['Amanda', 'John', 'Sarah'];
          final index = int.tryParse(threadId) ?? 0;
          final name = state.uri.queryParameters['name'] ?? fallbackNames[index.clamp(0, 2)];
          return ChatScreen(
            threadId: threadId,
            agentName: name,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.transactionSummary,
        builder: (_, state) => TransactionSummaryScreen(
          estateId: state.uri.queryParameters['estateId'],
        ),
      ),
      GoRoute(path: AppRoutes.transactionSuccess, builder: (_, __) => const BookingSuccessScreen()),
      GoRoute(path: AppRoutes.transactionHistory, builder: (_, __) => const TransactionHistoryScreen()),
      GoRoute(
        path: '${AppRoutes.transactionDetail}/:id',
        builder: (_, state) => TransactionDetailScreen(
          transactionId: state.pathParameters['id'] ?? '1',
        ),
      ),
      GoRoute(
        path: '${AppRoutes.transactionDispute}/:id',
        builder: (_, state) => DisputeDetailScreen(
          transactionId: state.pathParameters['id'] ?? '1',
        ),
      ),
      GoRoute(
        path: AppRoutes.submitReview,
        builder: (_, state) => SubmitReviewScreen(
          listingId: state.uri.queryParameters['listingId'] ?? '1',
        ),
      ),
      GoRoute(path: AppRoutes.addEstate, builder: (_, __) => const AddEstateScreen()),
      GoRoute(
        path: '${AppRoutes.editEstate}/:id',
        builder: (_, state) => AddEstateScreen(
          estateId: state.pathParameters['id'],
        ),
      ),
      GoRoute(path: AppRoutes.accountSetupUser, builder: (_, __) => const UserSetupScreen()),
      GoRoute(path: AppRoutes.accountSetupLocation, builder: (_, __) => const LocationSetupScreen()),
      GoRoute(path: AppRoutes.accountSetupIntent, builder: (_, __) => const IntentSetupScreen()),
      GoRoute(path: AppRoutes.accountSetupPreferable, builder: (_, __) => const PreferableSetupScreen()),
      GoRoute(path: AppRoutes.accountSetupPayment, builder: (_, __) => const PaymentSetupScreen()),
      GoRoute(path: AppRoutes.accountSetupSuccess, builder: (_, __) => const AccountSuccessScreen()),
    ],
  );
}

/// Paths accessible without authentication (guest browsing + post-OTP onboarding flow).
const Set<String> _publicPaths = {
  AppRoutes.welcome,
  AppRoutes.choice,
  AppRoutes.loginOption,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.otp,
  AppRoutes.phoneVerification,
  AppRoutes.faq,
  AppRoutes.home,
  AppRoutes.search,
  AppRoutes.searchResults,
  AppRoutes.listingMap,
  AppRoutes.explore,
  AppRoutes.topLocations,
  AppRoutes.accountSetupIntent,
  AppRoutes.accountSetupPreferable,
  AppRoutes.accountSetupLocation,
  AppRoutes.accountSetupSuccess,
};

/// Registration/onboarding routes - do not restore when app restarts or is reopened.
/// User must restart from welcome if they were in the middle of registration.
/// Flow: choice -> preferable -> home (location page and success modal removed).
const Set<String> _registrationFlowPaths = {
  AppRoutes.register,
  AppRoutes.otp,
  AppRoutes.phoneVerification,
  AppRoutes.choice,
  AppRoutes.accountSetupPreferable,
};

const Set<String> _authOnlyPaths = {
  AppRoutes.welcome,
  AppRoutes.choice,
  AppRoutes.loginOption,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.otp,
  AppRoutes.phoneVerification,
  AppRoutes.faq,
};
