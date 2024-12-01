import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';

class DataVisualizationPage extends StatefulWidget {
  @override
  _DataVisualizationPageState createState() => _DataVisualizationPageState();
}

class _DataVisualizationPageState extends State<DataVisualizationPage> {
  bool showCpuChart = true;
  bool showCoreChart = true;
  bool showMemoryChart = true;

  List<double> cpuUsage = [];
  List<List<double>> coreUsage = List.generate(8, (_) => []);
  double memoryUsed = 0;
  double memoryTotal = 8; // Example total memory

  UsbPort? _port;
  Timer? _timer;
  int _currentIndex = 0;
  List<double> _testCpuData = [];
  List<List<double>> _testCoreData = List.generate(8, (_) => []);
  List<double> _testMemoryUsed = [];

  final int visibleDataPoints = 20; // Number of visible data points

  Object? _aircraft;

  @override
  void initState() {
    super.initState();
    _startUsbListener();
    _initialize3DModel();
  }

  void _initialize3DModel() {
    _aircraft = Object(
      fileName: 'assets/drone.obj', // 确保你有一个 3D 模型文件
    );
  }

  void _updateAircraftAttitude(double yaw, double pitch, double roll) {
    setState(() {
      _aircraft?.rotation.setValues(pitch, yaw, roll);
    });
  }

