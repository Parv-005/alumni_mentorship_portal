import 'package:alumni_mentorship_platform/core/router/redirect.dart';
import 'package:alumni_mentorship_platform/features/auth/views/login_screen.dart';
import 'package:alumni_mentorship_platform/features/auth/views/register_screen.dart';
import 'package:alumni_mentorship_platform/features/bookings/views/booking_detail_screen.dart';
import 'package:alumni_mentorship_platform/features/bookings/views/booking_list_screen.dart';
import 'package:alumni_mentorship_platform/features/bookings/views/booking_request_screen.dart';
import 'package:alumni_mentorship_platform/features/dashboard/views/dashboard_screen.dart';
import 'package:alumni_mentorship_platform/features/forum/views/forum_compose_screen.dart';
import 'package:alumni_mentorship_platform/features/forum/views/forum_feed_screen.dart';
import 'package:alumni_mentorship_platform/features/forum/views/forum_post_detail_screen.dart';
import 'package:alumni_mentorship_platform/features/mentors/views/mentor_detail_screen.dart';
import 'package:alumni_mentorship_platform/features/mentors/views/mentor_directory_screen.dart';
import 'package:alumni_mentorship_platform/features/mentors/views/mentor_profile_editor_screen.dart';
import 'package:alumni_mentorship_platform/features/profile/views/profile_screen.dart';
import 'package:alumni_mentorship_platform/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Builds the app's [GoRouter]. The router refreshes whenever the
/// [AuthViewModel] notifies its listeners, so the redirect logic always
/// sees the latest session.
GoRouter buildRouter(AppProviders providers) {
  return GoRouter(
    initialLocation: '/dashboard',
    debugLogDiagnostics: false,
    refreshListenable: providers.authViewModel,
    redirect: buildAuthRedirect(authViewModel: providers.authViewModel),
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) =>
            const RegisterScreen(),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            _AppShell(currentLocation: state.matchedLocation, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: '/dashboard',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/mentors',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: MentorDirectoryScreen()),
            routes: <RouteBase>[
              GoRoute(
                path: 'edit',
                builder: (BuildContext context, GoRouterState state) =>
                    const MentorProfileEditorScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (BuildContext context, GoRouterState state) =>
                    MentorDetailScreen(mentorId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/bookings',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: BookingListScreen()),
            routes: <RouteBase>[
              GoRoute(
                path: 'new/:mentorId',
                builder: (BuildContext context, GoRouterState state) =>
                    BookingRequestScreen(
                      mentorId: state.pathParameters['mentorId']!,
                    ),
              ),
              GoRoute(
                path: ':id',
                builder: (BuildContext context, GoRouterState state) =>
                    BookingDetailScreen(bookingId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/forum',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: ForumFeedScreen()),
            routes: <RouteBase>[
              GoRoute(
                path: 'new',
                builder: (BuildContext context, GoRouterState state) =>
                    const ForumComposeScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (BuildContext context, GoRouterState state) =>
                    ForumPostDetailScreen(postId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (BuildContext context, GoRouterState state) =>
                const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Responsive shell: bottom navigation bar on narrow screens, navigation
/// rail on wide screens.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.currentLocation, required this.child});

  final String currentLocation;
  final Widget child;

  static const List<_NavTab> _tabs = <_NavTab>[
    _NavTab(
      label: 'Dashboard',
      path: '/dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _NavTab(
      label: 'Mentors',
      path: '/mentors',
      icon: Icons.workspace_premium_outlined,
      selectedIcon: Icons.workspace_premium,
    ),
    _NavTab(
      label: 'Forum',
      path: '/forum',
      icon: Icons.forum_outlined,
      selectedIcon: Icons.forum,
    ),
    _NavTab(
      label: 'Bookings',
      path: '/bookings',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
    ),
    _NavTab(
      label: 'Profile',
      path: '/profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  int get _selectedIndex {
    for (int i = 0; i < _tabs.length; i++) {
      if (currentLocation.startsWith(_tabs[i].path)) {
        return i;
      }
    }
    return 0;
  }

  void _onSelect(BuildContext context, int index) {
    context.go(_tabs[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final int selected = _selectedIndex;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 720;
        if (wide) {
          return Scaffold(
            body: Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: selected,
                  onDestinationSelected: (int i) => _onSelect(context, i),
                  labelType: NavigationRailLabelType.all,
                  destinations: _tabs
                      .map(
                        (_NavTab t) => NavigationRailDestination(
                          icon: Icon(t.icon),
                          selectedIcon: Icon(t.selectedIcon),
                          label: Text(t.label),
                        ),
                      )
                      .toList(growable: false),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }
        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: (int i) => _onSelect(context, i),
            destinations: _tabs
                .map(
                  (_NavTab t) => NavigationDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.selectedIcon),
                    label: t.label,
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.label,
    required this.path,
    required this.icon,
    required this.selectedIcon,
  });
  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
}
