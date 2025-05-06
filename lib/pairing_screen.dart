import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moj_pierszy_projekt/widgets/app_drawer.dart';

class PairingScreen extends StatefulWidget {
  @override
  _PairingScreenState createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final TextEditingController _uidController = TextEditingController();
  String _status = "";
  String? _myUID;
  String? _partnerUID;

  @override
  void initState() {
    super.initState();
    _loadPairingInfo();
  }

  Future<void> _loadPairingInfo() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final myUID = currentUser.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('pairedUsers')
        .doc(myUID)
        .get();

    setState(() {
      _myUID = myUID;
      if (snapshot.exists && snapshot.data()?['partner'] != null) {
      _partnerUID = snapshot.data()?['partner'] as String;
      }
    });
  }

  Future<void> _pairUsers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final enteredUID = _uidController.text.trim();

    if (currentUser == null || enteredUID.isEmpty || enteredUID == currentUser.uid) {
      setState(() {
        _status = "Nieprawidłowy UID.";
      });
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('users').doc(enteredUID).get();

      if (!doc.exists) {
        setState(() {
          _status = "Użytkownik nie istnieje.";
        });
        return;
      }

      await firestore.collection('pairedUsers').doc(currentUser.uid).set({
        'partner': enteredUID,
      });
      await firestore.collection('pairedUsers').doc(enteredUID).set({
        'partner': currentUser.uid,
      });

      setState(() {
        _partnerUID = enteredUID;
        _status = "Sparowano pomyślnie!";
      });
    } catch (e) {
      setState(() {
        _status = "Błąd: ${e.toString()}";
      });
    }
  }

  Future<void> _unpairUsers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _partnerUID == null) return;

    final firestore = FirebaseFirestore.instance;

    await firestore.collection('pairedUsers').doc(currentUser.uid).delete();
    await firestore.collection('pairedUsers').doc(_partnerUID!).delete();

    setState(() {
      _partnerUID = null;
      _status = "Odłączono partnera.";
    });
  }

  void _copyUID() {
    if (_myUID != null) {
      Clipboard.setData(ClipboardData(text: _myUID ?? ""));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Skopiowano UID do schowka")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Parowanie kont")),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Twój UID:", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(child: Text(_myUID ?? "Ładowanie...")),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: _copyUID,
                  tooltip: "Kopiuj UID",
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text("Wpisz UID partnera:"),
            TextField(controller: _uidController),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _pairUsers,
              child: const Text("Połącz konta"),
            ),
            const SizedBox(height: 12),
            if (_partnerUID != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Sparowany z:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_partnerUID!),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _unpairUsers,
                    icon: const Icon(Icons.link_off),
                    label: const Text("Odłącz konto"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Text(_status, style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}
