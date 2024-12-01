import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatelessWidget {
  final MapController mapController;
  final LatLng currentPosition;
  final double currentZoom;
  final bool locationFetched;

  MapPage(this.mapController, this.currentPosition, this.currentZoom, this.locationFetched);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        center: currentPosition,
        zoom: currentZoom,
        interactiveFlags: InteractiveFlag.all,
      ),
      children: [
        TileLayer(
          urlTemplate: "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: locationFetched ? currentPosition : LatLng(22.580321, 113.938796),
              builder: (ctx) => Container(
                child: Icon(Icons.navigation, color: Colors.red, size: 40),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
