import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../../shared/models/user_model.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/requests/provider_request_detail_screen.dart';
import '../../features/guest_bookings/provider_guest_booking_detail_screen.dart';
import 'provider_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) => notifier.redirect(state),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/provider/requests/:id',
        builder: (context, state) => ProviderRequestDetailScreen(
          requestId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/provider/guest-bookings/:id',
        builder: (context, state) => ProviderGuestBookingDetailScreen(
          bookingId: int.parse(state.pathParameters['id']!),
        ),
      ),
      providerShellRoute,
    ],
  );
});

class _AuthRouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _AuthRouterNotifier(this._ref) {
    _ref.listen<AsyncValue<UserModel?>>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }

  String? redirect(GoRouterState state) {
    final authState = _ref.read(authNotifierProvider);
    if (authState.isLoading) return null;

    final user = authState.valueOrNull;
    final onAuthRoute =
        state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (user == null && !onAuthRoute) return '/login';
    if (user != null && onAuthRoute) return '/provider';
    if (user != null && user.role != 'provider') return '/login';
    return null;
  }
}
