import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({Key? key}) : super(key: key);

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  String? _remoteVersion;
  String? _changelog;
  String? _apkUrl;
  String? _currentVersion;
  bool _isLoading = true;
  bool _updateAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;

      final response = await http.get(Uri.parse(
          'https://lista-zakupow-16d84.web.app/version.json')); // <-- Twój plik JSON z wersją

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _remoteVersion = data['version'];
        _apkUrl = data['apk_url'];
        _changelog = data['changelog'];

        if (_remoteVersion != null &&
            _remoteVersion!.trim() != _currentVersion!.trim()) {
          _updateAvailable = true;
        }
      } else {
        print('Błąd HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Błąd pobierania wersji: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _downloadAndInstallApk() async {
  print("Kliknięto przycisk aktualizacji");

  final status = await Permission.requestInstallPackages.status;

  if (!status.isGranted) {
    print("Brak zgody na instalację – otwieram ustawienia...");
    await openAppSettings();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nadaj zgodę w ustawieniach, a następnie wróć i kliknij ponownie.')),
    );
    return;
  }

  try {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/update.apk';
    print("Pobieranie APK do: $filePath");

    final dio = Dio();
    await dio.download(_apkUrl!, filePath);

    print("Pobrano. Otwieranie...");
    final result = await OpenFile.open(filePath);
    print("Wynik otwarcia: ${result.message}");
  } catch (e) {
    print("Błąd podczas pobierania: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Błąd podczas pobierania: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aktualizacja aplikacji")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _updateAvailable
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dostępna nowa wersja: $_remoteVersion",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text("Obecna wersja: $_currentVersion"),
                        const SizedBox(height: 12),
                        if (_changelog != null) ...[
                          const Text("Co nowego:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(_changelog!),
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text("Pobierz i zainstaluj"),
                          onPressed: () {
                            print('Kliknięto przycisk aktualizacji');
                            _downloadAndInstallApk();
                          },
                        )
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              size: 64, color: Colors.green),
                          const SizedBox(height: 16),
                          Text("Masz najnowszą wersję ($_currentVersion)"),
                        ],
                      ),
                    ),
            ),
    );
  }
}
