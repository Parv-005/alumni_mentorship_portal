import 'package:alumni_mentorship_platform/core/router/app_router.dart';
import 'package:alumni_mentorship_platform/core/theme/app_theme.dart';
import 'package:alumni_mentorship_platform/data/repositories/auth_repository.dart';
import 'package:alumni_mentorship_platform/data/repositories/booking_repository.dart';
import 'package:alumni_mentorship_platform/data/repositories/forum_repository.dart';
import 'package:alumni_mentorship_platform/data/repositories/mentor_repository.dart';
import 'package:alumni_mentorship_platform/data/repositories/profile_repository.dart';
import 'package:alumni_mentorship_platform/features/auth/view_models/auth_view_model.dart';
import 'package:alumni_mentorship_platform/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The application root widget. Wires the [AuthViewModel] and repositories
/// into the widget tree through an [AppProviders] inherited notifier, and
/// configures the [MaterialApp.router] with the platform theme.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final AuthViewModel _authViewModel;
  late final AppProviders _providers;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel();
    _providers = AppProviders(
      authViewModel: _authViewModel,
      authRepository: const AuthRepository(),
      profileRepository: const ProfileRepository(),
      mentorRepository: const MentorRepository(),
      bookingRepository: const BookingRepository(),
      forumRepository: const ForumRepository(),
      child: const SizedBox.shrink(),
    );
    _router = buildRouter(_providers);
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _providers.copyWith(
      child: MaterialApp.router(
        title: 'Alumni Mentorship Platform',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}
