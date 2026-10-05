import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

    // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ydmkelswmewcyewpprtf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlkbWtlbHN3bWV3Y3lld3BwcnRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEwNTA4NzYsImV4cCI6MjEwNjYyNjg3Nn0.Qa5U6BMdtpxqspR772VCdHQ7yS4nYADZ5y3zbapGjqY',
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Return Translink',
      theme: AppTheme.lightTheme,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
