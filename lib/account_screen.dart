// lib/account_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moj_pierszy_projekt/widgets/app_drawer.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Konto"),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: user != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Informacje o koncie:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Email: ${user.email ?? "Brak"}"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Przykładowe resetowanie hasła (przejście do ekranu resetu lub wykonanie akcji)
                      Navigator.pop(context);
                    },
                    child: const Text("Zmień hasło"),
                  ),
                ],
              )
            : const Center(child: Text("Brak danych o koncie")),
      ),
    );
  }
}
