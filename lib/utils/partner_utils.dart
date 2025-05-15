import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<List<String>> getPairedUIDs() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return [];

  final uid = currentUser.uid;
  final doc = await FirebaseFirestore.instance
      .collection('pairedUsers')
      .doc(uid)
      .get();

  if (doc.exists && doc.data()?['partner'] != null) {
    final partnerUID = doc.data()!['partner'] as String;
    return [uid, partnerUID];
  }

  return [uid];
}
