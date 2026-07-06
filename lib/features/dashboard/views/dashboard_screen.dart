import 'package:alumni_mentorship_platform/data/models/forum_post.dart';
import 'package:alumni_mentorship_platform/features/auth/view_models/auth_view_model.dart';
import 'package:alumni_mentorship_platform/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:alumni_mentorship_platform/shared/providers/app_providers.dart';
import 'package:alumni_mentorship_platform/shared/widgets/empty_state.dart';
import 'package:alumni_mentorship_platform/shared/widgets/error_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/loading_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/role_badge.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Role-aware dashboard screen. Loads via [DashboardViewModel] and shows
/// the appropriate cards for students, alumni, and admins.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardViewModel? _viewModel;
  String? _loadedRole;

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final auth = AppProviders.of(context).authViewModel;
    final role = auth.role ?? 'student';
    final vm = _ensureViewModel();
    await vm.load(role: role);
  }

  DashboardViewModel _ensureViewModel() {
    final providers = AppProviders.of(context);
    return _viewModel ??= DashboardViewModel(
      bookingRepository: providers.bookingRepository,
      forumRepository: providers.forumRepository,
      mentorRepository: providers.mentorRepository,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AppProviders.of(context).authViewModel;
    final role = auth.role ?? 'student';
    _ensureViewModel();
    // Reload when the role changes (e.g. after login), but avoid reloading on
    // every rebuild within the same role.
    if (_loadedRole != role) {
      _loadedRole = role;
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthViewModel auth = AppProviders.of(context).authViewModel;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: <Widget>[
          if (auth.profile != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: RoleBadge(role: auth.profile!.role)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: AnimatedBuilder(
          animation: _ensureViewModel(),
          builder: (BuildContext context, Widget? _) {
            final vm = _ensureViewModel();
            if (vm.loading && !vm.recentPosts.isNotEmpty) {
              return const LoadingView(message: 'Loading dashboard…');
            }
            if (vm.error != null) {
              return ErrorView(message: vm.error!, onRetry: _refresh);
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _GreetingCard(name: auth.profile?.fullName ?? 'there'),
                const SizedBox(height: 16),
                _buildRoleCards(context, theme),
                const SizedBox(height: 24),
                Text('Recent forum posts', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (vm.recentPosts.isEmpty)
                  const EmptyState(
                    icon: Icons.forum_outlined,
                    title: 'No posts yet',
                    message: 'Be the first to start a discussion.',
                  )
                else
                  ...vm.recentPosts
                      .take(5)
                      .map((ForumPost p) => _ForumPostTile(post: p)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleCards(BuildContext context, ThemeData theme) {
    final AuthViewModel auth = AppProviders.of(context).authViewModel;
    final vm = _ensureViewModel();
    if (auth.isAdmin) {
      return _AdminCards(
        mentorCount: vm.mentorCount,
        bookingCount: vm.studentBookings.length + vm.mentorBookings.length,
        postCount: vm.recentPosts.length,
      );
    }
    if (auth.isMentor) {
      return _MentorCards(
        pendingCount: vm.pendingMentorRequestCount,
        sessionCount: vm.mentorBookings.length,
        hasMentorProfile: vm.isMentor,
      );
    }
    return _StudentCards(
      pendingCount: vm.pendingStudentRequestCount,
      requestCount: vm.studentBookings.length,
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            Icon(Icons.waving_hand, color: theme.colorScheme.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Hello, $name', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome to your mentorship hub.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCards extends StatelessWidget {
  const _StudentCards({required this.pendingCount, required this.requestCount});

  final int pendingCount;
  final int requestCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _ActionCard(
          icon: Icons.search,
          title: 'Browse mentors',
          subtitle: 'Find an alumni mentor to guide you',
          onTap: () => context.go('/mentors'),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatTile(
                label: 'My requests',
                value: requestCount.toString(),
                icon: Icons.send_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Awaiting reply',
                value: pendingCount.toString(),
                icon: Icons.hourglass_empty,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MentorCards extends StatelessWidget {
  const _MentorCards({
    required this.pendingCount,
    required this.sessionCount,
    required this.hasMentorProfile,
  });

  final int pendingCount;
  final int sessionCount;
  final bool hasMentorProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _ActionCard(
          icon: Icons.inbox_outlined,
          title: 'Incoming requests',
          subtitle: pendingCount == 0
              ? 'No new requests'
              : '$pendingCount need your attention',
          onTap: () => context.go('/bookings'),
          highlight: pendingCount > 0,
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatTile(
                label: 'My sessions',
                value: sessionCount.toString(),
                icon: Icons.event_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.edit_outlined,
                title: hasMentorProfile ? 'Edit profile' : 'Create profile',
                subtitle: 'Manage your mentor page',
                onTap: () => context.go('/mentors/edit'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminCards extends StatelessWidget {
  const _AdminCards({
    required this.mentorCount,
    required this.bookingCount,
    required this.postCount,
  });

  final int mentorCount;
  final int bookingCount;
  final int postCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatTile(
            label: 'Mentors',
            value: mentorCount.toString(),
            icon: Icons.workspace_premium_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Bookings',
            value: bookingCount.toString(),
            icon: Icons.event_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Posts',
            value: postCount.toString(),
            icon: Icons.forum_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineMedium),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      color: highlight ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                color: highlight
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: highlight
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: highlight
                            ? theme.colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.85,
                              )
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForumPostTile extends StatelessWidget {
  const _ForumPostTile({required this.post});

  final ForumPost post;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: () => context.go('/forum/${post.id}'),
        title: Text(
          post.title,
          style: theme.textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            _iconFor(post.type),
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        trailing: Text('${post.upvotes}'),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'question':
        return Icons.help_outline;
      case 'insight':
        return Icons.lightbulb_outline;
      case 'discussion':
      default:
        return Icons.forum_outlined;
    }
  }
}
