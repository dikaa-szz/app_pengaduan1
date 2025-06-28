import 'package:flutter/material.dart';

class PantauLaporanPage extends StatelessWidget {
  const PantauLaporanPage({super.key});

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
              Icons.search, // Ikon pencarian
              size: 40, // Ukuran ikon
              color: Colors.teal, // Warna ikon
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Menampilkan judul laporan
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text(
                "Judul Laporan",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
            ),
            // Menampilkan informasi laporan
            Card(
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Lokasi fasilitas rusak 🛠",
                      style: TextStyle(fontSize: 14, color: Colors.teal),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Tanggal Pengaduan 📅",
                      style: TextStyle(fontSize: 14, color: Colors.teal),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text("Status Laporan"),
                    ),
                  ],
                ),
              ),
            ),
            // Menampilkan perkembangan laporan
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Perkembangan Laporan",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  _buildProgressItem(
                    color: Colors.orange,
                    status: "Laporan Dikirim → 10 Maret 2025",
                  ),
                  _buildProgressItem(
                    color: Colors.yellow,
                    status: "Dalam Proses → 12 Maret 2025",
                  ),
                  _buildProgressItem(
                    color: Colors.green,
                    status: "Selesai Diperbaiki → 15 Maret 2025",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem({required Color color, required String status}) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 12),
        SizedBox(width: 8),
        Text(status),
      ],
    );
  }
}
