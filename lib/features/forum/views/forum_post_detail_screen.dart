import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/data/models/forum_post.dart';
import 'package:alumni_mentorship_platform/data/models/forum_reply.dart';
import 'package:alumni_mentorship_platform/features/forum/view_models/forum_post_detail_view_model.dart';
import 'package:alumni_mentorship_platform/shared/providers/app_providers.dart';
import 'package:alumni_mentorship_platform/shared/widgets/domain_chip.dart';
import 'package:alumni_mentorship_platform/shared/widgets/empty_state.dart';
import 'package:alumni_mentorship_platform/shared/widgets/error_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/loading_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/role_badge.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Detail screen for a single forum post. Shows the post header, the
/// list of replies, and a reply composer at the bottom.
class ForumPostDetailScreen extends StatefulWidget {
  const ForumPostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<ForumPostDetailScreen> createState() => _ForumPostDetailScreenState();
}

class _ForumPostDetailScreenState extends State<ForumPostDetailScreen> {
  ForumPostDetailViewModel? _viewModel;
  TextEditingController? _replyController;
  String? _loadedPostId;
  bool _loaded = false;

  @override
  void dispose() {
    _replyController?.dispose();
    _viewModel?.dispose();
    super.dispose();
  }

  ForumPostDetailViewModel _ensureViewModel() {
    if (_viewModel == null) {
      _viewModel = ForumPostDetailViewModel(
        forumRepository: AppProviders.of(context).forumRepository,
        postId: widget.postId,
      );
      _replyController = TextEditingController();
      developer.log(
        'ForumPostDetailScreen init id=${widget.postId}',
        name: 'ForumPostDetailScreen',
      );
    }
    return _viewModel!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = _ensureViewModel();
    if (!_loaded || _loadedPostId != widget.postId) {
      _loaded = true;
      _loadedPostId = widget.postId;
      vm.load();
    }
  }

  Future<void> _onRefresh() async {
    await _ensureViewModel().refresh();
  }

  Future<void> _onSend() async {
    final vm = _ensureViewModel();
    final controller = _replyController!;
    final String text = controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    final bool ok = await vm.addReply(body: text);
    if (!mounted) {
      return;
    }
    if (ok) {
      controller.clear();
      FocusScope.of(context).unfocus();
    } else {
      final String? message = vm.sendError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Failed to send reply')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = _ensureViewModel();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/forum'),
        ),
      ),
      // The body is a Column (bounded width from the Scaffold) so the
      // composer's Row/FilledButton receive finite constraints. Only the
      // ListView is wrapped in the RefreshIndicator — putting the composer
      // inside RefreshIndicator gave it unbounded width and froze the screen.
      body: Column(
        children: <Widget>[
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: AnimatedBuilder(
                animation: vm,
                builder: (BuildContext context, Widget? _) {
                  final v = _ensureViewModel();
                  // Use a CustomScrollView so RefreshIndicator always has a
                  // scrollable descendant — even for loading/error/empty
                  // states (which are non-scrollable). Mirrors the feed
                  // screen's pattern.
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: <Widget>[
                      if (v.loading && v.post == null && v.replies.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: LoadingView(message: 'Loading post…'),
                        )
                      else if (v.error != null && v.post == null)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: ErrorView(
                            message: v.error!,
                            onRetry: _onRefresh,
                          ),
                        )
                      else if (v.post == null)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: Icons.help_outline,
                            title: 'Post not found',
                            message: 'This post may have been deleted.',
                          ),
                        )
                      else
                        SliverList.builder(
                          itemCount: v.replies.length + 1,
                          itemBuilder: (BuildContext context, int index) {
                            if (index == 0) {
                              return _PostHeaderCard(post: v.post!);
                            }
                            final ForumReply reply = v.replies[index - 1];
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _ReplyTile(reply: reply),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          AnimatedBuilder(
            animation: vm,
            builder: (BuildContext context, Widget? _) {
              final v = _ensureViewModel();
              if (v.post == null) {
                return const SizedBox.shrink();
              }
              return _ReplyComposer(
                controller: _replyController!,
                sending: v.sending,
                onSend: _onSend,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Header card with the post title, type, author, tags, body, and
/// metadata.
class _PostHeaderCard extends StatelessWidget {
  const _PostHeaderCard({required this.post});

  final ForumPost post;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String authorName = post.author?.fullName ?? 'Unknown author';
    final String? authorRole = post.author?.role;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _PostTypeChip(type: post.type),
                const Spacer(),
                if (post.answered)
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Answered',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    _initials(authorName),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (authorRole != null) ...<Widget>[
                  const SizedBox(width: 8),
                  RoleBadge(role: authorRole),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(post.body, style: theme.textTheme.bodyLarge),
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
                Icon(
                  Icons.thumb_up_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.upvotes} upvotes',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatAbsolute(post.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Replies', style: theme.textTheme.titleMedium),
          ],
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

/// Single reply tile with author, body, upvotes, and timestamp.
class _ReplyTile extends StatelessWidget {
  const _ReplyTile({required this.reply});

  final ForumReply reply;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String authorName = reply.author?.fullName ?? 'Unknown author';
    final String? authorRole = reply.author?.role;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
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
                Expanded(
                  child: Text(
                    authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (authorRole != null) ...<Widget>[
                  const SizedBox(width: 8),
                  RoleBadge(role: authorRole),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(reply.body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Icon(
                  Icons.thumb_up_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text('${reply.upvotes}', style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Text(
                  _formatAbsolute(reply.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
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

/// Chip that identifies the post type.
class _PostTypeChip extends StatelessWidget {
  const _PostTypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final _TypeSpec spec = _specFor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

/// Bottom-pinned reply composer with a multi-line text field and a
/// send button.
class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // A plain Container with a top border separates the composer visually
    // without an elevated `Material`, whose RenderPhysicalModel asserted
    // `hasSize` during the first paint pass. The Scaffold already provides a
    // Material ancestor for the FilledButton's ink ripple.
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(hintText: 'Write a reply…'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
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

/// Returns a YYYY-MM-DD HH:MM timestamp for reply/post metadata.
String _formatAbsolute(DateTime when) {
  final String mm = when.month.toString().padLeft(2, '0');
  final String dd = when.day.toString().padLeft(2, '0');
  final String hh = when.hour.toString().padLeft(2, '0');
  final String mn = when.minute.toString().padLeft(2, '0');
  return '${when.year}-$mm-$dd $hh:$mn';
}
