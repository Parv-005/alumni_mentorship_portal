import 'package:alumni_mentorship_platform/features/auth/view_models/auth_view_model.dart';
import 'package:alumni_mentorship_platform/shared/providers/app_providers.dart';
import 'package:alumni_mentorship_platform/shared/widgets/role_badge.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Profile screen. Shows the current user's profile fields and a sign-out
/// button. The full profile editor will be added by a later feature agent.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthViewModel auth = AppProviders.of(context).authViewModel;
    final ThemeData theme = Theme.of(context);
    final profile = auth.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (profile == null)
              const Center(child: CircularProgressIndicator())
            else ...<Widget>[
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: profile.avatarUrl != null
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.headlineMedium,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  profile.fullName.isEmpty ? '(no name)' : profile.fullName,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  profile.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: RoleBadge(role: profile.role)),
              const SizedBox(height: 32),
              Card(
                child: Column(
                  children: <Widget>[
                    _ProfileTile(
                      icon: Icons.school_outlined,
                      label: 'Program',
                      value: profile.program ?? '—',
                    ),
                    const Divider(height: 1),
                    _ProfileTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Graduation year',
                      value: profile.graduationYear?.toString() ?? '—',
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: auth.loading
                  ? null
                  : () async {
                      await auth.signOut();
                      if (context.mounted) context.go('/login');
                    },
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
