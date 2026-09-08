/// Runtime-only backend settings. Values are intentionally not committed.
class BackendConfiguration {
  const BackendConfiguration({
    this.supabaseUrl = const String.fromEnvironment('SUPABASE_URL'),
    this.supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY'),
  });

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
