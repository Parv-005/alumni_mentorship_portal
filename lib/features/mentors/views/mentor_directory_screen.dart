import 'package:alumni_mentorship_platform/data/models/mentor.dart';
import 'package:alumni_mentorship_platform/features/mentors/view_models/mentor_directory_view_model.dart';
import 'package:alumni_mentorship_platform/shared/providers/app_providers.dart';
import 'package:alumni_mentorship_platform/shared/widgets/domain_chip.dart';
import 'package:alumni_mentorship_platform/shared/widgets/empty_state.dart';
import 'package:alumni_mentorship_platform/shared/widgets/error_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/loading_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/status_pill.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Directory of mentors with search, domain, and availability filters.
class MentorDirectoryScreen extends StatefulWidget {
  const MentorDirectoryScreen({super.key});

  @override
  State<MentorDirectoryScreen> createState() => _MentorDirectoryScreenState();
}

class _MentorDirectoryScreenState extends State<MentorDirectoryScreen> {
  MentorDirectoryViewModel? _viewModel;
  TextEditingController? _searchController;
  bool _loaded = false;

  @override
  void dispose() {
    _searchController?.dispose();
    _viewModel?.dispose();
    super.dispose();
  }

  MentorDirectoryViewModel _ensureViewModel() {
    if (_viewModel == null) {
      _viewModel = MentorDirectoryViewModel(
        mentorRepository: AppProviders.of(context).mentorRepository,
      );
      _searchController = TextEditingController(text: _viewModel!.search);
    }
    return _viewModel!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = _ensureViewModel();
    if (!_loaded) {
      _loaded = true;
      vm.load();
    }
  }

  Future<void> _onSearchSubmitted(String value) async {
    final vm = _ensureViewModel();
    vm.setSearch(value);
    await vm.load();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final auth = AppProviders.of(context).authViewModel;
    final bool canBecomeMentor =
        auth.isAuthenticated && auth.profile?.role == 'alumni';

    return Scaffold(
      appBar: AppBar(title: const Text('Mentors')),
      floatingActionButton: canBecomeMentor
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/mentors/edit'),
              icon: const Icon(Icons.workspace_premium),
              label: const Text('Become a mentor'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => _ensureViewModel().refresh(),
        child: AnimatedBuilder(
          animation: _ensureViewModel(),
          builder: (BuildContext context, Widget? _) {
            final vm = _ensureViewModel();
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Search mentors by name',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: _onSearchSubmitted,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _DomainFilterBar(viewModel: vm)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: <Widget>[
                        FilterChip(
                          selected: vm.availableOnly,
                          onSelected: vm.setAvailableOnly,
                          avatar: Icon(
                            Icons.event_available,
                            size: 18,
                            color: vm.availableOnly
                                ? theme.colorScheme.onSecondaryContainer
                                : null,
                          ),
                          label: const Text('Available only'),
                        ),
                        const Spacer(),
                        if (vm.loading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                ),
                if (vm.error != null && vm.mentors.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(message: vm.error!, onRetry: vm.refresh),
                  )
                else if (vm.loading && vm.mentors.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: LoadingView(message: 'Loading mentors…'),
                  )
                else if (vm.mentors.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.workspace_premium_outlined,
                      title: 'No mentors found',
                      message: 'Try adjusting your filters or search keywords.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    sliver: SliverList.builder(
                      itemCount: vm.mentors.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Mentor mentor = vm.mentors[index];
                        return _MentorCard(mentor: mentor);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Horizontally scrollable row of domain filter chips.
class _DomainFilterBar extends StatelessWidget {
  const _DomainFilterBar({required this.viewModel});

  final MentorDirectoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: MentorDirectoryViewModel.kDomains.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return ChoiceChip(
              label: const Text('All'),
              selected: viewModel.domain == null,
              onSelected: (_) => viewModel.setDomain(null),
            );
          }
          final String domain = MentorDirectoryViewModel.kDomains[index - 1];
          return ChoiceChip(
            label: Text(domain),
            selected: viewModel.domain == domain,
            onSelected: (bool selected) =>
                viewModel.setDomain(selected ? domain : null),
          );
        },
      ),
    );
  }
}

/// Tappable card displaying a single mentor in the directory list.
class _MentorCard extends StatelessWidget {
  const _MentorCard({required this.mentor});

  final Mentor mentor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String name = mentor.profile?.fullName ?? 'Alumni mentor';
    final String? avatarUrl = mentor.profile?.avatarUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: () => context.go('/mentors/${mentor.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _MentorAvatar(name: name, avatarUrl: avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          DomainChip(label: mentor.domain),
                          const SizedBox(width: 8),
                          Text(
                            '${mentor.experienceYears} yrs exp',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mentor.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      StatusPill(status: mentor.availability),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar with network image + initials fallback.
class _MentorAvatar extends StatelessWidget {
  const _MentorAvatar({required this.name, required this.avatarUrl});

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
    final Widget fallback = CircleAvatar(
      radius: 28,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        _initials,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return fallback;
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: NetworkImage(avatarUrl!),
      onBackgroundImageError: (_, _) {},
      child: Text(
        _initials,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
