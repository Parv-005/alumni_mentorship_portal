import 'package:alumni_mentorship_platform/features/mentors/view_models/mentor_editor_view_model.dart';
import 'package:alumni_mentorship_platform/shared/providers/app_providers.dart';
import 'package:alumni_mentorship_platform/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Form for creating or editing the current user's mentor profile.
class MentorProfileEditorScreen extends StatefulWidget {
  const MentorProfileEditorScreen({super.key});

  @override
  State<MentorProfileEditorScreen> createState() =>
      _MentorProfileEditorScreenState();
}

class _MentorProfileEditorScreenState extends State<MentorProfileEditorScreen> {
  MentorEditorViewModel? _viewModel;
  TextEditingController? _domainController;
  TextEditingController? _experienceController;
  TextEditingController? _bioController;
  TextEditingController? _skillsController;
  TextEditingController? _linkedinController;
  bool _loaded = false;

  @override
  void dispose() {
    final vm = _viewModel;
    if (vm != null) {
      vm.removeListener(_syncControllers);
    }
    _domainController?.dispose();
    _experienceController?.dispose();
    _bioController?.dispose();
    _skillsController?.dispose();
    _linkedinController?.dispose();
    _viewModel?.dispose();
    super.dispose();
  }

  MentorEditorViewModel _ensureViewModel() {
    if (_viewModel == null) {
      _viewModel = MentorEditorViewModel(
        mentorRepository: AppProviders.of(context).mentorRepository,
      );
      _domainController = TextEditingController();
      _experienceController = TextEditingController();
      _bioController = TextEditingController();
      _skillsController = TextEditingController();
      _linkedinController = TextEditingController();
      _viewModel!.addListener(_syncControllers);
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

  void _syncControllers() {
    final vm = _viewModel;
    if (vm == null) {
      return;
    }
    final domain = _domainController;
    final experience = _experienceController;
    final bio = _bioController;
    final skills = _skillsController;
    final linkedin = _linkedinController;
    if (domain == null ||
        experience == null ||
        bio == null ||
        skills == null ||
        linkedin == null) {
      return;
    }
    if (domain.text != vm.domain) {
      domain.text = vm.domain;
    }
    final String years = vm.experienceYears.toString();
    if (experience.text != years) {
      experience.text = years;
    }
    if (bio.text != vm.bio) {
      bio.text = vm.bio;
    }
    if (skills.text != vm.skillsText) {
      skills.text = vm.skillsText;
    }
    if (linkedin.text != vm.linkedinUrl) {
      linkedin.text = vm.linkedinUrl;
    }
  }

  Future<void> _onSave() async {
    final vm = _ensureViewModel();
    final result = await vm.save();
    if (!mounted) {
      return;
    }
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mentor profile saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/mentors');
    } else if (vm.validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.validationError!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: ${vm.error}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = _ensureViewModel();
    return Scaffold(
      appBar: AppBar(
        title: Text(vm.hasExisting ? 'Edit mentor profile' : 'Become a mentor'),
      ),
      body: AnimatedBuilder(
        animation: vm,
        builder: (BuildContext context, Widget? _) {
          if (vm.loading) {
            return const LoadingView(message: 'Loading profile…');
          }
          return _EditorForm(
            viewModel: vm,
            domainController: _domainController!,
            experienceController: _experienceController!,
            bioController: _bioController!,
            skillsController: _skillsController!,
            linkedinController: _linkedinController!,
            onSave: _onSave,
          );
        },
      ),
    );
  }
}

/// Stateless body of the editor. Holds the form fields, segmented
/// availability selector, and the save button.
class _EditorForm extends StatelessWidget {
  const _EditorForm({
    required this.viewModel,
    required this.domainController,
    required this.experienceController,
    required this.bioController,
    required this.skillsController,
    required this.linkedinController,
    required this.onSave,
  });

  final MentorEditorViewModel viewModel;
  final TextEditingController domainController;
  final TextEditingController experienceController;
  final TextEditingController bioController;
  final TextEditingController skillsController;
  final TextEditingController linkedinController;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        Text('Tell students about yourself', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Share your domain, experience, and the topics you can help with.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: domainController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Domain',
            hintText: 'e.g. Engineering',
          ),
          onChanged: viewModel.setDomain,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: experienceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Years of experience',
            hintText: '0',
          ),
          onChanged: (String value) {
            final int parsed = int.tryParse(value) ?? 0;
            viewModel.setExperienceYears(parsed);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: bioController,
          maxLines: 5,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Bio',
            hintText: 'What can you help students with?',
            alignLabelWithHint: true,
          ),
          onChanged: viewModel.setBio,
        ),
        const SizedBox(height: 20),
        Text('Availability', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _AvailabilitySelector(viewModel: viewModel),
        const SizedBox(height: 20),
        TextField(
          controller: skillsController,
          decoration: const InputDecoration(
            labelText: 'Skills',
            hintText: 'e.g. Dart, System Design, Career (comma separated)',
          ),
          onChanged: viewModel.setSkillsText,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: linkedinController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'LinkedIn URL (optional)',
            hintText: 'https://www.linkedin.com/in/...',
          ),
          onChanged: viewModel.setLinkedinUrl,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: viewModel.saving ? null : onSave,
          icon: viewModel.saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(viewModel.saving ? 'Saving…' : 'Save profile'),
        ),
      ],
    );
  }
}

/// Segmented control for the three availability values.
class _AvailabilitySelector extends StatelessWidget {
  const _AvailabilitySelector({required this.viewModel});

  final MentorEditorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const <ButtonSegment<String>>[
        ButtonSegment<String>(
          value: 'accepting',
          label: Text('Accepting'),
          icon: Icon(Icons.event_available),
        ),
        ButtonSegment<String>(
          value: 'booked',
          label: Text('Booked'),
          icon: Icon(Icons.event_busy),
        ),
        ButtonSegment<String>(
          value: 'break',
          label: Text('On break'),
          icon: Icon(Icons.pause_circle_outline),
        ),
      ],
      selected: <String>{viewModel.availability},
      onSelectionChanged: (Set<String> selection) {
        if (selection.isEmpty) {
          return;
        }
        viewModel.setAvailability(selection.first);
      },
    );
  }
}
