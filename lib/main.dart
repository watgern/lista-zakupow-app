import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'about_screen.dart';
import 'login_screen.dart';
import 'category_screen.dart';
import 'account_screen.dart';
import 'pairing_screen.dart';
import 'category_items_screen.dart';
import 'shopping_list_screen.dart';
import 'update_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔔 Konfiguracja Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 🔐 Prośba o zgodę na powiadomienia (iOS / Android 13+)
  await messaging.requestPermission();

  // 📲 Pobierz token urządzenia (do testów lub wysyłania do konkretnego usera)
  final token = await messaging.getToken();
  print("📲 FCM TOKEN: $token");

  // 🔔 Nasłuchiwanie push notyfikacji w trakcie działania aplikacji
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final notification = message.notification;
  if (notification != null) {
    await FirebaseFirestore.instance.collection('notifications').add({
      'user': user.uid,
      'title': notification.title ?? '',
      'body': notification.body ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
});

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista Zakupów Firestore',
      theme: _buildAppTheme(),
      home: const AuthWrapper(),
      routes: {
        '/category': (context) => const CategoryScreen(),
        '/account': (context) => const AccountScreen(),
        '/pairing': (context) => PairingScreen(),
        '/categoryItems': (context) => const CategoryItemsScreen(),
        '/shoppingList': (context) => const ShoppingListScreen(),
        '/update': (context) => const UpdateScreen(),
        '/about': (context) => const AboutScreen(),

      },
    );
  }
}

ThemeData _buildAppTheme() {
  const mainGreen = Color(0xFF66BB6A);
  const lightBackground = Color(0xFFF1F8E9);

  return ThemeData(
    primaryColor: mainGreen,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: mainGreen,
      brightness: Brightness.light,
    ).copyWith(
      primary: mainGreen,
      secondary: mainGreen,
      background: lightBackground,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: mainGreen,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: mainGreen,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: mainGreen,
        textStyle: const TextStyle(fontSize: 14),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.all(mainGreen),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
  );
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const CategoryScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
