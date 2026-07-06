import 'package:alumni_mentorship_platform/core/theme/app_theme.dart';
import 'package:alumni_mentorship_platform/features/auth/view_models/auth_view_model.dart';
import 'package:alumni_mentorship_platform/features/auth/views/widgets/auth_brand_panel.dart';
import 'package:alumni_mentorship_platform/features/auth/views/widgets/form_error_banner.dart';
import 'package:alumni_mentorship_platform/shared/providers/app_providers.dart';
import 'package:alumni_mentorship_platform/shared/widgets/grain_overlay.dart';
import 'package:alumni_mentorship_platform/shared/widgets/nalum_logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Registration screen with full name, email, password, and a role picker
/// (student vs alumni). On success the router sends the user to /dashboard.
///
/// Responsive: a single-column form on mobile, and a 55/45 brand-panel +
/// form split on desktop (≥720px), matching the Stitch designs.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _role = 'student';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final AuthViewModel auth = AppProviders.of(context).authViewModel;
    final bool ok = await auth.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      role: _role,
    );
    if (ok && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthViewModel auth = AppProviders.of(context).authViewModel;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool wide = constraints.maxWidth >= 720;
              final Widget form = _buildForm(context, auth, theme, wide);
              if (wide) {
                return Row(
                  children: <Widget>[
                    Expanded(
                      flex: 55,
                      child: AuthBrandPanel(
                        hero: 'Become part of the network.',
                        subtitle: 'Students find mentors. Alumni give back.',
                        bullets: const <AuthTrustBullet>[
                          AuthTrustBullet(
                            icon: Icons.school_outlined,
                            label: 'Academic Guidance',
                            subtitle:
                                'Navigate your career path with expert help.',
                          ),
                          AuthTrustBullet(
                            icon: Icons.handshake_outlined,
                            label: 'Professional Networking',
                            subtitle:
                                'Connect with established industry leaders.',
                          ),
                          AuthTrustBullet(
                            icon: Icons.forum_outlined,
                            label: 'Insightful Discussions',
                            subtitle: 'Engage in high-value alumni forums.',
                          ),
                        ],
                      ),
                    ),
                    Expanded(flex: 45, child: form),
                  ],
                );
              }
              return form;
            },
          ),
          const Positioned.fill(child: GrainOverlay()),
        ],
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AuthViewModel auth,
    ThemeData theme,
    bool wide,
  ) {
    final TextTheme text = theme.textTheme;
    final ColorScheme colors = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, wide ? 32 : 16, 24, wide ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/login'),
                style: IconButton.styleFrom(
                  backgroundColor: colors.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Center(
                            child: wide
                                ? Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colors.outlineVariant,
                                      ),
                                    ),
                                    child: const NalumLogo(size: 40),
                                  )
                                : const NalumLogo(size: 56),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Create your account',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              textStyle: text.headlineMedium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.headline,
                              fontSize: 30,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Join the alumni mentorship community',
                            textAlign: TextAlign.center,
                            style: text.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const <String>[AutofillHints.name],
                            decoration: _fieldDecoration(
                              theme: theme,
                              wide: wide,
                              label: 'Full name',
                              hint: wide ? 'Sarah Chen' : 'Full name',
                              icon: Icons.person_outline,
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Full name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const <String>[AutofillHints.email],
                            decoration: _fieldDecoration(
                              theme: theme,
                              wide: wide,
                              label: 'Email',
                              hint: wide
                                  ? 'sarah.chen@university.edu'
                                  : 'Email',
                              icon: Icons.mail_outline,
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const <String>[
                              AutofillHints.newPassword,
                            ],
                            decoration: _fieldDecoration(
                              theme: theme,
                              wide: wide,
                              label: 'Password',
                              hint: wide ? '••••••••' : 'Password',
                              icon: Icons.lock_outline,
                              helper: wide ? null : 'At least 6 characters',
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          if (wide) ...<Widget>[
                            const SizedBox(height: 2),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'At least 6 characters',
                                style: text.labelSmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            'I am a…',
                            style: text.labelLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const <ButtonSegment<String>>[
                              ButtonSegment<String>(
                                value: 'student',
                                label: Text('Student'),
                                icon: Icon(Icons.school_outlined),
                              ),
                              ButtonSegment<String>(
                                value: 'alumni',
                                label: Text('Alumni'),
                                icon: Icon(Icons.workspace_premium_outlined),
                              ),
                            ],
                            selected: <String>{_role},
                            onSelectionChanged: (Set<String> selection) {
                              setState(() => _role = selection.first);
                            },
                          ),
                          if (auth.error != null) ...<Widget>[
                            const SizedBox(height: 16),
                            FormErrorBanner(message: auth.error!),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: auth.loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              shadowColor: colors.primary.withValues(
                                alpha: 0.25,
                              ),
                            ),
                            child: auth.loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Create account'),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/login'),
                              style: TextButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: text.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                  children: const <InlineSpan>[
                                    TextSpan(text: 'Already have an account? '),
                                    TextSpan(
                                      text: 'Sign in',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (wide) ...<Widget>[
                            const SizedBox(height: 16),
                            Text(
                              'By creating an account, you agree to our Terms '
                              'of Service and Privacy Policy.',
                              textAlign: TextAlign.center,
                              style: text.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required ThemeData theme,
    required bool wide,
    required String label,
    required String hint,
    required IconData icon,
    String? helper,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: wide ? label : null,
      hintText: wide ? null : hint,
      helperText: helper,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
    );
  }
}