  void _startUsbListener() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isNotEmpty) {
      _port = await devices.first.create();
      if (await _port!.open()) {
        _port!.setPortParameters(
          9600,
          UsbPort.DATABITS_8,
          UsbPort.STOPBITS_1,
          UsbPort.PARITY_NONE,
        );

        _port!.inputStream!.listen((data) {
          final dataString = utf8.decode(data);
          _processData(dataString);
        });
      }
    }
  }

  void _processData(String data) {
    try {
      final jsonData = json.decode(data);
      setState(() {
        cpuUsage.add(jsonData['cpu']);
        for (int i = 0; i < 8; i++) {
          coreUsage[i].add(jsonData['cores'][i]);
        }
        memoryUsed = jsonData['memoryUsed'];

        // 更新飞行器姿态
        double yaw = jsonData['yaw'];
        double pitch = jsonData['pitch'];
        double roll = jsonData['roll'];
        _updateAircraftAttitude(yaw, pitch, roll);
      });
    } catch (e) {
      print("Data parsing error: $e");
    }
  }

  void _generateTestData() {
    Random random = Random();
    _testCpuData = List.generate(200, (_) => random.nextDouble() * 100);
    _testCoreData = List.generate(8, (_) => List.generate(200, (_) => random.nextDouble() * 100));
    _testMemoryUsed = List.generate(200, (_) => random.nextDouble() * memoryTotal);
    _currentIndex = 0;

    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (_currentIndex >= 200) {
        timer.cancel();
      } else {
        setState(() {
          cpuUsage.add(_testCpuData[_currentIndex]);
          for (int i = 0; i < 8; i++) {
            coreUsage[i].add(_testCoreData[i][_currentIndex]);
          }
          memoryUsed = _testMemoryUsed[_currentIndex];
        });
        _currentIndex++;
      }
    });
  }

  void _resetData() {
    setState(() {
      cpuUsage.clear();
      for (var core in coreUsage) {
        core.clear();
      }
      memoryUsed = 0;
    });
  }

  Future<void> _exportData() async {
    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath();

      if (directoryPath != null) {
        final fileName = 'data_log.txt';
        final filePath = '$directoryPath/$fileName';

        final file = File(filePath);
        StringBuffer buffer = StringBuffer();
        buffer.writeln('CPU Usage:');
        for (var usage in cpuUsage) {
          buffer.writeln(usage.toString());
        }

        buffer.writeln('\nCore Usage:');
        for (int i = 0; i < coreUsage.length; i++) {
          buffer.writeln('Core $i:');
          for (var usage in coreUsage[i]) {
            buffer.writeln(usage.toString());
          }
        }

        buffer.writeln('\nMemory Used: $memoryUsed GB');

        await file.writeAsString(buffer.toString());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data exported to $filePath')),
        );
      }
    } catch (e) {
      print("Error exporting data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export data')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _port?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Visualization Page'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _generateTestData,
                  child: Text('Generate Test Data'),
                ),
                ElevatedButton(
                  onPressed: _resetData,
                  child: Text('Reset Data'),
                ),
                ElevatedButton(
                  onPressed: _exportData,
                  child: Text('Export Data'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildToggleableChart(
                    title: 'CPU Usage',
                    showChart: showCpuChart,
                    onToggle: () => setState(() => showCpuChart = !showCpuChart),
                    child: _buildCpuLineChart(),
                  ),
                ),
                Expanded(
                  child: _buildToggleableChart(
                    title: 'Core Usage',
                    showChart: showCoreChart,
                    onToggle: () => setState(() => showCoreChart = !showCoreChart),
                    child: _buildCoreLineChart(),
                  ),
                ),
              ],
            ),
            _buildToggleableChart(
              title: 'Memory Usage',
              showChart: showMemoryChart,
              onToggle: () => setState(() => showMemoryChart = !showMemoryChart),
              child: _buildMemoryPieChart(),
            ),
            _build3DView(), // 添加 3D 视图模块
          ],
        ),
      ),
    );
  }

  Widget _buildToggleableChart({
    required String title,
    required bool showChart,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Column(
        children: [
          ListTile(
            title: Text(title),
            trailing: IconButton(
              icon: Icon(showChart ? Icons.expand_less : Icons.expand_more),
              onPressed: onToggle,
            ),
          ),
          if (showChart) child,
        ],
      ),
    );
  }

  Widget _buildCpuLineChart() {
    return Container(
      height: 200,
      padding: EdgeInsets.all(8),
      child: LineChart(
        LineChartData(
          minX: cpuUsage.length > visibleDataPoints
              ? cpuUsage.length - visibleDataPoints.toDouble()
              : 0,
          maxX: cpuUsage.length.toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: cpuUsage.asMap().entries
                  .where((e) => e.key >= (cpuUsage.length - visibleDataPoints))
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: Colors.blue,
              dotData: FlDotData(show: false),  // Hide the dots
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreLineChart() {
    return Container(
      height: 200,
      padding: EdgeInsets.all(8),
      child: LineChart(
        LineChartData(
          minX: coreUsage[0].length > visibleDataPoints
              ? coreUsage[0].length - visibleDataPoints.toDouble()
              : 0,
          maxX: coreUsage[0].length.toDouble(),
          lineBarsData: List.generate(8, (index) {
            return LineChartBarData(
              spots: coreUsage[index]
                  .asMap()
                  .entries
                  .where((e) => e.key >= (coreUsage[index].length - visibleDataPoints))
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: Colors.red,
              dotData: FlDotData(show: false),  // Hide the dots
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMemoryPieChart() {
    return Container(
      height: 200,
      padding: EdgeInsets.all(8),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: memoryUsed,
              title: '${memoryUsed.toStringAsFixed(1)} GB',
              color: Colors.blue,
            ),
            PieChartSectionData(
              value: memoryTotal - memoryUsed,
              title: '${(memoryTotal - memoryUsed).toStringAsFixed(1)} GB',
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DView() {
    return _buildToggleableChart(
      title: '3D Model',
      showChart: true, // 初始状态是否展开
      onToggle: () {
        setState(() {
          // 切换显示状态
        });
      },
      child: Container(
        height: 300,
        child: Row(
          children: [
            Expanded(
              child: Cube(
                onSceneCreated: (Scene scene) {
                  scene.world.add(_aircraft!);

                  // 添加立体坐标系（X, Y, Z轴）
                  var axis = Object(
                    scale: Vector3.all(1.0),
                    children: [
                      // X轴 - 红色
                      Object(
                        position: Vector3(5, 0, 0),
                        backfaceCulling: false,
                        scale: Vector3(10, 0.1, 0.1), // 更长的X轴
                        lighting: true,
                        // color: Color.fromARGB(255, 255, 0, 0), // 红色
                      ),
                      // Y轴 - 绿色
                      Object(
                        position: Vector3(0, 5, 0),
                        backfaceCulling: false,
                        scale: Vector3(0.1, 10, 0.1), // 更长的Y轴
                        lighting: true,
                        // color: Color.fromARGB(255, 0, 255, 0), // 绿色
                      ),
                      // Z轴 - 蓝色
                      Object(
                        position: Vector3(0, 0, 5),
                        backfaceCulling: false,
                        scale: Vector3(0.1, 0.1, 10), // 更长的Z轴
                        lighting: true,
                        // color: Color.fromARGB(255, 0, 0, 255), // 蓝色
                      ),
                    ],
                  );

                  scene.world.add(axis);
                  scene.camera.zoom = 10;
                },
              ),
            ),
            Container(
              width: 100,
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yaw: ${_aircraft?.rotation.y.toStringAsFixed(2)}°'),
                  Text('Pitch: ${_aircraft?.rotation.x.toStringAsFixed(2)}°'),
                  Text('Roll: ${_aircraft?.rotation.z.toStringAsFixed(2)}°'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}