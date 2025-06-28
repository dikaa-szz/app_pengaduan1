import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';

// Kelas untuk data chart kategori
class ChartData {
  final String category;
  final int count;

  ChartData(this.category, this.count);
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> reports = [];
  List<ChartData> chartData = [];
  Position? userPosition;
  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
    _fetchSpotLocations();
    _getUserLocation();
  }

  _fetchReports() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('reports').get();
      var reportsList = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        reports = reportsList;
        _generateChartData();
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching reports: $e");
    }
  }

  _fetchSpotLocations() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('spots').get();
      var spotList = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        markers = spotList.map((spot) {
          // Gunakan konversi aman dari num ke double
          double lat = (spot['latitude'] as num).toDouble();
          double lon = (spot['longitude'] as num).toDouble();

          if (lat != 0.0 && lon != 0.0) {
            return Marker(
              point: LatLng(lat, lon),
              width: 40.0,
              height: 40.0,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(spot['title'] ?? 'No Title'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kategori: ${spot['category'] ?? 'Tidak Ada'}'),
                          Text('Deskripsi: ${spot['description'] ?? 'Tidak Ada'}'),
                          Text('Lat: $lat'),
                          Text('Lng: $lon'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Tutup'),
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(
                  Icons.location_on,
                  color: const Color.fromARGB(255, 18, 77, 133),
                  size: 40.0,
                ),
              ),
            );
          } else {
            return null;
          }
        }).where((marker) => marker != null).cast<Marker>().toList();
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching spot locations: $e");
    }
  }

  _generateChartData() {
    Map<String, int> categoryCounts = {};

    for (var report in reports) {
      String category = report['report_type'] ?? 'Other';
      category = category.isEmpty ? 'Other' : category;
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    chartData = categoryCounts.entries.map((entry) {
      return ChartData(entry.key, entry.value);
    }).toList();
  }

  _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: 'Layanan lokasi tidak aktif.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        Fluttertoast.showToast(msg: 'Izin lokasi ditolak.');
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      userPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Color.fromARGB(255, 76, 178, 182),
      ),
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Maps Lokasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(userPosition?.latitude ?? -2.548926, userPosition?.longitude ?? 118.014863),
                    zoom: 5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    ),
                    MarkerLayer(
                      markers: markers,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  'Jumlah Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DataTable(
                  columns: [
                    DataColumn(
                      label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Count', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  rows: chartData.map((category) {
                    return DataRow(cells: [
                      DataCell(Text(category.category)),
                      DataCell(Text('${category.count}')),
                    ]);
                  }).toList(),
                ),
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${chartData.fold(0, (sum, item) => sum + item.count)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
