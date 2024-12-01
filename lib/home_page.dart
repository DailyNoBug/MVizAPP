import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'sidebar.dart';
import 'map_page.dart';
import 'data_visualization_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Default to map page
  bool _isSidebarVisible = true;
  double _currentZoom = 13.0;
  final MapController _mapController = MapController();
  LatLng _currentPosition = LatLng(22.580321, 113.938796);
  bool _locationFetched = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
  }

  Future<void> _getCurrentLocation() async {
    try {
      Future.error("没有适配");
    } catch (e) {
      print("无法获取位置: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          if (_isSidebarVisible)
            Sidebar(
              onHide: () => setState(() => _isSidebarVisible = false),
              onSelectPage: (index) => setState(() => _selectedIndex = index),
              selectedIndex: _selectedIndex,
            ),
          Expanded(
            child: Stack(
              children: [
                if (_selectedIndex == 0)
                  MapPage(_mapController, _currentPosition, _currentZoom, _locationFetched)
                else if (_selectedIndex == 1)
                  DataVisualizationPage()
                else
                  SettingsPage(),
                if (!_isSidebarVisible)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: EdgeInsets.all(20),
                        backgroundColor: Colors.blue,
                      ),
                      child: Icon(Icons.dehaze, size: 30, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isSidebarVisible = true;
                        });
                      },
                    ),
                  ),
                if (_selectedIndex == 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          onPressed: _zoomIn,
                          child: Icon(Icons.zoom_in),
                        ),
                        SizedBox(height: 8),
                        FloatingActionButton(
                          onPressed: _zoomOut,
                          child: Icon(Icons.zoom_out),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _zoomIn() {
    setState(() {
      _currentZoom++;
      _mapController.move(_mapController.center, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom--;
      _mapController.move(_mapController.center, _currentZoom);
    });
  }
}
