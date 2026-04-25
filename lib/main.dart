import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/auth_providers.dart';
import 'providers/game_providers.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const GamifiedApp(),
    ),
  );
}

class GamifiedApp extends ConsumerWidget {
  const GamifiedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gamified Home',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: LaunchCinematicGate(authState: authState),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
      },
    );
  }
}

class LaunchCinematicGate extends StatefulWidget {
  const LaunchCinematicGate({
    super.key,
    required this.authState,
  });

  final AsyncValue<dynamic> authState;

  @override
  State<LaunchCinematicGate> createState() => _LaunchCinematicGateState();
}

class _LaunchCinematicGateState extends State<LaunchCinematicGate> {
  bool _showCinematic = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() {
        _showCinematic = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showCinematic) {
      final size = MediaQuery.of(context).size;
      return Material(
        color: Colors.black,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: RiveAnimation.asset(
            'Loading_Screen.riv',
            fit: BoxFit.fill,
          ),
        ),
      );
    }

    return widget.authState.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
      data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}

