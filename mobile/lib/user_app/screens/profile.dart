import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import halaman edit profile
import 'edit_profile_page.dart'; // Sesuaikan dengan path file Anda

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user;
  String name = 'Memuat...';
  String telephone = 'Memuat...';
  String email = '';
  String about = 'Aplikasi pelaporan fasilitas umum';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _getUserData();
  }

  Future<void> _getUserData() async {
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            name = data['name'] ?? 'Tidak diketahui';
            telephone = data['phone'] ?? 'Tidak diketahui';
            email = data['email'] ?? user!.email ?? 'Tidak diketahui';
            isLoading = false;
          });
        } else {
          // Jika dokumen tidak ada, gunakan data dari Firebase Auth
          setState(() {
            name = user!.displayName ?? 'Tidak diketahui';
            email = user!.email ?? 'Tidak diketahui';
            telephone = 'Tidak diketahui';
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          name = 'Error memuat data';
          telephone = 'Error memuat data';
          email = user!.email ?? 'Error memuat data';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fungsi untuk refresh data
  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    await _getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text("Profile"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFFE0E0E0),
                  child: Icon(Icons.person, size: 60, color: Colors.teal),
                ),
                const SizedBox(height: 24),

                _infoCard(Icons.person, "Nama", name),
                const SizedBox(height: 12),
                _infoCard(Icons.email, "Email", email),
                const SizedBox(height: 12),
                _infoCard(Icons.phone, "Telepon", telephone),
                const SizedBox(height: 12),
                _infoCard(Icons.info, "About", about),
                const SizedBox(height: 24),

                // Button Edit Profile
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // Navigate ke halaman edit profile
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                      
                      // Refresh data jika ada perubahan
                      if (result == true) {
                        _refreshData();
                      }
                    },
                    icon: const Icon(Icons.edit, color: Color.fromARGB(255, 74, 179, 168)),
                    label: const Text(
                      "Edit Profile", 
                      style: TextStyle(color: Color.fromARGB(255, 95, 206, 195))
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color.fromARGB(255, 74, 179, 168)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Button Logout
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Logout", style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    // Konfirmasi logout
                    bool? shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Konfirmasi'),
                        content: const Text('Apakah Anda yakin ingin keluar?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.teal.shade100),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label, 
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  )
                ),
                const SizedBox(height: 4),
                Text(
                  value, 
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}