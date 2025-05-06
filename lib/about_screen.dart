// lib/about_screen.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:moj_pierszy_projekt/widgets/app_drawer.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("O aplikacji")),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Lista Zakupów", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Wersja: $_version"),
            const SizedBox(height: 20),
            const Text("Autor: Łukasz Onyszczuk"),
            const SizedBox(height: 10),
            const Text("Aplikacja służy do zarządzania listami zakupów, kategorii oraz parowaniem kont użytkowników."),
            const SizedBox(height: 20),
            const Text("Kontakt:"),
            const Text("📧 watgern@gmail.com"),
          ],
        ),
      ),
    );
  }
}
