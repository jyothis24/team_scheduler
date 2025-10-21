import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
void main() {
  runApp(const MyApp());
}

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
