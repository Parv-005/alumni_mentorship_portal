import 'package:alumni_mentorship_platform/features/auth/view_models/auth_view_model.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Public route paths — anyone can visit these even when signed out.
const List<String> _publicPaths = <String>['/login', '/register'];

/// Default landing path for authenticated users.
const String _homePath = '/dashboard';

/// Returns a [GoRouterRedirect] that sends unauthenticated users to
/// `/login` and authenticated users away from `/login` and `/register`.
GoRouterRedirect buildAuthRedirect({required AuthViewModel authViewModel}) {
  return (BuildContext context, GoRouterState state) {
    final bool isAuthenticated = authViewModel.isAuthenticated;
    final bool isPublic = _publicPaths.contains(state.matchedLocation);

    if (!isAuthenticated && !isPublic) {
      return '/login?from=${Uri.encodeComponent(state.matchedLocation)}';
    }
    if (isAuthenticated && isPublic) {
      return _homePath;
    }
    return null;
  };
}
