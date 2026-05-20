import 'package:go_router/go_router.dart';
import '../../features/dashboard/provider_dashboard_screen.dart';
import '../../features/requests/provider_requests_screen.dart';
import '../../features/bids/provider_bids_screen.dart';
import '../../features/jobs/provider_jobs_screen.dart';
import '../../features/notifications/provider_notifications_screen.dart';
import '../../features/profile/provider_profile_screen.dart';
import '../../features/reviews/provider_reviews_screen.dart';
import '../../features/guest_bookings/provider_guest_bookings_screen.dart';
import '../../features/shell/provider_shell.dart';

final providerShellRoute = ShellRoute(
  builder: (context, state, child) => ProviderShell(child: child),
  routes: [
    GoRoute(
      path: '/provider',
      builder: (context, state) => const ProviderDashboardScreen(),
    ),
    GoRoute(
      path: '/provider/requests',
      builder: (context, state) => const ProviderRequestsScreen(),
    ),
    GoRoute(
      path: '/provider/jobs',
      builder: (context, state) => const ProviderJobsScreen(),
    ),
    GoRoute(
      path: '/provider/bids',
      builder: (context, state) => const ProviderBidsScreen(),
    ),
    GoRoute(
      path: '/provider/notifications',
      builder: (context, state) => const ProviderNotificationsScreen(),
    ),
    GoRoute(
      path: '/provider/profile',
      builder: (context, state) => const ProviderProfileScreen(),
    ),
    GoRoute(
      path: '/provider/reviews',
      builder: (context, state) => const ProviderReviewsScreen(),
    ),
    GoRoute(
      path: '/provider/guest-bookings',
      builder: (context, state) => const ProviderGuestBookingsScreen(),
    ),
  ],
);
