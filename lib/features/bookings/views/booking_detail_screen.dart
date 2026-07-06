import 'dart:async';

import 'package:alumni_mentorship_platform/data/models/booking_request.dart';
import 'package:alumni_mentorship_platform/data/models/mentor.dart';
import 'package:alumni_mentorship_platform/data/models/user_profile.dart';
import 'package:alumni_mentorship_platform/features/auth/view_models/auth_view_model.dart';
import 'package:alumni_mentorship_platform/features/bookings/view_models/booking_detail_view_model.dart';
import 'package:alumni_mentorship_platform/shared/providers/app_providers.dart';
import 'package:alumni_mentorship_platform/shared/widgets/error_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/loading_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/role_badge.dart';
import 'package:alumni_mentorship_platform/shared/widgets/status_pill.dart';
import 'package:flutter/material.dart';

/// Shows a single booking request. Renders a status timeline, all the
/// request metadata, the other party's name + role, and (for mentors) the
/// accept / decline / mark-completed actions appropriate to the current
/// status.
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  BookingDetailViewModel? _viewModel;
  AuthViewModel? _auth;
  String? _loadedBookingId;
  bool _loaded = false;

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  BookingDetailViewModel _ensureViewModel() {
    if (_viewModel == null) {
      final providers = AppProviders.of(context);
      _viewModel = BookingDetailViewModel(
        bookingId: widget.bookingId,
        bookingRepository: providers.bookingRepository,
        mentorRepository: providers.mentorRepository,
        profileRepository: providers.profileRepository,
      );
    }
    return _viewModel!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final providers = AppProviders.of(context);
    _auth = providers.authViewModel;
    final vm = _ensureViewModel();
    if (!_loaded || _loadedBookingId != widget.bookingId) {
      _loaded = true;
      _loadedBookingId = widget.bookingId;
      unawaited(vm.load());
    }
  }

  Future<void> _changeStatus(String newStatus, String successMessage) async {
    final vm = _ensureViewModel();
    final bool ok = await vm.updateStatus(newStatus);
    if (!mounted) {
      return;
    }
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } else if (vm.updateError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(vm.updateError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: AnimatedBuilder(
        animation: _ensureViewModel(),
        builder: (BuildContext context, Widget? _) {
          final vm = _ensureViewModel();
          if (vm.loading && vm.booking == null) {
            return const LoadingView(message: 'Loading booking…');
          }
          if (vm.error != null) {
            return ErrorView(
              message: vm.error!,
              onRetry: () => unawaited(vm.load()),
            );
          }
          final BookingRequest? booking = vm.booking;
          if (booking == null) {
            return const ErrorView(message: 'Booking not found');
          }
          return _DetailBody(
            theme: theme,
            booking: booking,
            mentor: vm.mentor,
            student: vm.student,
            viewerIsMentor: _auth?.isMentor ?? false,
            viewerIsStudent: booking.studentId == _auth?.profile?.id,
            updating: vm.updating,
            onAccept: () => _changeStatus('accepted', 'Request accepted'),
            onDecline: () => _changeStatus('declined', 'Request declined'),
            onComplete: () => _changeStatus('completed', 'Marked completed'),
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.theme,
    required this.booking,
    required this.mentor,
    required this.student,
    required this.viewerIsMentor,
    required this.viewerIsStudent,
    required this.updating,
    required this.onAccept,
    required this.onDecline,
    required this.onComplete,
  });

  final ThemeData theme;
  final BookingRequest booking;
  final Mentor? mentor;
  final UserProfile? student;
  final bool viewerIsMentor;
  final bool viewerIsStudent;
  final bool updating;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final _CounterpartyInfo counterparty = _counterparty();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        booking.topic,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(status: booking.status),
                  ],
                ),
                const SizedBox(height: 8),
                _MetadataRow(
                  icon: Icons.swap_horiz,
                  label: 'Session type',
                  value: _sessionTypeLabel(booking.sessionType),
                ),
                const SizedBox(height: 4),
                _MetadataRow(
                  icon: Icons.event_outlined,
                  label: 'Preferred time',
                  value: _formatDateTime(booking.preferredAt),
                ),
                if (booking.message.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text('Message', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking.message,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    _initials(counterparty.name),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        counterparty.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          RoleBadge(role: counterparty.role),
                          const SizedBox(width: 8),
                          Text(
                            counterparty.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Status timeline', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                _StatusTimeline(booking: booking),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ..._buildActions(context),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (!viewerIsMentor || updating) {
      if (updating) {
        return <Widget>[const Center(child: CircularProgressIndicator())];
      }
      return const <Widget>[];
    }
    switch (booking.status) {
      case 'pending':
        return <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDecline,
                  icon: const Icon(Icons.close),
                  label: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check),
                  label: const Text('Accept'),
                ),
              ),
            ],
          ),
        ];
      case 'accepted':
        return <Widget>[
          FilledButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Mark Completed'),
          ),
        ];
      default:
        return const <Widget>[];
    }
  }

  _CounterpartyInfo _counterparty() {
    if (viewerIsStudent) {
      return _CounterpartyInfo(
        name: mentor?.profile?.fullName ?? 'Mentor',
        role: 'alumni',
        subtitle: mentor?.domain ?? 'Mentor',
      );
    }
    return _CounterpartyInfo(
      name: student?.fullName ?? 'Student',
      role: student?.role ?? 'student',
      subtitle: student?.program ?? 'Student',
    );
  }
}

