import 'package:alumni_mentorship_platform/data/models/mentor.dart';
import 'package:alumni_mentorship_platform/data/models/user_profile.dart';
import 'package:alumni_mentorship_platform/features/mentors/view_models/mentor_detail_view_model.dart';
import 'package:alumni_mentorship_platform/shared/providers/app_providers.dart';
import 'package:alumni_mentorship_platform/shared/widgets/domain_chip.dart';
import 'package:alumni_mentorship_platform/shared/widgets/error_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/loading_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/role_badge.dart';
import 'package:alumni_mentorship_platform/shared/widgets/status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Detailed view of a single mentor: profile header, bio, skills, LinkedIn,
/// and a request-session call-to-action.
class MentorDetailScreen extends StatefulWidget {
  const MentorDetailScreen({super.key, required this.mentorId});

  final String mentorId;

  @override
  State<MentorDetailScreen> createState() => _MentorDetailScreenState();
}

class _MentorDetailScreenState extends State<MentorDetailScreen> {
  MentorDetailViewModel? _viewModel;
  String? _loadedMentorId;
  bool _loaded = false;

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  MentorDetailViewModel _ensureViewModel() {
    return _viewModel ??= MentorDetailViewModel(
      mentorRepository: AppProviders.of(context).mentorRepository,
      mentorId: widget.mentorId,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = _ensureViewModel();
    if (!_loaded || _loadedMentorId != widget.mentorId) {
      _loaded = true;
      _loadedMentorId = widget.mentorId;
      vm.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mentor')),
      body: RefreshIndicator(
        onRefresh: () => _ensureViewModel().refresh(),
        child: AnimatedBuilder(
          animation: _ensureViewModel(),
          builder: (BuildContext context, Widget? _) {
            final vm = _ensureViewModel();
            if (vm.loading && vm.mentor == null) {
              return const LoadingView(message: 'Loading mentor…');
            }
            if (vm.error != null && vm.mentor == null) {
              return ErrorView(message: vm.error!, onRetry: vm.refresh);
            }
            final Mentor mentor = vm.mentor!;
            return _MentorDetailBody(viewModel: vm, mentor: mentor);
          },
        ),
      ),
    );
  }
}

/// The scrollable body shown once a mentor has loaded. Composed of a
/// profile header, bio + skills, and the request-session CTA.
class _MentorDetailBody extends StatelessWidget {
  const _MentorDetailBody({required this.viewModel, required this.mentor});

  final MentorDetailViewModel viewModel;
  final Mentor mentor;

  @override
  Widget build(BuildContext context) {
    final UserProfile? profile = mentor.profile;
    final auth = AppProviders.of(context).authViewModel;
    final bool canRequest = viewModel.isAccepting && auth.isStudent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        _ProfileHeader(mentor: mentor, profile: profile),
        const SizedBox(height: 16),
        _RequestSessionButton(
          enabled: canRequest,
          isAccepting: viewModel.isAccepting,
          isStudent: auth.isStudent,
          isAuthenticated: auth.isAuthenticated,
          mentorId: mentor.id,
        ),
        const SizedBox(height: 24),
        _SectionTitle(text: 'About'),
        const SizedBox(height: 8),
        Text(mentor.bio, style: Theme.of(context).textTheme.bodyLarge),
        if (mentor.skills.isNotEmpty) ...<Widget>[
          const SizedBox(height: 24),
          _SectionTitle(text: 'Skills'),
          const SizedBox(height: 8),
          _SkillsWrap(skills: mentor.skills),
        ],
        if (mentor.linkedinUrl != null &&
            mentor.linkedinUrl!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 24),
          _SectionTitle(text: 'Connect'),
          const SizedBox(height: 8),
          _LinkedInTile(url: mentor.linkedinUrl!),
        ],
      ],
    );
  }
}

/// Hero-style card with avatar, name, role, domain, experience, and status.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.mentor, required this.profile});

  final Mentor mentor;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String name = profile?.fullName ?? 'Alumni mentor';
    final String? avatarUrl = profile?.avatarUrl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _Avatar(name: name, avatarUrl: avatarUrl),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(name, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      if (profile != null) RoleBadge(role: profile!.role),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                DomainChip(label: mentor.domain),
                _MetaChip(
                  icon: Icons.work_history_outlined,
                  label: '${mentor.experienceYears} yrs experience',
                ),
                if (profile?.program != null)
                  _MetaChip(
                    icon: Icons.school_outlined,
                    label: profile!.program!,
                  ),
                if (profile?.graduationYear != null)
                  _MetaChip(
                    icon: Icons.calendar_today_outlined,
                    label: 'Class of ${profile!.graduationYear}',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(status: mentor.availability),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _SkillsWrap extends StatelessWidget {
  const _SkillsWrap({required this.skills});

  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills
          .map(
            (String skill) => Chip(
              label: Text(skill),
              backgroundColor: theme.colorScheme.secondaryContainer,
              labelStyle: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
              ),
              side: BorderSide.none,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _LinkedInTile extends StatelessWidget {
  const _LinkedInTile({required this.url});

  final String url;

  Future<void> _onTap(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('LinkedIn URL copied: $url'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: () => _onTap(context),
        leading: Icon(Icons.link, color: theme.colorScheme.primary),
        title: const Text('LinkedIn profile'),
        subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.copy_outlined, size: 18),
      ),
    );
  }
}

/// The "Request Session" CTA. Disabled (with a reason) when the mentor is
/// not currently accepting requests or the current user is not a student.
class _RequestSessionButton extends StatelessWidget {
  const _RequestSessionButton({
    required this.enabled,
    required this.isAccepting,
    required this.isStudent,
    required this.isAuthenticated,
    required this.mentorId,
  });

  final bool enabled;
  final bool isAccepting;
  final bool isStudent;
  final bool isAuthenticated;
  final String mentorId;

  String get _hint {
    if (!isAuthenticated) {
      return 'Sign in as a student to request a session.';
    }
    if (!isStudent) {
      return 'Only students can request mentorship sessions.';
    }
    if (!isAccepting) {
      return 'This mentor is not currently accepting new requests.';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton.icon(
          onPressed: enabled
              ? () => context.go('/bookings/new/$mentorId')
              : null,
          icon: const Icon(Icons.event_available),
          label: const Text('Request session'),
        ),
        if (_hint.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            _hint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.avatarUrl});

  final String name;
  final String? avatarUrl;

  String get _initials {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return CircleAvatar(
        radius: 36,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          _initials,
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 36,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: NetworkImage(avatarUrl!),
      onBackgroundImageError: (_, _) {},
      child: Text(
        _initials,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );
  }
}
