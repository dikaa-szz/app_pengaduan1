import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';


import 'firebase_options.dart';
import 'user_app/screens/Login.dart';
import 'user_app/screens/home.dart';
import 'user_app/screens/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistem Pelaporan Jalan Rusak',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,

      home: const LoginPage(),

      routes: {
        '/login': (context) => const LoginPage(),
        // '/home': (context) => const HomeScreen(), // aktifkan jika diperlukan
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
