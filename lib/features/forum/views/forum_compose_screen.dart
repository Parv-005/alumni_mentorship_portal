import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/features/forum/view_models/forum_compose_view_model.dart';
import 'package:alumni_mentorship_platform/shared/providers/app_providers.dart';
import 'package:alumni_mentorship_platform/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Compose form for a new forum post. Holds fields for type, title, body,
/// and tags, and submits via [ForumComposeViewModel].
class ForumComposeScreen extends StatefulWidget {
  const ForumComposeScreen({super.key});

  @override
  State<ForumComposeScreen> createState() => _ForumComposeScreenState();
}

class _ForumComposeScreenState extends State<ForumComposeScreen> {
  ForumComposeViewModel? _viewModel;
  TextEditingController? _titleController;
  TextEditingController? _bodyController;
  TextEditingController? _tagsController;

  @override
  void dispose() {
    _titleController?.dispose();
    _bodyController?.dispose();
    _tagsController?.dispose();
    _viewModel?.dispose();
    super.dispose();
  }

  ForumComposeViewModel _ensureViewModel() {
    if (_viewModel == null) {
      _viewModel = ForumComposeViewModel(
        forumRepository: AppProviders.of(context).forumRepository,
      );
      _titleController = TextEditingController(text: _viewModel!.title);
      _bodyController = TextEditingController(text: _viewModel!.body);
      _tagsController = TextEditingController(text: _viewModel!.tagsText);
      developer.log('ForumComposeScreen init', name: 'ForumComposeScreen');
    }
    return _viewModel!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureViewModel();
  }

  Future<void> _onSubmit() async {
    final vm = _ensureViewModel();
    final bool ok = await vm.submit();
    if (!mounted) {
      return;
    }
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Posted')));
      context.go('/forum');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = _ensureViewModel();
    return Scaffold(
      appBar: AppBar(
        title: const Text('New post'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/forum'),
        ),
      ),
      body: AnimatedBuilder(
        animation: vm,
        builder: (BuildContext context, Widget? _) {
          if (vm.error != null && !vm.loading) {
            return ErrorView(message: vm.error!, onRetry: _onSubmit);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Type', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _TypeChoiceBar(selected: vm.type, onSelected: vm.setType),
                const SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'What is your post about?',
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: vm.setTitle,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Body',
                    hintText: 'Share the details…',
                    alignLabelWithHint: true,
                  ),
                  minLines: 5,
                  maxLines: 12,
                  onChanged: vm.setBody,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    hintText: 'comma, separated, tags',
                  ),
                  onChanged: vm.setTagsText,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: vm.loading || !vm.isValid ? null : _onSubmit,
                  icon: vm.loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Post'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Row of choice chips that drive the selected post type.
class _TypeChoiceBar extends StatelessWidget {
  const _TypeChoiceBar({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: ForumComposeViewModel.kTypes
          .map(
            (String type) => ChoiceChip(
              label: Text(ForumComposeViewModel.kTypeLabels[type] ?? type),
              selected: selected == type,
              onSelected: (_) => onSelected(type),
            ),
          )
          .toList(growable: false),
    );
  }
}
