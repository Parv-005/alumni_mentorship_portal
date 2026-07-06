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

/// Email + password sign-in screen. Redirects to the dashboard on success.
///
/// Responsive: a centered single-column form on mobile, and a 55/45 teal
/// brand-panel + form split on desktop (≥720px), matching the Stitch designs.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final AuthViewModel auth = AppProviders.of(context).authViewModel;
    final bool ok = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (ok && mounted) {
      context.go('/dashboard');
    }
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is not available yet.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
                        hero: 'Mentorship that lasts beyond graduation.',
                        subtitle:
                            'Connect with alumni who have been where you are '
                            'heading. Build lifelong professional networks '
                            'and gain real-world insights.',
                        bullets: const <AuthTrustBullet>[
                          AuthTrustBullet(
                            icon: Icons.videocam_outlined,
                            label: '1:1 sessions',
                          ),
                          AuthTrustBullet(
                            icon: Icons.verified_user_outlined,
                            label: 'Domain-matched mentors',
                          ),
                          AuthTrustBullet(
                            icon: Icons.forum_outlined,
                            label: 'A community forum',
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
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(child: NalumLogo(size: wide ? 64 : 56)),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      textStyle: text.headlineMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.headline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to your mentorship account',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Test student email: cemix95745@kinws.com\n Pass: abcd@1234',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 15,
                    ),
                  ),
                  
                  SizedBox(height: wide ? 32 : 28),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    decoration: _fieldDecoration(
                      theme: theme,
                      wide: wide,
                      label: 'Email',
                      hint: wide ? 'name@university.edu' : 'Email',
                      icon: Icons.email_outlined,
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
                    autofillHints: const <String>[AutofillHints.password],
                    decoration: _fieldDecoration(
                      theme: theme,
                      wide: wide,
                      label: 'Password',
                      hint: wide ? '••••••••' : 'Password',
                      icon: Icons.lock_outline,
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
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton(
                        onPressed: () => _comingSoon('Password recovery'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          wide ? 'Forgot?' : 'Forgot password?',
                          style: text.bodySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (auth.error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    FormErrorBanner(message: auth.error!),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: auth.loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      shadowColor: colors.primary.withValues(alpha: 0.25),
                    ),
                    icon: auth.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(wide ? Icons.arrow_forward : Icons.lock_open),
                    label: Text(auth.loading ? 'Signing in…' : 'Sign in'),
                  ),
                  if (wide) ...<Widget>[
                    const SizedBox(height: 24),
                    _DividerRow(theme: theme),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _comingSoon('Google sign-in'),
                      icon: const _GoogleMark(),
                      label: const Text('Sign in with Google'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/register'),
                      style: TextButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: text.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          children: <InlineSpan>[
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Register',
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: wide ? label : null,
      hintText: wide ? null : hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
    );
  }
}

class _DividerRow extends StatelessWidget {
  const _DividerRow({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Divider(color: theme.colorScheme.outlineVariant, height: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: theme.colorScheme.outlineVariant, height: 1),
        ),
      ],
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    final Paint p = Paint()..style = PaintingStyle.fill;
    final Path path = Path()
      ..moveTo(r.width * 0.95, r.height * 0.5)
      ..arcToPoint(
        Offset(r.width * 0.05, r.height * 0.5),
        radius: Radius.circular(r.width * 0.45),
        largeArc: true,
        clockwise: false,
      );
    canvas.drawPath(path, p..color = const Color(0xFF4285F4));
    p.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(r.width * 0.5, r.height * 0.62)
        ..lineTo(r.width * 0.31, r.height * 0.9)
        ..arcToPoint(
          Offset(r.width * 0.05, r.height * 0.5),
          radius: Radius.circular(r.width * 0.45),
          largeArc: true,
          clockwise: true,
        ),
      p,
    );
    p.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(r.width * 0.31, r.height * 0.9)
        ..lineTo(r.width * 0.5, r.height * 0.62)
        ..arcToPoint(
          Offset(r.width * 0.69, r.height * 0.38),
          radius: Radius.circular(r.width * 0.25),
          largeArc: false,
          clockwise: false,
        ),
      p,
    );
    p.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(r.width * 0.69, r.height * 0.38)
        ..arcToPoint(
          Offset(r.width * 0.95, r.height * 0.5),
          radius: Radius.circular(r.width * 0.45),
          largeArc: false,
          clockwise: false,
        ),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
