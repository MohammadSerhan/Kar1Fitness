import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _status = 'Ready to test';
  bool _testing = false;

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _testing = true;
      _status = 'Testing Firebase connection...\n';
    });

    try {
      // Test 1: Check Firebase Auth
      _updateStatus('✓ Firebase Auth initialized');

      // Test 2: Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _updateStatus('✓ Current user: ${currentUser.email} (${currentUser.uid})');
      } else {
        _updateStatus('✗ No user signed in');
      }

      // Test 3: Try to read from Firestore
      _updateStatus('\nTesting Firestore read...');
      try {
        final testDoc = await _firestore.collection('_test').doc('connection').get();
        _updateStatus('✓ Firestore read successful (exists: ${testDoc.exists})');
      } catch (e) {
        _updateStatus('✗ Firestore read failed: $e');
      }

      // Test 4: Try to write to Firestore
      _updateStatus('\nTesting Firestore write...');
      try {
        await _firestore.collection('_test').doc('connection').set({
          'timestamp': FieldValue.serverTimestamp(),
          'test': true,
        });
        _updateStatus('✓ Firestore write successful');
      } catch (e) {
        _updateStatus('✗ Firestore write failed: $e');
      }

      // Test 5: Check if user document exists
      if (currentUser != null) {
        _updateStatus('\nChecking user document...');
        try {
          final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
          if (userDoc.exists) {
            _updateStatus('✓ User document exists');
            _updateStatus('Data: ${userDoc.data()}');
          } else {
            _updateStatus('✗ User document does NOT exist');
            _updateStatus('\nAttempting to create user document...');

            // Try to create user document
            try {
              final userData = {
                'uid': currentUser.uid,
                'email': currentUser.email,
                'name': currentUser.displayName ?? 'User',
                'created_at': FieldValue.serverTimestamp(),
              };

              await _firestore.collection('users').doc(currentUser.uid).set(userData);
              _updateStatus('✓ User document created successfully!');
            } catch (e) {
              _updateStatus('✗ Failed to create user document: $e');
            }
          }
        } catch (e) {
          _updateStatus('✗ Error checking user document: $e');
        }
      }

      _updateStatus('\n✓ All tests completed!');
    } catch (e) {
      _updateStatus('\n✗ Error: $e');
    } finally {
      setState(() => _testing = false);
    }
  }

  void _updateStatus(String message) {
    setState(() {
      _status += '\n$message';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _testing ? null : _testFirebaseConnection,
              child: Text(_testing ? 'Testing...' : 'Run Firebase Tests'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
