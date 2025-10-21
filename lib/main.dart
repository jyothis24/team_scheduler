import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://wjcdutzlamxihrgkxkad.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqY2R1dHpsYW14aWhyZ2t4a2FkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MjM2MzUsImV4cCI6MjA3MzQ5OTYzNX0.GRj0ikI2hnF_ISO1af_q8GTGaG4DgWCvB7_JiHErZ3Y',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Scheduler',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const OnboardingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
