import 'dart:async';

import 'package:alumni_mentorship_platform/data/models/mentor.dart';
import 'package:alumni_mentorship_platform/features/bookings/view_models/booking_request_view_model.dart';
import 'package:alumni_mentorship_platform/shared/providers/app_providers.dart';
import 'package:alumni_mentorship_platform/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Form screen used by a student to request a session with a specific
/// [mentorId]. Loads the mentor for the header label, then collects topic,
/// session type, preferred date/time, and an optional message before
/// delegating submission to [BookingRequestViewModel].
class BookingRequestScreen extends StatefulWidget {
  const BookingRequestScreen({super.key, required this.mentorId});

  final String mentorId;

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  BookingRequestViewModel? _viewModel;
  TextEditingController? _topicController;
  TextEditingController? _messageController;

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelChanged);
    _topicController?.dispose();
    _messageController?.dispose();
    _viewModel?.dispose();
    super.dispose();
  }

  BookingRequestViewModel _ensureViewModel() {
    if (_viewModel == null) {
      final providers = AppProviders.of(context);
      _viewModel = BookingRequestViewModel(
        mentorId: widget.mentorId,
        bookingRepository: providers.bookingRepository,
        mentorRepository: providers.mentorRepository,
      );
      _topicController = TextEditingController();
      _messageController = TextEditingController();
      _viewModel!.addListener(_onViewModelChanged);
    }
    return _viewModel!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureViewModel();
  }

  void _onViewModelChanged() {
    final vm = _viewModel;
    if (vm != null && vm.success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request sent')));
      context.go('/bookings');
    }
  }

  Future<void> _pickPreferredAt() async {
    final vm = _ensureViewModel();
    final DateTime now = DateTime.now();
    final DateTime initial = vm.preferredAt ?? now.add(const Duration(days: 1));
    final DateTime firstDate = DateTime(now.year, now.month, now.day);
    final DateTime lastDate = now.add(const Duration(days: 365));

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null || !mounted) {
      return;
    }
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(vm.preferredAt ?? date),
    );
    if (time == null) {
      vm.setPreferredAt(date);
      return;
    }
    vm.setPreferredAt(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Request Session')),
      body: AnimatedBuilder(
        animation: _ensureViewModel(),
        builder: (BuildContext context, Widget? _) {
          final vm = _ensureViewModel();
          if (vm.mentorLoading) {
            return const LoadingView(message: 'Loading mentor…');
          }
          return _RequestForm(
            viewModel: vm,
            topicController: _topicController!,
            messageController: _messageController!,
            theme: theme,
            mentor: vm.mentor,
            mentorError: vm.mentorError,
            onPickDate: _pickPreferredAt,
          );
        },
      ),
    );
  }
}

class _RequestForm extends StatelessWidget {
  const _RequestForm({
    required this.viewModel,
    required this.topicController,
    required this.messageController,
    required this.theme,
    required this.mentor,
    required this.mentorError,
    required this.onPickDate,
  });

  final BookingRequestViewModel viewModel;
  final TextEditingController topicController;
  final TextEditingController messageController;
  final ThemeData theme;
  final Mentor? mentor;
  final String? mentorError;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _MentorHeader(mentor: mentor, error: mentorError, theme: theme),
          const SizedBox(height: 24),
          Text('Topic', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: topicController,
            onChanged: viewModel.setTopic,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'What do you want to discuss?',
            ),
          ),
          const SizedBox(height: 20),
          Text('Session type', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _SessionTypeChips(
            selected: viewModel.sessionType,
            onChanged: viewModel.setSessionType,
          ),
          const SizedBox(height: 20),
          Text('Preferred date & time', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _PreferredAtTile(
            value: viewModel.preferredAt,
            onTap: onPickDate,
            onClear: () => viewModel.setPreferredAt(null),
          ),
          const SizedBox(height: 20),
          Text('Message (optional)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: messageController,
            onChanged: viewModel.setMessage,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share any context that would help the mentor prepare',
            ),
          ),
          const SizedBox(height: 24),
          if (viewModel.submitError != null) ...<Widget>[
            _ErrorBanner(message: viewModel.submitError!),
            const SizedBox(height: 16),
          ],
          FilledButton.icon(
            onPressed: viewModel.canSubmit
                ? () => unawaited(viewModel.submit())
                : null,
            icon: viewModel.submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(viewModel.submitting ? 'Sending…' : 'Send Request'),
          ),
        ],
      ),
    );
  }
}

class _MentorHeader extends StatelessWidget {
  const _MentorHeader({
    required this.mentor,
    required this.error,
    required this.theme,
  });

  final Mentor? mentor;
  final String? error;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (mentor == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error ?? 'Mentor unavailable',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                _initials(mentor!.profile?.fullName),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    mentor!.profile?.fullName ?? 'Mentor',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mentor!.domain,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) {
      return '?';
    }
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _SessionTypeChips extends StatelessWidget {
  const _SessionTypeChips({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  static const Map<String, _SessionTypeSpec>
  _specs = <String, _SessionTypeSpec>{
    'video': _SessionTypeSpec(label: 'Video', icon: Icons.videocam_outlined),
    'in_person': _SessionTypeSpec(
      label: 'In-person',
      icon: Icons.location_on_outlined,
    ),
    'async': _SessionTypeSpec(label: 'Async', icon: Icons.chat_bubble_outline),
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kSessionTypes
          .map((String value) {
            final _SessionTypeSpec spec = _specs[value]!;
            final bool isSelected = value == selected;
            return ChoiceChip(
              label: Text(spec.label),
              avatar: Icon(spec.icon, size: 18),
              selected: isSelected,
              onSelected: (bool yes) {
                if (yes) {
                  onChanged(value);
                }
              },
            );
          })
          .toList(growable: false),
    );
  }
}

class _SessionTypeSpec {
  const _SessionTypeSpec({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

class _PreferredAtTile extends StatelessWidget {
  const _PreferredAtTile({
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.event_outlined),
        title: Text(
          value == null ? 'Pick a date & time' : _format(value!),
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: value == null
            ? Text(
                'Optional',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: value == null
            ? const Icon(Icons.chevron_right)
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClear,
                tooltip: 'Clear',
              ),
      ),
    );
  }

  String _format(DateTime dt) {
    final DateTime local = dt.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d · $hh:$mm';
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
