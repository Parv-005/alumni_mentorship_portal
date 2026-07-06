import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/data/models/forum_post.dart';
import 'package:alumni_mentorship_platform/features/forum/view_models/forum_feed_view_model.dart';
import 'package:alumni_mentorship_platform/shared/providers/app_providers.dart';
import 'package:alumni_mentorship_platform/shared/widgets/domain_chip.dart';
import 'package:alumni_mentorship_platform/shared/widgets/empty_state.dart';
import 'package:alumni_mentorship_platform/shared/widgets/error_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/loading_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/role_badge.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Main forum feed. Shows a list of [ForumPost]s grouped by sort order
/// (newest, unanswered, or top). Tapping a card opens the post detail
/// screen; the FAB opens the compose screen.
class ForumFeedScreen extends StatefulWidget {
  const ForumFeedScreen({super.key});

  @override
  State<ForumFeedScreen> createState() => _ForumFeedScreenState();
}

class _ForumFeedScreenState extends State<ForumFeedScreen> {
  ForumFeedViewModel? _viewModel;
  bool _loaded = false;

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  ForumFeedViewModel _ensureViewModel() {
    if (_viewModel == null) {
      _viewModel = ForumFeedViewModel(
        forumRepository: AppProviders.of(context).forumRepository,
      );
      developer.log('ForumFeedScreen init', name: 'ForumFeedScreen');
    }
    return _viewModel!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = _ensureViewModel();
    if (!_loaded) {
      _loaded = true;
      vm.listPosts();
    }
  }

  Future<void> _onSortSelected(String sort) async {
    await _ensureViewModel().setSort(sort);
  }

  Future<void> _onRefresh() async {
    await _ensureViewModel().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forum')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/forum/new'),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: AnimatedBuilder(
          animation: _ensureViewModel(),
          builder: (BuildContext context, Widget? _) {
            final vm = _ensureViewModel();
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: _SortBar(sort: vm.sort, onSelected: _onSortSelected),
                ),
                if (vm.error != null && vm.posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(message: vm.error!, onRetry: _onRefresh),
                  )
                else if (vm.loading && vm.posts.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: LoadingView(message: 'Loading posts…'),
                  )
                else if (vm.posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.forum_outlined,
                      title: 'No posts yet',
                      message: 'Be the first to start a discussion.',
                      action: FilledButton.icon(
                        onPressed: () => context.go('/forum/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('New post'),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    sliver: SliverList.builder(
                      itemCount: vm.posts.length,
                      itemBuilder: (BuildContext context, int index) {
                        final ForumPost post = vm.posts[index];
                        return _ForumPostCard(post: post);
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

/// Row of choice chips that drive the active sort.
class _SortBar extends StatelessWidget {
  const _SortBar({required this.sort, required this.onSelected});

  final String sort;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: <Widget>[
          ChoiceChip(
            label: const Text('Newest'),
            selected: sort == ForumFeedViewModel.sortNewest,
            onSelected: (_) => onSelected(ForumFeedViewModel.sortNewest),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Unanswered'),
            selected: sort == ForumFeedViewModel.sortUnanswered,
            onSelected: (_) => onSelected(ForumFeedViewModel.sortUnanswered),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Top'),
            selected: sort == ForumFeedViewModel.sortTop,
            onSelected: (_) => onSelected(ForumFeedViewModel.sortTop),
          ),
        ],
      ),
    );
  }
}

/// Tappable card that summarises a single [ForumPost].
class _ForumPostCard extends StatelessWidget {
  const _ForumPostCard({required this.post});

  final ForumPost post;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String authorName = post.author?.fullName ?? 'Unknown author';
    final String? authorRole = post.author?.role;
    final String relative = _formatRelative(post.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: () => context.go('/forum/${post.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _TypeBadge(type: post.type),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (post.answered) ...<Widget>[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                if (post.tags.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: post.tags
                        .map((String t) => DomainChip(label: t))
                        .toList(growable: false),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              _initials(authorName),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          if (authorRole != null) ...<Widget>[
                            const SizedBox(width: 6),
                            RoleBadge(role: authorRole),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.thumb_up_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text('${post.upvotes}', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 12),
                    Text(
                      relative,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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

  String _initials(String name) {
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
}

/// Pill that identifies the post type with an icon and label.
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final _TypeSpec spec = _specFor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(spec.icon, size: 14, color: spec.foreground),
          const SizedBox(width: 4),
          Text(
            spec.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: spec.foreground,
            ),
          ),
        ],
      ),
    );
  }

  _TypeSpec _specFor(String value) {
    switch (value) {
      case 'insight':
        return _TypeSpec(
          label: 'Insight',
          icon: Icons.lightbulb_outline,
          background: const Color(0xFFFFF59D),
          foreground: const Color(0xFF6B4E00),
        );
      case 'discussion':
        return _TypeSpec(
          label: 'Discussion',
          icon: Icons.forum_outlined,
          background: const Color(0xFFB3E5FC),
          foreground: const Color(0xFF01579B),
        );
      case 'question':
      default:
        return _TypeSpec(
          label: 'Question',
          icon: Icons.help_outline,
          background: const Color(0xFFD1C4E9),
          foreground: const Color(0xFF311B92),
        );
    }
  }
}

class _TypeSpec {
  const _TypeSpec({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
}

/// Tiny "Xh ago" / "Xm ago" / "Xd ago" helper. Returns the raw date if
/// the post is older than 7 days.
String _formatRelative(DateTime when) {
  final Duration diff = DateTime.now().difference(when);
  if (diff.isNegative) {
    return 'just now';
  }
  if (diff.inSeconds < 60) {
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
  return '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}';
}
