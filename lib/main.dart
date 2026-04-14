import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✓ Firebase initialized successfully');
  } catch (e) {
    print('✗ Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        title: 'KAR1 Fitness',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _ensureUserDocument(User user) async {
    try {
      print('Checking user document for ${user.uid}...');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        print('User document not found, creating...');
        final userData = {
          'uid': user.uid,
          'email': user.email ?? '',
          'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
          'created_at': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('users').doc(user.uid).set(userData);
        print('✓ User document created successfully!');
      } else {
        print('✓ User document already exists');
      }
    } catch (e) {
      print('✗ Error ensuring user document: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is signed in, ensure their document exists
          _ensureUserDocument(snapshot.data!);
          return const MainScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
