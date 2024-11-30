import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isSidebarVisible = true;
  double _currentZoom = 13.0;
  final MapController _mapController = MapController();
  LatLng _currentPosition = LatLng(22.580321, 113.938796); // 默认位置（大疆天空之城）
  bool _locationFetched = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // 隐藏系统任务栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      // setState(() {
      //   _currentPosition = LatLng(position.latitude, position.longitude);
      //   _locationFetched = true;
      // });
      Future.error("没有适配");
    } catch (e) {
      print("无法获取位置: $e");
      // 如果无法获取位置，保持默认位置
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          if (_isSidebarVisible)
            Container(
              width: 200,
              color: Colors.blueGrey[50],
              child: Column(
                children: <Widget>[
                  Container(
                    color: Colors.blue,
                    child: ListTile(
                      leading: Icon(Icons.arrow_left),
                      title: Text('隐藏'),
                      onTap: () {
                        setState(() {
                          _isSidebarVisible = false;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Mountaion Fly Viz'),
                  ),
                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        ListTile(
                          title: Text('地图'),
                          onTap: () {
                            setState(() {
                              _selectedIndex = 0;
                            });
                          },
                        ),
                        ListTile(
                          title: Text('数据可视化'),
                          onTap: () {
                            setState(() {
                              _selectedIndex = 1;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                _selectedIndex == 0 ? buildMap() : buildDataVisualization(),
                if (!_isSidebarVisible)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(20),
                        backgroundColor: Colors.blue, // 背景颜色
                      ),
                      child: Icon(Icons.arrow_right, size: 30, color: Colors.white),
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

  Widget buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _currentPosition,
        zoom: _currentZoom,
        interactiveFlags: InteractiveFlag.all, // 启用所有交互手势
      ),
      children: [
        TileLayer(
          urlTemplate: "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _locationFetched ? _currentPosition : LatLng(22.580321, 113.938796), // 显示当前位置或默认位置
              builder: (ctx) => Container(
                child: Icon(Icons.navigation, color: Colors.red, size: 40),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildDataVisualization() {
    return Center(
      child: Text('数据可视化页面'),
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

