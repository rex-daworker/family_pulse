import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  // Required before any async work in main
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using the auto-generated config
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ProviderScope wraps the whole app for Riverpod state management
  runApp(
    const ProviderScope(
      child: FamilyPulseApp(),
    ),
  );
}

class FamilyPulseApp extends StatelessWidget {
  const FamilyPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FamilyPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D9E75)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('FamilyPulse — Coming Soon'),
        ),
      ),
    );
  }
}