class _CounterpartyInfo {
  const _CounterpartyInfo({
    required this.name,
    required this.role,
    required this.subtitle,
  });
  final String name;
  final String role;
  final String subtitle;
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.booking});

  final BookingRequest booking;

  @override
  Widget build(BuildContext context) {
    final List<_TimelineStep> steps = _steps(booking);
    return Column(
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          _TimelineStepWidget(step: steps[i], isLast: i == steps.length - 1),
      ],
    );
  }

  List<_TimelineStep> _steps(BookingRequest b) {
    final DateTime updated = b.updatedAt;
    final int? updatedToIndex = _activeIndexFor(b.status);
    return <_TimelineStep>[
      _TimelineStep(
        label: 'Requested',
        timestamp: b.createdAt,
        isActive: true,
        isCompleted: true,
        description: 'Student sent the request',
      ),
      _TimelineStep(
        label: b.status == 'declined' ? 'Declined' : 'Accepted',
        timestamp: updatedToIndex != null && updatedToIndex >= 1
            ? updated
            : null,
        isActive: updatedToIndex != null && updatedToIndex >= 1,
        isCompleted: updatedToIndex != null && updatedToIndex >= 1,
        description: b.status == 'declined'
            ? 'Mentor declined the request'
            : 'Mentor accepted the request',
      ),
      _TimelineStep(
        label: 'Completed',
        timestamp: updatedToIndex != null && updatedToIndex >= 2
            ? updated
            : null,
        isActive: updatedToIndex != null && updatedToIndex >= 2,
        isCompleted: updatedToIndex != null && updatedToIndex >= 2,
        description: 'Session marked complete',
      ),
    ];
  }

  int? _activeIndexFor(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'accepted':
      case 'rescheduled':
      case 'declined':
        return 1;
      case 'completed':
        return 2;
      default:
        return 0;
    }
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.label,
    required this.timestamp,
    required this.isActive,
    required this.isCompleted,
    required this.description,
  });
  final String label;
  final DateTime? timestamp;
  final bool isActive;
  final bool isCompleted;
  final String description;
}

class _TimelineStepWidget extends StatelessWidget {
  const _TimelineStepWidget({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color circleColor = step.isCompleted
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final Color textColor = step.isActive
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: step.isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
                child: step.isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: step.isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    step.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: textColor,
                      fontWeight: step.isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (step.timestamp != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      _formatTimestamp(step.timestamp!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final DateTime local = dt.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d · $hh:$mm';
  }
}

String _sessionTypeLabel(String value) {
  switch (value) {
    case 'video':
      return 'Video call';
    case 'in_person':
      return 'In-person';
    case 'async':
      return 'Async (chat)';
    default:
      return value;
  }
}

String _formatDateTime(DateTime? dt) {
  if (dt == null) {
    return 'Not specified';
  }
  final DateTime local = dt.toLocal();
  final String y = local.year.toString().padLeft(4, '0');
  final String m = local.month.toString().padLeft(2, '0');
  final String d = local.day.toString().padLeft(2, '0');
  final String hh = local.hour.toString().padLeft(2, '0');
  final String mm = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d · $hh:$mm';
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
