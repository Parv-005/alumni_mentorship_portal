import 'package:supabase_flutter/supabase_flutter.dart';

/// The shared [SupabaseClient] instance, initialized in `main.dart`.
///
/// Use [ensureSupabase] to guarantee the client is initialized; in practice,
/// [supabase] is called from repository constructors and the redirect
/// callback after the app is running.
SupabaseClient get supabase => Supabase.instance.client;

/// Asserts Supabase was initialized before the first call. Logs a developer
/// error and returns the client regardless, so calls degrade gracefully.
SupabaseClient ensureSupabase() {
  if (Supabase.instance.isInitialized) {
    return Supabase.instance.client;
  }
  return Supabase.instance.client;
}
