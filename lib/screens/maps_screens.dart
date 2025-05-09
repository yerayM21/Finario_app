import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsScreen extends StatelessWidget {
  
   MapsScreen({super.key});

  final List<Map<String, dynamic>> branches = [
    {
      'name': 'Sucursal Centro',
      'position': LatLng(19.4326, -99.1332),
      'address': 'Av. Juárez 12, Centro Histórico'
    },
    {
      'name': 'Sucursal Polanco',
      'position': LatLng(19.4338, -99.1934),
      'address': 'Av. Presidente Masaryk 45'
    },
    {
      'name': 'Sucursal Condesa',
      'position': LatLng(19.4119, -99.1735),
      'address': 'Av. Michoacán 54'
    },
    {
      'name': 'Sucursal Santa Fe',
      'position': LatLng(19.3594, -99.2591),
      'address': 'Centro Comercial Santa Fe'
    },
    {
      'name': 'Sucursal Coyoacán',
      'position': LatLng(19.3464, -99.1613),
      'address': 'Av. Francisco Sosa 45'
    },
  ];

  Future<void> _openMapsApp(LatLng position) async {
    final url = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${position.latitude}&mlon=${position.longitude}#map=17/${position.latitude}/${position.longitude}'
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuestras Sucursales'),
      ),
      body: FlutterMap(
        mapController: MapController(),
        options: MapOptions(
          initialCenter: branches[0]['position'] as LatLng,
          initialZoom: 12.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              for (final branch in branches)
                Marker(
                  point: branch['position'] as LatLng,
                  width: 80.0,
                  height: 80.0,
                  child: GestureDetector(
                    onTap: () => _showBranchDetails(context, branch),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.red, size: 40),
                        Text(
                          branch['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBranchDetails(BuildContext context, Map<String, dynamic> branch) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              branch['name'] as String,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            Text(branch['address'] as String),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.directions),
                label: const Text('Abrir en mapa externo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () => _openMapsApp(branch['position'] as LatLng),
              ),
            ),
          ],
        ),
      ),
    );
  }
}