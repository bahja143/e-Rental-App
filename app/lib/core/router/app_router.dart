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
import '../../features/auth/screens/faq_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/estate_detail_screen.dart';
import '../../features/home/screens/agent_profile_screen.dart';
import '../../features/home/screens/location_detail_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/account_setup/screens/user_setup_screen.dart';
import '../../features/account_setup/screens/location_setup_screen.dart';
import '../../features/account_setup/screens/preferable_setup_screen.dart';
import '../../features/account_setup/screens/payment_setup_screen.dart';
import '../../features/account_setup/screens/account_success_screen.dart';
import '../../features/saved/screens/saved_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/explore/screens/explore_screen.dart';
import '../../features/messages/screens/messages_list_screen.dart';
import '../../features/messages/screens/chat_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/transaction/screens/transaction_summary_screen.dart';
import '../../features/transaction/screens/booking_success_screen.dart';
import '../../features/add_estate/screens/add_estate_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: ApiSession.authState,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isPublic = _publicPaths.contains(path);
      final isAuthenticated = ApiSession.isAuthenticated;

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
      GoRoute(path: AppRoutes.choice, builder: (_, __) => const ChoiceScreen()),
      GoRoute(path: AppRoutes.loginOption, builder: (_, __) => const LoginOptionScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, state) => OtpScreen(
          email: state.uri.queryParameters['email'] ?? 'jonathan@email.com',
        ),
      ),
      GoRoute(path: AppRoutes.faq, builder: (_, __) => const FaqScreen()),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(path: AppRoutes.search, builder: (_, __) => const SearchScreen()),
      GoRoute(path: AppRoutes.saved, builder: (_, __) => const SavedScreen()),
      GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: AppRoutes.editProfile, builder: (_, __) => const EditProfileScreen()),
      GoRoute(
        path: '${AppRoutes.estate}/:id',
        builder: (_, state) => EstateDetailScreen(
          estateId: state.pathParameters['id'] ?? '1',
        ),
      ),
      GoRoute(
        path: '${AppRoutes.agent}/:id',
        builder: (_, state) => AgentProfileScreen(
          agentId: state.pathParameters['id'] ?? '1',
        ),
      ),
      GoRoute(
        path: '${AppRoutes.location}/:name',
        builder: (_, state) => LocationDetailScreen(
          locationName: state.pathParameters['name'] ?? 'Mogadishu',
        ),
      ),
      GoRoute(path: AppRoutes.explore, builder: (_, __) => const ExploreScreen()),
      GoRoute(path: AppRoutes.messages, builder: (_, __) => const MessagesListScreen()),
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
      GoRoute(path: AppRoutes.addEstate, builder: (_, __) => const AddEstateScreen()),
      GoRoute(path: AppRoutes.accountSetupUser, builder: (_, __) => const UserSetupScreen()),
      GoRoute(path: AppRoutes.accountSetupLocation, builder: (_, __) => const LocationSetupScreen()),
      GoRoute(path: AppRoutes.accountSetupPreferable, builder: (_, __) => const PreferableSetupScreen()),
      GoRoute(path: AppRoutes.accountSetupPayment, builder: (_, __) => const PaymentSetupScreen()),
      GoRoute(path: AppRoutes.accountSetupSuccess, builder: (_, __) => const AccountSuccessScreen()),
    ],
  );
}

const Set<String> _publicPaths = {
  AppRoutes.welcome,
  AppRoutes.choice,
  AppRoutes.loginOption,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.otp,
  AppRoutes.faq,
};

const Set<String> _authOnlyPaths = {
  AppRoutes.welcome,
  AppRoutes.loginOption,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.otp,
  AppRoutes.faq,
};
