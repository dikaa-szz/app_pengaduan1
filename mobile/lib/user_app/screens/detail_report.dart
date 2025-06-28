import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class DetailReportPage extends StatefulWidget {
  final String docId;

  const DetailReportPage({super.key, required this.docId});

  @override
  _DetailReportPageState createState() => _DetailReportPageState();
}

class _DetailReportPageState extends State<DetailReportPage> {
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  File? _image;
  Uint8List? _webImageBytes;
  String? imageUrl;
  bool _isSubmitting = false;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  
  // Stream untuk mendengarkan perubahan realtime
  late Stream<DocumentSnapshot> _reportStream;
  
  // Flag untuk mencegah update berulang
  bool _isUpdatingFromStream = false;
  
  // Menyimpan data terakhir untuk perbandingan
  String _lastDescription = '';
  String _lastLocation = '';
  String? _lastImageUrl;

  // Tambahan untuk error handling
  String? _error;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    print('DetailReportPage initialized with docId: ${widget.docId}');
    _initializeStream();
    _loadInitialReport();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Inisialisasi stream untuk realtime updates
  void _initializeStream() {
    _reportStream = FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.docId)
        .snapshots();
  }

  // Memuat laporan awal dengan error handling yang lebih baik
  Future<void> _loadInitialReport() async {
    try {
      print('=== DEBUG INFO ===');
      print('Loading report for docId: ${widget.docId}');
      
      // Validasi docId terlebih dahulu - perbaikan utama di sini
      if (widget.docId.isEmpty || 
          widget.docId == 'ID_LAPORAN_YANG_INGIN_DITAMPILKAN' ||
          widget.docId.contains('ID_LAPORAN') ||
          widget.docId.contains('PLACEHOLDER')) {
        setState(() {
          _isLoading = false;
          _error = "Document ID tidak valid. Silakan pilih laporan yang valid.";
        });
        if (mounted) {
          _showSnackBar("Document ID tidak valid", Colors.red);
        }
        return;
      }
      
      final doc = await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.docId)
          .get();

      print('Document exists: ${doc.exists}');

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('Document data: $data');
        
        setState(() {
          _reportData = data;
          _error = null;
        });
        
        _updateControllersSafely(data);
      } else {
        setState(() {
          _isLoading = false;
          _error = "Laporan tidak ditemukan";
        });
        
        if (mounted) {
          _showSnackBar("Laporan tidak ditemukan", Colors.red);
        }
      }
    } catch (e) {
      print('Error loading report: $e');
      setState(() {
        _isLoading = false;
        _error = "Error memuat laporan: $e";
      });
      
      if (mounted) {
        _showSnackBar("Error memuat laporan: $e", Colors.red);
      }
    }
  }

  // Update controllers dengan mapping field yang benar dari Firestore
  void _updateControllersSafely(Map<String, dynamic> data) {
    if (_isUpdatingFromStream) return;
    
    print('=== UPDATING CONTROLLERS ===');
    print('Raw data: $data');
    
    // Berdasarkan screenshot Firestore, field yang benar adalah:
    final newDescription = data['description'] ?? // Field utama
                          data['deskripsi'] ?? 
                          data['desc'] ?? 
                          '';
                          
    final newLocation = data['location'] ?? // Field utama
                       data['lokasi'] ?? 
                       data['alamat'] ?? 
                       '';
                       
    final newImageUrl = data['image_url'] ?? // Field utama
                       data['imageUrl'] ?? 
                       data['gambar'] ?? 
                       '';

    print('Extracted - Description: "$newDescription"');
    print('Extracted - Location: "$newLocation"');
    print('Extracted - ImageUrl: "$newImageUrl"');

    // Update controllers
    if (newDescription != _lastDescription && 
        !_descriptionController.selection.isValid) {
      _descriptionController.text = newDescription;
      _lastDescription = newDescription;
    }

    if (newLocation != _lastLocation && 
        !_locationController.selection.isValid) {
      _locationController.text = newLocation;
      _lastLocation = newLocation;
    }

    if (newImageUrl != _lastImageUrl) {
      setState(() {
        imageUrl = newImageUrl;
        _lastImageUrl = newImageUrl;
        _isLoading = false;
      });
    } else if (_isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk memilih gambar dari galeri atau kamera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _image = File(pickedFile.path);
          });
        } else {
          setState(() {
            _image = File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        _showSnackBar("Error memilih gambar: $e", Colors.red);
      }
    }
  }

  // Fungsi untuk meng-upload gambar ke server Laravel
  Future<String?> _uploadImage() async {
    if (_image == null && _webImageBytes == null) return null;

    try {
      // Sesuaikan URL dengan server Laravel Anda
      final uri = Uri.parse('http://127.0.0.1:8000/api/upload');
      var request = http.MultipartRequest('POST', uri);

      if (kIsWeb && _webImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          _webImageBytes!,
          filename: 'laporan_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));
      } else if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image', 
          _image!.path
        ));
      }

      final response = await request.send();
      final respStr = await http.Response.fromStream(response);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(respStr.body);
        return responseData['url'];
      } else {
        throw Exception('HTTP ${response.statusCode}: ${respStr.body}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        _showSnackBar("Error upload gambar: $e", Colors.red);
      }
      return null;
    }
  }

  // Fungsi untuk menyimpan perubahan laporan di Firestore
  Future<void> _saveReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("User tidak terautentikasi", Colors.red);
      return;
    }

    // Validasi input
    if (_descriptionController.text.trim().isEmpty) {
      _showSnackBar("Deskripsi tidak boleh kosong", Colors.red);
      return;
    }

    if (_locationController.text.trim().isEmpty) {
      _showSnackBar("Lokasi tidak boleh kosong", Colors.red);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      _isUpdatingFromStream = true;
      
      String? newImageUrl;

      // Upload gambar baru jika ada
      if (_image != null) {
        newImageUrl = await _uploadImage();
        if (newImageUrl == null) {
          throw Exception('Gagal upload gambar');
        }
      }

      // Siapkan data untuk update - gunakan field name yang konsisten
      Map<String, dynamic> updateData = {
        'description': _descriptionController.text.trim(), // Field utama
        'location': _locationController.text.trim(), // Field utama
        'timestamp': FieldValue.serverTimestamp(),
        'user_id': user.uid,
      };

      // Tambahkan URL gambar baru jika ada
      if (newImageUrl != null) {
        updateData['image_url'] = newImageUrl;
      }

      // Update dokumen di Firestore
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.docId)
          .update(updateData);

      // Update variabel tracking
      _lastDescription = _descriptionController.text.trim();
      _lastLocation = _locationController.text.trim();
      if (newImageUrl != null) {
        _lastImageUrl = newImageUrl;
      }

      if (mounted) {
        _showSnackBar("Laporan berhasil diperbarui", Colors.green);
        
        // Reset gambar yang dipilih
        setState(() {
          _image = null;
          _webImageBytes = null;
        });
      }
    } catch (e) {
      print('Error saving report: $e');
      if (mounted) {
        _showSnackBar("Gagal menyimpan laporan: $e", Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        _isUpdatingFromStream = false;
      });
    }
  }

  // Fungsi untuk menghapus laporan
  Future<void> _deleteReport() async {
    final confirmed = await _showDeleteConfirmation();
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.docId)
          .delete();

      if (mounted) {
        _showSnackBar("Laporan berhasil dihapus", Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error deleting report: $e');
      if (mounted) {
        _showSnackBar("Gagal menghapus laporan: $e", Colors.red);
      }
    }
  }

  // Dialog konfirmasi hapus
  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus laporan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan gambar
  Widget _buildImageWidget() {
    if (_image != null) {
      return kIsWeb 
          ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
          : Image.file(_image!, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return const Center(
            child: Icon(Icons.error, size: 50, color: Colors.red),
          );
        },
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 50, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'Tap untuk memilih gambar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
  }

  // Helper untuk menampilkan snackbar
  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _isUpdatingFromStream = false;
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "Detail Laporan", 
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)
          ),
          iconTheme: const IconThemeData(color: Colors.teal),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>( 
      stream: _reportStream, 
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('StreamBuilder error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isSubmitting) {
              _updateControllersSafely(data);
            }
          });
        } else if (snapshot.hasData && !snapshot.data!.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showSnackBar("Laporan telah dihapus", Colors.orange);
              Navigator.pop(context);
            }
          });
          return const Center(
            child: Text('Laporan tidak ditemukan atau telah dihapus'),
          );
        }

        return _buildReportForm();
      },
    );
  }

  Widget _buildReportForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Debug info (hapus di production)
          if (kDebugMode) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('DocID: "${widget.docId}"', style: TextStyle(fontSize: 11)),
                  Text('Data loaded: ${_reportData != null}', style: TextStyle(fontSize: 11)),
                  if (_reportData != null) 
                    Text('Available fields: ${_reportData!.keys.toList()}', style: TextStyle(fontSize: 11)),
                  Text('Description: "${_descriptionController.text}"', style: TextStyle(fontSize: 11)),
                  Text('Location: "${_locationController.text}"', style: TextStyle(fontSize: 11)),
                  Text('ImageURL: "${imageUrl ?? 'null'}"', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Bagian Bukti Gambar
          const Text(
            "Bukti Gambar",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal
            )
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _isSubmitting ? null : _showImageSourceDialog,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildImageWidget(),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bagian Deskripsi Kerusakan
          const Text(
            "Deskripsi Kerusakan",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal
            )
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              hintText: "Masukkan deskripsi kerusakan...",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.teal),
              ),
            ),
            maxLines: 4,
            onChanged: (value) {
              _lastDescription = value;
            },
          ),
          const SizedBox(height: 20),

          // Bagian Lokasi
          const Text(
            "Lokasi",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal
            )
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _locationController,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              hintText: "Masukkan lokasi...",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.teal),
              ),
            ),
            onChanged: (value) {
              _lastLocation = value;
            },
          ),
          const SizedBox(height: 30),

          // Tombol Simpan
          Center(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _saveReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("Simpan Perubahan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 15),

          // Tombol Hapus Laporan
          Center(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _deleteReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
              child: const Text("Hapus Laporan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog untuk memilih sumber gambar
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Sumber Gambar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
          ],
        ),
      ),
    );
  }
}