// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Brak e-maila';
    final name = user?.displayName ?? 'Użytkownik';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color.fromARGB(255, 36, 211, 86)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 24, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Kategorie'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/category');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Konto'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/account');
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Parowanie kont'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/pairing');
            },
          ),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('Sprawdź wersję'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/update');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('O aplikacji'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/about');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Wyloguj się'),
            onTap: () async {
  await FirebaseAuth.instance.signOut();
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
},

          ),
        ],
      ),
    );
  }
}
