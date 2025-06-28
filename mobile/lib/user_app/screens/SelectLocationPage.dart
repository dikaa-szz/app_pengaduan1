import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key});

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  LatLng _selectedLocation = LatLng(-7.7956, 110.3695);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pilih Lokasi"),
        backgroundColor: Colors.teal,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedLocation);
            },
            child: Text("PILIH", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          center: _selectedLocation,
          zoom: 15,
          onTap: (tapPosition, point) {
            setState(() {
              _selectedLocation = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedLocation,
                width: 40,
                height: 40,
                child: Icon(Icons.location_pin, color: Colors.red, size: 40),
              )
            ],
          ),
        ],
      ),
    );
  }
}
