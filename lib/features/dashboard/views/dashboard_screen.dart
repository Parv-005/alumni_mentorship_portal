import 'dart:math' as math;

import 'package:alumni_mentorship_platform/core/theme/app_theme.dart';
import 'package:alumni_mentorship_platform/data/models/forum_post.dart';
import 'package:alumni_mentorship_platform/data/models/mentor.dart';
import 'package:alumni_mentorship_platform/features/auth/view_models/auth_view_model.dart';
import 'package:alumni_mentorship_platform/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:alumni_mentorship_platform/shared/providers/app_providers.dart';
import 'package:alumni_mentorship_platform/shared/widgets/empty_state.dart';
import 'package:alumni_mentorship_platform/shared/widgets/error_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/grain_overlay.dart';
import 'package:alumni_mentorship_platform/shared/widgets/initials_avatar.dart';
import 'package:alumni_mentorship_platform/shared/widgets/loading_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/role_badge.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Width breakpoint that switches between the mobile and desktop layouts. The
/// app shell uses the same threshold for the NavigationBar/Rail swap.
const double _kDesktopBreakpoint = 720;

/// Role-aware dashboard screen. Loads via [DashboardViewModel] and shows
/// the appropriate cards for students, alumni, and admins.
///
/// The screen is responsive: below [_kDesktopBreakpoint] it uses a single
/// column with a top app bar; at or above the breakpoint it renders the
/// wider 12-column grid layout (the app shell provides the navigation rail).
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
    final AuthViewModel auth = AppProviders.of(context).authViewModel;
    final String role = auth.role ?? 'student';
    final DashboardViewModel vm = _ensureViewModel();
    await vm.load(role: role);
  }

  DashboardViewModel _ensureViewModel() {
    final AppProviders providers = AppProviders.of(context);
    return _viewModel ??= DashboardViewModel(
      bookingRepository: providers.bookingRepository,
      forumRepository: providers.forumRepository,
      mentorRepository: providers.mentorRepository,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AuthViewModel auth = AppProviders.of(context).authViewModel;
    final String role = auth.role ?? 'student';
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

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isDesktop = constraints.maxWidth >= _kDesktopBreakpoint;
        final DashboardViewModel vm = _ensureViewModel();

        return Scaffold(
          appBar: isDesktop ? null : AppBar(title: const Text('Dashboard')),
          body: Stack(
            children: <Widget>[
              const Positioned.fill(child: GrainOverlay()),
              RefreshIndicator(
                onRefresh: _refresh,
                child: AnimatedBuilder(
                  animation: vm,
                  builder: (BuildContext context, Widget? _) {
                    if (vm.loading && vm.recentPosts.isEmpty) {
                      // Wrap in a scrollable so RefreshIndicator can still pull
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const <Widget>[
                          SizedBox(height: 200),
                          LoadingView(message: 'Loading dashboard…'),
                        ],
                      );
                    }
                    if (vm.error != null) {
                      return ErrorView(message: vm.error!, onRetry: _refresh);
                    }
                    if (isDesktop) {
                      return _DesktopDashboard(
                        auth: auth,
                        theme: theme,
                        vm: vm,
                        onRefresh: _refresh,
                      );
                    }
                    return _MobileDashboard(auth: auth, theme: theme, vm: vm);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// Converts a [DateTime] into a short human-readable relative time string
/// like "3h ago" or "2d ago" — matching the Stitch design's footer copy.
String _relativeTime(DateTime createdAt) {
  final DateTime now = DateTime.now();
  final Duration diff = now.difference(createdAt);
  if (diff.inMinutes < 1) {
    return 'just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  }
  return '${createdAt.year}-${_two(createdAt.month)}-${_two(createdAt.day)}';
}

String _two(int n) => n.toString().padLeft(2, '0');

// ---------------------------------------------------------------------------
// Mobile layout (<720px)
// ---------------------------------------------------------------------------

class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({
    required this.auth,
    required this.theme,
    required this.vm,
  });

  final AuthViewModel auth;
  final ThemeData theme;
  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: <Widget>[
        if (auth.profile != null)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RoleBadge(role: auth.profile!.role),
            ),
          ),
        _GreetingCard(name: auth.profile?.fullName ?? 'there'),
        const SizedBox(height: 16),
        if (auth.isAdmin)
          _AdminCards(
            mentorCount: vm.mentorCount,
            bookingCount: vm.studentBookings.length + vm.mentorBookings.length,
            postCount: vm.recentPosts.length,
          )
        else if (auth.isMentor)
          _MentorCards(
            pendingCount: vm.pendingMentorRequestCount,
            sessionCount: vm.mentorBookings.length,
            hasMentorProfile: vm.isMentor,
          )
        else
          _StudentCards(
            pendingCount: vm.pendingStudentRequestCount,
            requestCount: vm.studentBookings.length,
          ),
        const SizedBox(height: 24),
        _ForumSectionHeader(
          title: 'Recent forum posts',
          actionLabel: 'See all',
          onAction: () => context.go('/forum'),
        ),
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
  }
}

// ---------------------------------------------------------------------------
// Desktop layout (>=720px)
// ---------------------------------------------------------------------------

class _DesktopDashboard extends StatelessWidget {
  const _DesktopDashboard({
    required this.auth,
    required this.theme,
    required this.vm,
    required this.onRefresh,
  });

  final AuthViewModel auth;
  final ThemeData theme;
  final DashboardViewModel vm;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
          children: <Widget>[
            _DesktopPageHeader(role: auth.profile?.role),
            const SizedBox(height: 32),
            _DesktopGreetingAndActivity(
              name: auth.profile?.fullName ?? 'there',
              pendingCount: vm.pendingStudentRequestCount,
            ),
            const SizedBox(height: 24),
            if (auth.isAdmin)
              _AdminCards(
                mentorCount: vm.mentorCount,
                bookingCount:
                    vm.studentBookings.length + vm.mentorBookings.length,
                postCount: vm.recentPosts.length,
                desktop: true,
              )
            else if (auth.isMentor)
              _MentorDesktopCards(
                pendingCount: vm.pendingMentorRequestCount,
                sessionCount: vm.mentorBookings.length,
                hasMentorProfile: vm.isMentor,
              )
            else ...<Widget>[
              _BrowseMentorsActionCard(desktop: true),
              const SizedBox(height: 16),
              _StudentStatsRow(
                requestCount: vm.studentBookings.length,
                pendingCount: vm.pendingStudentRequestCount,
                completedCount: vm.studentBookings
                    .where((b) => b.status == 'completed')
                    .length,
              ),
            ],
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 7,
                  child: _DesktopForumSection(
                    posts: vm.recentPosts.take(5).toList(),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 5,
                  child: _SuggestedMentorsSection(
                    mentors: vm.mentors.take(2).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopPageHeader extends StatelessWidget {
  const _DesktopPageHeader({required this.role});

  final String? role;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          'Dashboard',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        if (role != null) RoleBadge(role: role!),
      ],
    );
  }
}

class _DesktopGreetingAndActivity extends StatelessWidget {
  const _DesktopGreetingAndActivity({
    required this.name,
    required this.pendingCount,
  });

  final String name;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight gives the horizontal Row a finite cross-axis (height)
    // equal to the tallest child, so `CrossAxisAlignment.stretch` can equalize
    // the two cards without being forced to infinite height by the surrounding
    // sliver's unbounded vertical constraints.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(flex: 8, child: _GreetingCard(name: name, desktop: true)),
          const SizedBox(width: 24),
          Expanded(flex: 4, child: _ActivityCard(pendingCount: pendingCount)),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'ACTIVITY',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const _PulsingDot(),
              const SizedBox(width: 8),
              Text(
                '$pendingCount awaiting reply',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(_ctrl),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _DesktopForumSection extends StatelessWidget {
  const _DesktopForumSection({required this.posts});

  final List<ForumPost> posts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Recent forum posts',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/forum'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text(
                'View all',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (posts.isEmpty)
          const EmptyState(
            icon: Icons.forum_outlined,
            title: 'No posts yet',
            message: 'Be the first to start a discussion.',
          )
        else
          ...posts.map((ForumPost p) => _DesktopForumPostCard(post: p)),
      ],
    );
  }
}

class _DesktopForumPostCard extends StatelessWidget {
  const _DesktopForumPostCard({required this.post});

  final ForumPost post;

  @override
  Widget build(BuildContext context) {
    final String author = post.author?.fullName ?? 'Unknown';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.go('/forum/${post.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _TypePill(type: post.type),
                    const SizedBox(width: 8),
                    Text(
                      _relativeTime(post.createdAt),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        InitialsAvatar(
                          name: post.author?.fullName ?? '?',
                          radius: 12,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          author,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.thumb_up_outlined,
                          size: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.upvotes}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestedMentorsSection extends StatelessWidget {
  const _SuggestedMentorsSection({required this.mentors});

  final List<Mentor> mentors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Suggested for you',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        if (mentors.isEmpty)
          const EmptyState(
            icon: Icons.person_search_outlined,
            title: 'No mentor suggestions yet',
            message: 'Check back soon — new mentors are added regularly.',
          )
        else
          ...mentors.map((Mentor m) => _SuggestedMentorCard(mentor: m)),
        const SizedBox(height: 32),
        const _ExpandNetworkPromoCard(),
      ],
    );
  }
}

class _SuggestedMentorCard extends StatelessWidget {
  const _SuggestedMentorCard({required this.mentor});

  final Mentor mentor;

  @override
  Widget build(BuildContext context) {
    final String name = mentor.profile?.fullName ?? 'Mentor';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                InitialsAvatar(name: name, radius: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          mentor.domain.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go('/mentors/${mentor.id}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Request session'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandNetworkPromoCard extends StatelessWidget {
  const _ExpandNetworkPromoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, AppColors.primaryDeep],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: <Widget>[
          const Positioned(
            right: -16,
            bottom: -16,
            child: Icon(
              Icons.school_outlined,
              size: 120,
              color: Color(0x1AFFFFFF),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Expand your network',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Alumni from over 50 countries are ready to help you '
                'navigate your career journey.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/mentors'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'LEARN MORE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable card primitives
// ---------------------------------------------------------------------------

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.name, this.desktop = false});

  final String name;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: EdgeInsets.all(desktop ? 32 : 20),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.waving_hand,
                      color: AppColors.primary,
                      size: desktop ? 28 : 24,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Hello, $name',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: desktop ? 26 : 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desktop
                      ? 'Welcome to your mentorship hub. You have a few new updates waiting.'
                      : 'Welcome to your mentorship hub.',
                  style: GoogleFonts.outfit(
                    fontSize: desktop ? 15 : 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!desktop) ...<Widget>[
            const SizedBox(width: 12),
            const _ProgressRing(progress: 2 / 3, label: '2/3'),
          ],
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: const Size(48, 48),
            painter: _RingPainter(progress: progress),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 4;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    final Paint track = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    final Paint arc = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final double sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

class _BrowseMentorsActionCard extends StatelessWidget {
  const _BrowseMentorsActionCard({this.desktop = false});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.go('/mentors'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          padding: EdgeInsets.all(desktop ? 24 : 16),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(desktop ? 12 : 8),
                ),
                child: const Icon(Icons.search, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Browse mentors',
                      style: GoogleFonts.outfit(
                        fontSize: desktop ? 18 : 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desktop
                          ? 'Find someone in your field of study or interest'
                          : 'Find someone in your field',
                      style: GoogleFonts.outfit(
                        fontSize: desktop ? 14 : 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ],
          ),
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
        const _BrowseMentorsActionCard(),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatTile(
                label: 'My requests',
                value: requestCount.toString(),
                icon: Icons.send_outlined,
                iconTintIsPrimary: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Awaiting reply',
                value: pendingCount.toString(),
                icon: Icons.hourglass_empty,
                iconTintIsPrimary: true,
                valueColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StudentStatsRow extends StatelessWidget {
  const _StudentStatsRow({
    required this.requestCount,
    required this.pendingCount,
    required this.completedCount,
  });

  final int requestCount;
  final int pendingCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatTile(
            label: 'My requests',
            value: requestCount.toString(),
            icon: Icons.send_outlined,
            desktop: true,
            iconTintIsPrimary: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatTile(
            label: 'Awaiting reply',
            value: pendingCount.toString(),
            icon: Icons.hourglass_empty,
            desktop: true,
            iconTintIsPrimary: true,
            valueColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatTile(
            label: 'Sessions completed',
            value: completedCount.toString(),
            icon: Icons.check_circle_outline,
            desktop: true,
            iconTintIsPrimary: false,
          ),
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
        _HighlightActionCard(
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
                iconTintIsPrimary: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TertiaryActionCard(
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

class _MentorDesktopCards extends StatelessWidget {
  const _MentorDesktopCards({
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
        _HighlightActionCard(
          icon: Icons.inbox_outlined,
          title: 'Incoming requests',
          subtitle: pendingCount == 0
              ? 'No new requests'
              : '$pendingCount need your attention',
          onTap: () => context.go('/bookings'),
          highlight: pendingCount > 0,
          desktop: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatTile(
                label: 'My sessions',
                value: sessionCount.toString(),
                icon: Icons.event_outlined,
                desktop: true,
                iconTintIsPrimary: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _TertiaryActionCard(
                icon: Icons.edit_outlined,
                title: hasMentorProfile ? 'Edit profile' : 'Create profile',
                subtitle: 'Manage your mentor page',
                onTap: () => context.go('/mentors/edit'),
                desktop: true,
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
    this.desktop = false,
  });

  final int mentorCount;
  final int bookingCount;
  final int postCount;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    if (desktop) {
      return Row(
        children: <Widget>[
          Expanded(
            child: _StatTile(
              label: 'Mentors',
              value: mentorCount.toString(),
              icon: Icons.workspace_premium_outlined,
              desktop: true,
              iconTintIsPrimary: false,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatTile(
              label: 'Bookings',
              value: bookingCount.toString(),
              icon: Icons.event_outlined,
              desktop: true,
              iconTintIsPrimary: false,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatTile(
              label: 'Posts',
              value: postCount.toString(),
              icon: Icons.forum_outlined,
              desktop: true,
              iconTintIsPrimary: false,
            ),
          ),
        ],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatTile(
            label: 'Mentors',
            value: mentorCount.toString(),
            icon: Icons.workspace_premium_outlined,
            iconTintIsPrimary: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Bookings',
            value: bookingCount.toString(),
            icon: Icons.event_outlined,
            iconTintIsPrimary: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Posts',
            value: postCount.toString(),
            icon: Icons.forum_outlined,
            iconTintIsPrimary: false,
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
    this.desktop = false,
    this.iconTintIsPrimary = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool desktop;
  final bool iconTintIsPrimary;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final double iconOpacity = iconTintIsPrimary ? 0.4 : 0.4;
    final Color iconColor = iconTintIsPrimary
        ? AppColors.primary.withValues(alpha: iconOpacity)
        : AppColors.onSurfaceVariant.withValues(alpha: iconOpacity);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: desktop ? AppColors.cardGlow() : null,
      ),
      padding: EdgeInsets.all(desktop ? 24 : 16),
      child: Stack(
        children: <Widget>[
          if (desktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.6,
                  ),
                ),
                Icon(icon, size: 20, color: iconColor),
              ],
            )
          else
            Align(
              alignment: Alignment.topRight,
              child: Icon(icon, size: 20, color: iconColor),
            ),
          Padding(
            padding: EdgeInsets.only(top: desktop ? 36 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (!desktop) ...<Widget>[
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: desktop ? 32 : 28,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightActionCard extends StatelessWidget {
  const _HighlightActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.highlight,
    this.desktop = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final Color background = highlight
        ? AppColors.primary.withValues(alpha: 0.1)
        : AppColors.card;
    final Color border = highlight
        ? AppColors.primary.withValues(alpha: 0.2)
        : AppColors.outlineVariant;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          padding: EdgeInsets.all(desktop ? 24 : 16),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(desktop ? 12 : 8),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: desktop ? 18 : 17,
                        fontWeight: FontWeight.w600,
                        color: highlight
                            ? AppColors.primary
                            : AppColors.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: desktop ? 14 : 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TertiaryActionCard extends StatelessWidget {
  const _TertiaryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.desktop = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          padding: EdgeInsets.all(desktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: desktop ? 16 : 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: desktop ? 13 : 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForumSectionHeader extends StatelessWidget {
  const _ForumSectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
          ),
          child: Text(
            actionLabel,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ForumPostTile extends StatelessWidget {
  const _ForumPostTile({required this.post});

  final ForumPost post;

  @override
  Widget build(BuildContext context) {
    final String author = post.author?.fullName ?? 'Unknown';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.go('/forum/${post.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    InitialsAvatar(
                      name: post.author?.fullName ?? '?',
                      radius: 14,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        post.title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _TypePill(type: post.type),
                    Flexible(
                      child: Text(
                        '$author · ${post.upvotes} upvotes · '
                        '${_relativeTime(post.createdAt)}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final _TypeStyle style = _styleFor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        style.label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: style.foreground,
        ),
      ),
    );
  }

  static _TypeStyle _styleFor(String type) {
    switch (type) {
      case 'question':
        return const _TypeStyle(
          label: 'Question',
          background: AppColors.statusLavenderBg,
          foreground: AppColors.statusLavenderText,
        );
      case 'insight':
        return const _TypeStyle(
          label: 'Insight',
          background: AppColors.statusAmberBg,
          foreground: AppColors.statusAmberText,
        );
      case 'discussion':
      default:
        return const _TypeStyle(
          label: 'Discussion',
          background: AppColors.statusBlueBg,
          foreground: AppColors.statusBlueText,
        );
    }
  }
}

class _TypeStyle {
  const _TypeStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });
  final String label;
  final Color background;
  final Color foreground;
}
