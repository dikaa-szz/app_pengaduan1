import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Mengimpor FirebaseAuth untuk akses User

import 'report.dart';
import 'report_form.dart';
import 'detail_report.dart';
import 'riwayat_page.dart';
import 'pantau_laporan.dart';
import 'profile.dart'; 
import 'dashboard.dart';

class HomeScreen extends StatefulWidget {
  final User user; // Menambahkan parameter user

  // Konstruktor yang menerima parameter user
  const HomeScreen({super.key, required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigasi berdasarkan item yang dipilih
    if (index == 0) {
      // Navigasi ke halaman Home
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(user: widget.user)), // Mengirim parameter user ke HomeScreen
      );
    } else if (index == 2) {
      // Navigasi ke halaman Profile ketika ikon Profile dipilih
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()), // Navigasi ke halaman Profile
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // Latar belakang putih
        elevation: 0, // Menghilangkan shadow di bawah AppBar
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Logo di kiri
          children: [
            Icon(
              FontAwesomeIcons.tools, // Ikon palu dan obeng dari FontAwesome
              size: 40, // Ukuran ikon
              color: Colors.teal, // Warna ikon
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(  // Menambahkan SingleChildScrollView agar seluruh konten bisa discrol
        child: Column(
          children: [
            // Menampilkan teks di atas gambar
            Container(
              padding: EdgeInsets.symmetric(vertical: 16), // Memberikan padding di atas dan bawah
              alignment: Alignment.center,
              child: Text(
                "Laporkan dan Pantau Perbaikan Fasilitas Umum",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
            ),
            // Gambar yang mengikuti ukuran layar
            Container(
              width: MediaQuery.of(context).size.width,  // Menggunakan lebar layar
              height: MediaQuery.of(context).size.height * 0.3,  // Menggunakan 30% dari tinggi layar
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 216, 230, 228), // Ubah warna latar belakang sesuai desain
                borderRadius: BorderRadius.circular(30), // Sudut tumpul
              ),
              child: Center(
                child: Image.asset(  // Gunakan Image.asset jika menggunakan gambar dari assets
                  'assets/bg.png', // Pastikan path sesuai dengan nama dan lokasi gambar Anda
                  fit: BoxFit.cover, // Menyesuaikan gambar dengan area
                ),
              ),
            ),
            SizedBox(height: 20), // Memberikan jarak antara gambar dan grid

            // Membungkus Grid Menu dengan padding dan background berbeda
            Padding(
              padding: EdgeInsets.all(12), // Memberikan padding pada grid
              child: Container(
                padding: EdgeInsets.all(10),  // Memberikan padding pada container
                decoration: BoxDecoration(
                  color: Colors.teal[50], // Background untuk menu
                  borderRadius: BorderRadius.circular(30), // Sudut tumpul
                ),
                child: GridView.count(
                  shrinkWrap: true,  // Menyebabkan GridView untuk menyesuaikan ukuran dengan kontennya
                  crossAxisCount: 3,
                  mainAxisSpacing: 16, // Jarak antar kolom
                  crossAxisSpacing: 16, // Jarak antar baris
                  children: [
                    _buildGridItem(Icons.description, "Report", context),
                    _buildGridItem(FontAwesomeIcons.mapMarkerAlt, "Pantau Laporan", context),
                    _buildGridItem(Icons.notifications, "Notifikasi", context),
                    _buildGridItem(Icons.dashboard, "Dashboard", context),
                    _buildGridItem(Icons.history, "Riwayat", context),
                    _buildGridItem(Icons.article, "Detail Laporan", context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,  // Mengubah warna ikon yang dipilih
        unselectedItemColor: Colors.teal.withOpacity(0.6), // Mengubah warna ikon yang tidak dipilih
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile', 
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String label, BuildContext context) {
    return GestureDetector(
      onTap: () {
         if (label == "Pantau Laporan") {
          // Navigasi ke halaman Pantau Laporan
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PantauLaporanPage()), // Pindah ke halaman Pantau Laporan
          );
         } else if (label == "Riwayat") {
          // Navigasi ke halaman Riwayat
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RiwayatPage()), // Pindah ke halaman Riwayat
          );
        } else if (label == "Report") {
          // Navigasi ke halaman pilihan jenis pelaporan
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReportPage()),
          );
        } else if (label == "Detail Laporan") {
          // Navigasi ke halaman Detail Laporan
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailReportPage(docId: 'ID_LAPORAN_YANG_INGIN_DITAMPILKAN'),
            ),
          );
        } else if (label == "Dashboard") {
          // Navigasi ke halaman Dashboard
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()), // Pindah ke halaman Dashboard
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.teal),
          SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.teal, fontSize: 12)),
        ],
      ),
    );
  }
}
