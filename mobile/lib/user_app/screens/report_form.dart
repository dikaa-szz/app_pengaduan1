import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class ReportFormPage extends StatefulWidget {
  const ReportFormPage({super.key});

  @override
  _ReportFormPageState createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  final _descriptionController = TextEditingController();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  File? _image;
  Uint8List? _webImageBytes;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();
  double? latitude;
  double? longitude;
  String? _locationName;

  final List<String> _reportTypes = ['Jalan Rusak', 'Fasilitas Umum', 'Lalin & Lampu Jalan'];
  String _selectedReportType = 'Jalan Rusak';

  Future<void> _getLocationFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      setState(() {
        latitude = locations.first.latitude;
        longitude = locations.first.longitude;
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _showMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(
          onLocationSelected: (selectedLatitude, selectedLongitude, selectedAddress) {
            setState(() {
              latitude = selectedLatitude;
              longitude = selectedLongitude;
              _locationName = selectedAddress;
              _locationController.text = selectedAddress;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _image = File('');
        });
      } else {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _submitReport() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _image == null ||
        latitude == null ||
        longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Harap isi semua data dan pilih gambar.")),
      );
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Anda belum login.")),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
      final userId = user.uid;

      var uri = Uri.parse('http://127.0.0.1:8000/api/upload');
      var request = http.MultipartRequest('POST', uri);

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          _webImageBytes!,
          filename: 'laporan.jpg',
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        String imageUrl = responseData['url'];

        await FirebaseFirestore.instance.collection('reports').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'location': _locationController.text,
          'report_type': _selectedReportType,
          'status': 'Menunggu Verifikasi',
          'timestamp': FieldValue.serverTimestamp(),
          'user_id': userId,
          'image_url': imageUrl,
          'latitude': latitude,
          'longitude': longitude,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Laporan berhasil dikirim!")),
        );

        _descriptionController.clear();
        _titleController.clear();
        _locationController.clear();
        setState(() {
          _image = null;
          _webImageBytes = null;
          _selectedReportType = _reportTypes[0];
          latitude = null;
          longitude = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal upload gambar ke server.")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan, coba lagi.")),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Form Laporan"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.camera_alt, color: Colors.teal),
                        title: Text("Ambil dari Kamera"),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.image, color: Colors.teal),
                        title: Text("Pilih dari Galeri"),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _image == null
                      ? Icon(Icons.image, size: 50, color: Colors.teal)
                      : kIsWeb
                          ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                          : Image.file(_image!, fit: BoxFit.cover),
                ),
              ),
              SizedBox(height: 20),

              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Judul Kerusakan",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 20),

              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Deskripsi Kerusakan",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 20),

              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: "Lokasi Kejadian",
                  hintText: "Klik untuk memilih lokasi",
                  prefixIcon: Icon(Icons.location_on, color: Colors.teal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onTap: _showMap,
                readOnly: true,
              ),
              SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedReportType,
                onChanged: (value) {
                  setState(() {
                    _selectedReportType = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: "Jenis Laporan",
                  prefixIcon: Icon(Icons.report_problem, color: Colors.teal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _reportTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
              ),
              SizedBox(height: 30),

              _isSubmitting
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        "Kirim Laporan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  final Function(double latitude, double longitude, String address) onLocationSelected;

  const MapPage({super.key, required this.onLocationSelected});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng _selectedLocation = LatLng(-7.7956, 110.3694); // Default location (Yogyakarta)
  
  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      // Tambahkan delay untuk memastikan permintaan tidak terlalu cepat
      await Future.delayed(Duration(milliseconds: 500));
      
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      print("Placemarks found: ${placemarks.length}"); // Debug log
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        print("Placemark details: ${place.toString()}"); // Debug log
        
        // Prioritaskan komponen alamat yang lebih relevan
        List<String> addressParts = [];
        
        // Tambahkan nama jalan/tempat terlebih dahulu
        if (place.name != null && place.name!.isNotEmpty && place.name != place.street) {
          addressParts.add(place.name!);
        }
        
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        
        if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty && place.thoroughfare != place.street) {
          addressParts.add(place.thoroughfare!);
        }
        
        if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          addressParts.add("No. ${place.subThoroughfare!}");
        }
        
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        
        // Tambahkan wilayah administratif
        if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          addressParts.add(place.subAdministrativeArea!);
        }
        
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }
        
        // Gabungkan semua bagian alamat dan hilangkan duplikasi
        List<String> uniqueParts = [];
        for (String part in addressParts) {
          if (!uniqueParts.contains(part) && part.trim().isNotEmpty) {
            uniqueParts.add(part.trim());
          }
        }
        
        String fullAddress = uniqueParts.join(', ');
        print("Generated address: $fullAddress"); // Debug log
        
        // Jika alamat terlalu pendek atau kosong, coba format alternatif
        if (fullAddress.isEmpty || fullAddress.length < 5) {
          String alternativeAddress = "";
          
          if (place.locality != null && place.locality!.isNotEmpty) {
            alternativeAddress = place.locality!;
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            if (alternativeAddress.isNotEmpty) {
              alternativeAddress += ", ${place.administrativeArea!}";
            } else {
              alternativeAddress = place.administrativeArea!;
            }
          }
          if (place.country != null && place.country!.isNotEmpty) {
            if (alternativeAddress.isNotEmpty) {
              alternativeAddress += ", ${place.country!}";
            } else {
              alternativeAddress = place.country!;
            }
          }
          
          if (alternativeAddress.isNotEmpty) {
            return alternativeAddress;
          }
        }
        
        // Jika berhasil mendapat alamat yang cukup detail
        if (fullAddress.isNotEmpty && fullAddress.length >= 5) {
          return fullAddress;
        }
      }
      
      // Fallback: jika gagal mendapat alamat yang bagus, return koordinat dengan format yang rapi
      return "Koordinat: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}";
      
    } catch (e) {
      print("Error getting address: $e");
      // Jika ada error, tetap return koordinat
      return "Koordinat: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}";
    }
  }

  Future<void> _onMapTap(LatLng location) async {
    setState(() {
      _selectedLocation = location;
    });
    
    // Tampilkan loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Mengambil informasi lokasi..."),
          ],
        ),
      ),
    );
    
    // Ambil alamat dari koordinat
    String address = await _getAddressFromCoordinates(location.latitude, location.longitude);
    
    // Tutup loading dialog
    Navigator.pop(context);
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Konfirmasi Lokasi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Lokasi yang dipilih:", style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                address, 
                style: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(height: 12),
            Text("Koordinat:", style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            Text(
              "${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              widget.onLocationSelected(location.latitude, location.longitude, address);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: Text("Pilih Lokasi", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pilih Lokasi"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Cara Penggunaan"),
                  content: Text("Ketuk pada peta untuk memilih lokasi kejadian. Marker merah akan muncul di lokasi yang dipilih."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("OK"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: _selectedLocation,
          zoom: 15.0,
          onTap: (tapPosition, point) => _onMapTap(point),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedLocation,
                width: 50.0,
                height: 50.0,
                child: GestureDetector(
                  onTap: () async {
                    // Tampilkan loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        content: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Text("Mengambil alamat..."),
                          ],
                        ),
                      ),
                    );
                    
                    // Ambil alamat dari koordinat
                    String address = await _getAddressFromCoordinates(
                      _selectedLocation.latitude, 
                      _selectedLocation.longitude
                    );
                    
                    // Tutup loading dialog
                    Navigator.pop(context);
                    
                    // Panggil callback dengan alamat yang sudah didapat
                    widget.onLocationSelected(_selectedLocation.latitude, _selectedLocation.longitude, address);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Tampilkan loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text("Mengambil alamat..."),
                ],
              ),
            ),
          );
          
          // Ambil alamat dari koordinat
          String address = await _getAddressFromCoordinates(
            _selectedLocation.latitude, 
            _selectedLocation.longitude
          );
          
          // Tutup loading dialog
          Navigator.pop(context);
          
          // Panggil callback dengan alamat yang sudah didapat
          widget.onLocationSelected(_selectedLocation.latitude, _selectedLocation.longitude, address);
        },
        backgroundColor: Colors.teal,
        icon: Icon(Icons.check, color: Colors.white),
        label: Text("Pilih Lokasi Ini", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}