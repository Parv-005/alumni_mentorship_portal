import 'package:alumni_mentorship_platform/app.dart';
import 'package:alumni_mentorship_platform/core/supabase/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Entry point for the Alumni Mentorship Platform app.
///
/// Initializes environment variables, then the Supabase client, then hands
/// control to [AppRoot]. Surfaces configuration errors via [runApp] so the UI
/// can display them in debug builds.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } on Object catch (error) {
    debugPrint('Failed to load .env: $error');
    runApp(
      _EnvErrorApp(message: 'Missing .env file. Copy .env.example to .env.'),
    );
    return;
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      supabaseUrl == 'your-project-url' ||
      supabaseAnonKey == null ||
      supabaseAnonKey.isEmpty ||
      supabaseAnonKey == 'your-anon-key') {
    runApp(
      const _EnvErrorApp(
        message: 'SUPABASE_URL or SUPABASE_ANON_KEY missing in .env.',
      ),
    );
    return;
  }

  try {
    // ignore: deprecated_member_use
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  } on Object catch (error) {
    debugPrint('Failed to initialize Supabase: $error');
    runApp(_EnvErrorApp(message: 'Failed to initialize Supabase: $error'));
    return;
  }

  ensureSupabase();

  runApp(const AppRoot());
}

class _EnvErrorApp extends StatelessWidget {
  const _EnvErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Configuration error',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
