import 'package:alumni_mentorship_platform/data/repositories/auth_repository.dart';
import 'package:alumni_mentorship_platform/data/repositories/booking_repository.dart';
import 'package:alumni_mentorship_platform/data/repositories/forum_repository.dart';
import 'package:alumni_mentorship_platform/data/repositories/mentor_repository.dart';
import 'package:alumni_mentorship_platform/data/repositories/profile_repository.dart';
import 'package:alumni_mentorship_platform/features/auth/view_models/auth_view_model.dart';
import 'package:flutter/widgets.dart';

/// Inherited widget that exposes the singleton [AuthViewModel] and the
/// repositories to the widget tree. The router and all screens read auth
/// state and call repository methods through these providers.
class AppProviders extends InheritedNotifier<AuthViewModel> {
  const AppProviders({
    super.key,
    required this.authViewModel,
    required this.authRepository,
    required this.profileRepository,
    required this.mentorRepository,
    required this.bookingRepository,
    required this.forumRepository,
    required super.child,
  });

  final AuthViewModel authViewModel;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final MentorRepository mentorRepository;
  final BookingRepository bookingRepository;
  final ForumRepository forumRepository;

  static AppProviders of(BuildContext context) {
    final AppProviders? result = context
        .dependOnInheritedWidgetOfExactType<AppProviders>();
    assert(result != null, 'AppProviders not found in widget tree');
    return result!;
  }

  /// Returns a copy of this provider with a different [child]. Useful for
  /// hoisting the provider to wrap a real subtree after a placeholder.
  AppProviders copyWith({required Widget child}) {
    return AppProviders(
      authViewModel: authViewModel,
      authRepository: authRepository,
      profileRepository: profileRepository,
      mentorRepository: mentorRepository,
      bookingRepository: bookingRepository,
      forumRepository: forumRepository,
      child: child,
    );
  }
}
