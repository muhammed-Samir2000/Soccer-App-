import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/app_dependencies.dart';
import 'core/config/backend_configuration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final BackendConfiguration configuration = BackendConfiguration();
  if (configuration.isSupabaseConfigured) {
    await Supabase.initialize(
      url: configuration.supabaseUrl,
      publishableKey: configuration.supabaseAnonKey,
    );
  }
  final AppDependencies dependencies = await AppDependencies.fromBackend(
    configuration,
  );
  runApp(SoccerBookingApp(dependencies: dependencies));
}
