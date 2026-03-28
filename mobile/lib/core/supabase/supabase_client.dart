// Convenience accessor for the Supabase client.
// Import this file instead of calling Supabase.instance.client everywhere.
import 'package:supabase_flutter/supabase_flutter.dart';

/// Returns the singleton [SupabaseClient].
/// Requires [Supabase.initialize] to have been called first (done in main.dart).
SupabaseClient get supabase => Supabase.instance.client;
