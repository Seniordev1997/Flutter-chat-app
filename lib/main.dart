import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:whatsapp_clone/features/auth/views/user_profile.dart';
import 'package:whatsapp_clone/features/auth/views/verification.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/dark.dart';
import 'features/auth/views/welcome.dart' show WelcomePage;

class WhatsApp extends StatelessWidget {
  const WhatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: darkTheme,
      debugShowCheckedModeBanner: false,
      home: const WelcomePage(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: WhatsApp(),
    ),
  );
}
