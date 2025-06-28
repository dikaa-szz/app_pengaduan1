import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'report_form.dart'; // Impor halaman formulir pelaporan

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pilih Jenis Pelaporan", 
          style: TextStyle(color: Colors.teal), // Warna teks di AppBar
        ),
        backgroundColor: const Color.fromARGB(255, 236, 238, 238), // Warna latar belakang AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Membuat Row dengan tiga pilihan pelaporan secara horizontal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Memberikan ruang antar elemen secara merata
              children: [
                _buildReportOption("Jalan Rusak", 'assets/js.png', context),
                _buildReportOption("Fasilitas Umum", 'assets/fu.png', context),
                _buildReportOption("Lalin & Lampu Jalan", 'assets/ll.png', context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk membangun pilihan jenis pelaporan
  Widget _buildReportOption(String title, String assetImage, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke halaman formulir pelaporan
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReportFormPage()),
        );
      },
      child: Container(
        width: 100,  // Menentukan lebar untuk setiap pilihan
        height: 120, // Menentukan tinggi untuk setiap pilihan
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 253, 255, 255),
          borderRadius: BorderRadius.circular(10), // Membuat sudut tumpul
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Memastikan gambar dan teks di tengah
          crossAxisAlignment: CrossAxisAlignment.center, // Memastikan teks dan gambar sejajar secara horizontal
          children: [
            Image.asset(assetImage, width: 50, height: 50), // Menggunakan gambar dari assets
            SizedBox(height: 8), // Memberikan jarak antara gambar dan teks
            Text(title, style: TextStyle(color: Colors.teal, fontSize: 14)), // Menambahkan teks
          ],
        ),
      ),
    );
  }
}
