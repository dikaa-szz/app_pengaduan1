import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  User? _currentUser;
  
  // Konfigurasi URL Laravel - DIPERBAIKI
  static const String laravelBaseUrl = 'http://127.0.0.1:8000'; // Untuk Android Emulator
  
  // URL alternatif untuk testing
  static const List<String> alternativeUrls = [
    'http://10.0.2.2:8000',      // Android Emulator
    'http://192.168.1.7', // Ganti dengan IP komputer Anda
    'http://127.0.0.1:8000',     // Local (web)
    'http://localhost:8000',     // Local (web)
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Riwayat", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.teal,
          elevation: 2,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Silakan login terlebih dahulu", 
                style: TextStyle(fontSize: 16, color: Colors.grey)
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Laporan", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reports')
              .where('user_id', isEqualTo: _currentUser!.uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.teal),
                    SizedBox(height: 16),
                    Text("Memuat riwayat..."),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      "Terjadi kesalahan saat memuat data",
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: const Text("Coba Lagi"),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "Belum ada laporan",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Laporan yang Anda buat akan muncul di sini",
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs;

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return _buildReportCard(data);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> data) {
    // Ambil data dengan validasi null safety
    final title = data['title']?.toString() ?? "Tidak ada judul";
    final description = data['description']?.toString() ?? "Tidak ada deskripsi";
    final location = data['location']?.toString() ?? "Lokasi tidak tersedia";
    final reportType = data['report_type']?.toString() ?? "Jenis laporan tidak tersedia";
    final status = data['status']?.toString() ?? "Menunggu";
    final imageUrl = data['image_url']?.toString();
    
    // Format tanggal dengan error handling
    String formattedDate = "Tanggal tidak tersedia";
    try {
      if (data['timestamp'] != null) {
        final timestamp = data['timestamp'] as Timestamp;
        final dateTime = timestamp.toDate();
        formattedDate = "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      }
    } catch (e) {
      debugPrint("Error parsing timestamp: $e");
    }

    // Tentukan warna status
    Color statusColor = _getStatusColor(status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(context, data, formattedDate),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan judul dan status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reportType,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Deskripsi (dipotong jika terlalu panjang)
              Text(
                description.length > 100 ? 
                  "${description.substring(0, 100)}..." : description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Lokasi dan tanggal
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              // Indikator ada gambar
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.image, size: 16, color: Colors.teal),
                    const SizedBox(width: 4),
                    Text(
                      "Ada foto lampiran",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'completed':
        return Colors.green;
      case 'ditolak':
      case 'rejected':
        return Colors.red;
      case 'sedang diproses':
      case 'processing':
        return Colors.blue;
      case 'menunggu':
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showDetailDialog(BuildContext context, Map<String, dynamic> data, String formattedDate) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        data['title']?.toString() ?? "Detail Laporan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PERBAIKAN UTAMA: Tampilkan gambar dengan URL handling yang benar
                      if (data['image_url'] != null && data['image_url'].toString().isNotEmpty) ...[
                        _buildImageWidget(data['image_url'].toString()),
                        const SizedBox(height: 16),
                      ],
                      
                      // Details
                      _buildDetailRow("Jenis Laporan", data['report_type']?.toString() ?? "-"),
                      _buildDetailRow("Status", data['status']?.toString() ?? "-"),
                      _buildDetailRow("Lokasi", data['location']?.toString() ?? "-"),
                      _buildDetailRow("Tanggal", formattedDate),
                      
                      const SizedBox(height: 12),
                      Text(
                        "Deskripsi:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Colors.teal[800]
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['description']?.toString() ?? "Tidak ada deskripsi",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PERBAIKAN UTAMA: Widget untuk menampilkan gambar dengan URL handling yang benar
  Widget _buildImageWidget(String imageUrl) {
    debugPrint("📸 Image URL dari Firestore: $imageUrl");
    
    // Buat list URL yang akan dicoba
    List<String> possibleUrls = _generateImageUrls(imageUrl);
    
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildImageWithFallback(possibleUrls, 0),
      ),
    );
  }

  // PERBAIKAN UTAMA: Generate URL gambar yang benar
  List<String> _generateImageUrls(String imageUrl) {
    List<String> urls = [];
    
    // 1. Jika URL sudah lengkap (dari Laravel asset()), gunakan langsung
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      urls.add(imageUrl);
      debugPrint("✅ URL lengkap ditemukan: $imageUrl");
    }
    
    // 2. Ekstrak nama file dari URL
    String filename = imageUrl;
    if (imageUrl.contains('/')) {
      filename = imageUrl.split('/').last;
    }
    
    // 3. Buat URL alternatif berdasarkan struktur Laravel standar
    for (String baseUrl in alternativeUrls) {
      // URL standar Laravel setelah php artisan storage:link
      urls.add('$baseUrl/storage/uploads/$filename');
      
      // URL alternatif lainnya
      urls.add('$baseUrl/storage/app/public/uploads/$filename');
      urls.add('$baseUrl/public/storage/uploads/$filename');
      urls.add('$baseUrl/uploads/$filename');
    }
    
    // 4. Hilangkan duplikat URL
    urls = urls.toSet().toList();
    
    debugPrint("🔄 Akan mencoba ${urls.length} URL:");
    for (int i = 0; i < urls.length; i++) {
      debugPrint("  ${i + 1}. ${urls[i]}");
    }
    
    return urls;
  }

  // PERBAIKAN: Widget untuk load gambar dengan fallback
  Widget _buildImageWithFallback(List<String> urls, int currentIndex) {
    if (currentIndex >= urls.length) {
      return _buildImageError("Semua URL gagal dimuat");
    }

    String currentUrl = urls[currentIndex];
    debugPrint("🔄 Mencoba URL: $currentUrl");

    return Image.network(
      currentUrl,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      headers: {
        'User-Agent': 'Flutter App',
        'Accept': 'image/*',
        'Cache-Control': 'no-cache',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          debugPrint("✅ Berhasil memuat gambar dari: $currentUrl");
          return child;
        }
        
        return Container(
          height: 200,
          color: Colors.grey[50],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.teal,
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  "Memuat gambar...",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  "Mencoba URL ${currentIndex + 1}/${urls.length}",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
                if (loadingProgress.expectedTotalBytes != null)
                  Text(
                    "${(loadingProgress.cumulativeBytesLoaded / 1024).toStringAsFixed(1)} KB / ${(loadingProgress.expectedTotalBytes! / 1024).toStringAsFixed(1)} KB",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 8,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint("❌ Gagal memuat dari $currentUrl: $error");
        
        // Jika masih ada URL lain untuk dicoba
        if (currentIndex + 1 < urls.length) {
          debugPrint("🔄 Mencoba URL berikutnya...");
          return _buildImageWithFallback(urls, currentIndex + 1);
        } else {
          debugPrint("💥 Semua URL gagal!");
          return _buildImageError("Tidak dapat memuat gambar");
        }
      },
    );
  }

  Widget _buildImageError(String message) {
    return Container(
      height: 200,
      color: Colors.grey[50],
      child: InkWell(
        onTap: () {
          // Refresh untuk mencoba lagi
          setState(() {});
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
                size: 40,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                "Gagal memuat gambar",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Ketuk untuk mencoba lagi",
                style: TextStyle(
                  color: Colors.teal,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showImageDebugDialog(),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text("Info Debug"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageDebugDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Debug Info - Gambar"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Base URL Laravel:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(laravelBaseUrl, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              const SizedBox(height: 16),
              const Text("Pastikan:", style: TextStyle(fontWeight: FontWeight.bold)),
              const Text("✓ Laravel server berjalan", style: TextStyle(fontSize: 12)),
              const Text("✓ Jalankan: php artisan storage:link", style: TextStyle(fontSize: 12)),
              const Text("✓ Folder storage/app/public/uploads ada", style: TextStyle(fontSize: 12)),
              const Text("✓ File gambar tersimpan dengan benar", style: TextStyle(fontSize: 12)),
              const Text("✓ Permissions folder 755", style: TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              const Text("Struktur URL Laravel:", style: TextStyle(fontWeight: FontWeight.bold)),
              const Text("http://domain.com/storage/uploads/nama_file.jpg", style: TextStyle(fontFamily: 'monospace', fontSize: 10)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.teal[800],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}