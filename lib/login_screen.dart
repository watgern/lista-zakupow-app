import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Logowanie' : 'Rejestracja'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Adres e-mail'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Hasło'),
            ),
            if (!_isLogin) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Powtórz hasło'),
              ),
            ],
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitAuthForm,
                    child: Text(_isLogin ? 'Zaloguj' : 'Zarejestruj'),
                  ),
            if (_isLogin)
              TextButton(
                onPressed: _resetPassword,
                child: const Text('Zapomniałeś hasła?'),
              ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                });
              },
              child: Text(_isLogin
                  ? 'Nie masz konta? Zarejestruj się'
                  : 'Masz już konto? Zaloguj się'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAuthForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Proszę wprowadzić adres e-mail i hasło.');
      return;
    }

    if (!_isLogin) {
      final confirmPassword = _confirmPasswordController.text.trim();
      if (password != confirmPassword) {
        _showError('Hasła nie są identyczne.');
        return;
      }
    }

    try {
      setState(() => _isLoading = true);

      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('Zalogowano jako: $email');
      } else {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Zapisz użytkownika do Firestore (ważne!)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': userCredential.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('Zarejestrowano jako: $email i zapisano w Firestore');
      }
    } on FirebaseAuthException catch (e) {
      _showError('Błąd: ${e.message}');
    } catch (e) {
      _showError('Nieznany błąd: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Proszę wprowadzić adres e-mail, aby zresetować hasło.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage('Link resetujący hasło został wysłany na $email');
    } on FirebaseAuthException catch (e) {
      _showError('Błąd: ${e.message}');
    } catch (e) {
      _showError('Nieznany błąd: $e');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wystąpił błąd'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Informacja'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
