import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android's native side (google-services.json) can auto-init the
  // default app before Dart runs, so Firebase.apps.isEmpty can't be
  // trusted here — catch the resulting duplicate-app error instead.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

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