import 'dart:async';

import 'package:alumni_mentorship_platform/data/models/booking_request.dart';
import 'package:alumni_mentorship_platform/data/models/mentor.dart';
import 'package:alumni_mentorship_platform/data/models/user_profile.dart';
import 'package:alumni_mentorship_platform/data/repositories/mentor_repository.dart';
import 'package:alumni_mentorship_platform/data/repositories/profile_repository.dart';
import 'package:alumni_mentorship_platform/features/auth/view_models/auth_view_model.dart';
import 'package:alumni_mentorship_platform/features/bookings/view_models/booking_list_view_model.dart';
import 'package:alumni_mentorship_platform/shared/providers/app_providers.dart';
import 'package:alumni_mentorship_platform/shared/widgets/empty_state.dart';
import 'package:alumni_mentorship_platform/shared/widgets/error_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/loading_view.dart';
import 'package:alumni_mentorship_platform/shared/widgets/status_pill.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Lists booking requests for the current user. Mentors see incoming
/// requests (`BookingRepository.listForMentor`); students see their own
/// outgoing requests (`BookingRepository.listForStudent`).
class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  BookingListViewModel? _viewModel;
  final Map<String, _Counterparty> _counterpartyCache =
      <String, _Counterparty>{};
  bool _resolvingCounterparties = false;
  AuthViewModel? _auth;
  AppProviders? _providers;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AppProviders providers = AppProviders.of(context);
    final AuthViewModel auth = providers.authViewModel;
    if (_viewModel == null) {
      _providers = providers;
      _auth = auth;
      _viewModel = BookingListViewModel(
        isMentor: auth.isMentor,
        currentUserId: auth.profile?.id,
        bookingRepository: providers.bookingRepository,
      );
      _viewModel!.addListener(_onViewModelChanged);
      unawaited(_refresh());
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelChanged);
    _viewModel?.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (_viewModel?.bookings.isEmpty ?? true) {
      return;
    }
    unawaited(_ensureCounterparties());
  }

  Future<void> _refresh() async {
    final BookingListViewModel? vm = _viewModel;
    if (vm == null) {
      return;
    }
    await vm.refresh();
  }

  Future<void> _ensureCounterparties() async {
    if (_resolvingCounterparties) {
      return;
    }
    final AppProviders? providers = _providers;
    final BookingListViewModel? vm = _viewModel;
    if (providers == null || vm == null) {
      return;
    }
    final MentorRepository mentorRepo = providers.mentorRepository;
    final ProfileRepository profileRepo = providers.profileRepository;
    final AuthViewModel auth = providers.authViewModel;

    final List<BookingRequest> bookings = vm.bookings;
    final List<String> missing = <String>[];
    for (final BookingRequest b in bookings) {
      final String id = vm.isMentor ? b.studentId : b.mentorId;
      if (!_counterpartyCache.containsKey(id)) {
        missing.add(id);
      }
    }
    if (missing.isEmpty) {
      return;
    }
    _resolvingCounterparties = true;
    try {
      for (final String id in missing) {
        if (vm.isMentor) {
          final UserProfile? profile = await profileRepo.fetchById(id);
          _counterpartyCache[id] = _Counterparty(
            name: profile?.fullName ?? 'Student',
            role: profile?.role ?? 'student',
          );
        } else {
          final Mentor? mentor = await mentorRepo.fetchById(id);
          _counterpartyCache[id] = _Counterparty(
            name: mentor?.profile?.fullName ?? 'Mentor',
            role: 'alumni',
          );
        }
      }
      _counterpartyCache['__currentUser'] = _Counterparty(
        name: auth.profile?.fullName ?? 'You',
        role: auth.profile?.role ?? 'student',
      );
      if (mounted) {
        setState(() {});
      }
    } on Object catch (_) {
      // Soft-fail: cards fall back to a generic label.
    } finally {
      _resolvingCounterparties = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthViewModel auth = _auth ?? AppProviders.of(context).authViewModel;
    final BookingListViewModel? vm = _viewModel;

    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: <Widget>[
                Icon(
                  (vm?.isMentor ?? auth.isMentor)
                      ? Icons.inbox_outlined
                      : Icons.send_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  (vm?.isMentor ?? auth.isMentor)
                      ? 'Incoming Requests'
                      : 'My Requests',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: vm == null
                ? const LoadingView()
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: AnimatedBuilder(
                      animation: vm,
                      builder: (BuildContext context, Widget? _) {
                        if (vm.loading && vm.bookings.isEmpty) {
                          return const LoadingView(
                            message: 'Loading bookings…',
                          );
                        }
                        if (vm.error != null) {
                          return ErrorView(
                            message: vm.error!,
                            onRetry: _refresh,
                          );
                        }
                        if (vm.bookings.isEmpty) {
                          return EmptyState(
                            icon: vm.isMentor
                                ? Icons.inbox_outlined
                                : Icons.event_outlined,
                            title: vm.isMentor
                                ? 'No incoming requests'
                                : 'No requests yet',
                            message: vm.isMentor
                                ? 'When students book a session with you, it will appear here.'
                                : 'Browse the mentor directory to start your first session.',
                            action: vm.isMentor
                                ? null
                                : FilledButton.icon(
                                    onPressed: () => context.go('/mentors'),
                                    icon: const Icon(Icons.search),
                                    label: const Text('Browse mentors'),
                                  ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: vm.bookings.length,
                          itemBuilder: (BuildContext context, int index) {
                            final BookingRequest b = vm.bookings[index];
                            final String counterpartyId = vm.isMentor
                                ? b.studentId
                                : b.mentorId;
                            final _Counterparty? cp =
                                _counterpartyCache[counterpartyId];
                            return _BookingCard(
                              booking: b,
                              isMentor: vm.isMentor,
                              counterpartyName: cp?.name,
                              onTap: () => context.go('/bookings/${b.id}'),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.isMentor,
    required this.counterpartyName,
    required this.onTap,
  });

  final BookingRequest booking;
  final bool isMentor;
  final String? counterpartyName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
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
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(status: booking.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Icon(
                    isMentor
                        ? Icons.school_outlined
                        : Icons.workspace_premium_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      counterpartyName ?? 'Loading…',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(booking.preferredAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Created ${_formatDate(booking.createdAt)}',
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
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) {
      return 'No preferred time';
    }
    final DateTime local = dt.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _Counterparty {
  const _Counterparty({required this.name, required this.role});
  final String name;
  final String role;
}
