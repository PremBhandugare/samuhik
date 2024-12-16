import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:samuhik/data/ngodata.dart'; 
class MapScr extends StatefulWidget {
  const MapScr({super.key});

  @override
  MapScrState createState() => MapScrState();
}

class MapScrState extends State<MapScr> {
  final MapController _mapController = MapController();
  int _selectedNgoIndex = -1;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCity(String cityName) async {
    if (cityName.isEmpty) return;
    setState(() => _isSearching = true);
    const apiKey = 'oyLqwKTDuilIERXSgG5B'; // Your API Key
    final encodedCity = Uri.encodeComponent(cityName);
    final url = 'https://api.maptiler.com/geocoding/$encodedCity.json?key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'].isNotEmpty) {
          final coordinates = data['features'][0]['center'];
          double zoomLevel = 12.0;
          final placeType = data['features'][0]['place_type']?[0];
          if (placeType != null) {
            switch (placeType) {
              case 'country':
                zoomLevel = 5.0;
                break;
              case 'region':
              case 'state':
                zoomLevel = 7.0;
                break;
              case 'city':
                zoomLevel = 12.0;
                break;
              case 'district':
              case 'locality':
                zoomLevel = 14.0;
                break;
              default:
                zoomLevel = 12.0;
            }
          }
          _mapController.move(LatLng(coordinates[1], coordinates[0]), zoomLevel);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not found')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching location: $e')),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(23.5937, 78.9629),
              initialZoom: 5.0,
              onTap: (_, __) => setState(() => _selectedNgoIndex = -1),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=oyLqwKTDuilIERXSgG5B',
              ),
              MarkerLayer(
                markers: List.generate(ngoData.length, (index) {
                  final ngo = ngoData[index];
                  return Marker(
                    point: LatLng(ngo['Latitude'], ngo['Longitude']),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedNgoIndex = index),
                      child: Icon(
                        Icons.location_on,
                        color: _selectedNgoIndex == index ? Colors.red : Colors.blue,
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
              CircleLayer(
                circles: ngoData.map((ngo) {
                  return CircleMarker(
                    point: LatLng(ngo['Latitude'], ngo['Longitude']),
                    radius: 10,
                    color: Colors.red.withOpacity(0.3),
                    borderColor: Colors.red,
                    borderStrokeWidth: 2,
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search location...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (value) => _searchCity(value),
                      ),
                    ),
                    if (_isSearching)
                      Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(8),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _searchCity(_searchController.text),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedNgoIndex != -1)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.business, color: Theme.of(context).colorScheme.primary, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ngoData[_selectedNgoIndex]['NGO Name'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_city, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'City: ${ngoData[_selectedNgoIndex]['City']}',
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Address: ${ngoData[_selectedNgoIndex]['Address']}',
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Description: ${ngoData[_selectedNgoIndex]['Description']}',
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
