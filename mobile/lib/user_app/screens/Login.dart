import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';         // Halaman utama setelah login
import 'Register.dart';    // Halaman untuk registrasi

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fungsi login dengan Firebase Auth
  Future<void> _login() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Navigasi ke halaman utama (Home) setelah login berhasil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(user: userCredential.user!)),
      );
    } on FirebaseAuthException catch (e) {
      String message = '';

      switch (e.code) {
        case 'user-not-found':
          message = 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
          break;
        case 'wrong-password':
          message = 'Password salah. Coba lagi.';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid.';
          break;
        case 'user-disabled':
          message = 'Akun ini telah dinonaktifkan.';
          break;
        default:
          message = 'Login gagal: ${e.message}';
      }

      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Terjadi kesalahan. Silakan coba lagi."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Gambar atau ilustrasi
                Image.asset(
                  'assets/lg.png',
                  height: 200,
                ),
                const SizedBox(height: 20),

                // Judul Halaman
                const Text(
                  'Selamat Datang',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Input email
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 20),

                // Input password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Masuk
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Masuk'),
                ),
                const SizedBox(height: 10),

                // Tautan Daftar Akun
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  child: const Text('Daftar Akun'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
