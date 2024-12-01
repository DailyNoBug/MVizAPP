import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  String _storageUsage = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _loadServerConfig();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设置页面',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildServerConfigOption(),
            SizedBox(height: 20),
            _buildStoragePathOption(),
            SizedBox(height: 20),
            _buildStorageInfo(),
            SizedBox(height: 20),
            _buildClearStorageButton(),
          ],
        ),
      ),
    );
  }

  Future<void> _loadServerConfig() async {
    final config = await loadServerConfig();
    final defaultPath = await getApplicationDocumentsDirectory();

    setState(() {
      _ipController.text = config['server_ip'] ?? '默认IP';
      _portController.text = config['server_port'] ?? '默认端口';
      _userController.text = config['server_user'] ?? '默认用户';
      _passwordController.text = config['server_password'] ?? '默认密码';
      _pathController.text = config['storage_path'] ?? defaultPath.path;
    });

    if (config['storage_path'] == null || config['storage_path']!.isEmpty) {
      await saveStoragePath(defaultPath.path);
    }

    _calculateStorageUsage(_pathController.text);
  }

  Future<void> saveServerConfig(String ip, String port, String user, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
    await prefs.setString('server_port', port);
    await prefs.setString('server_user', user);
    await prefs.setString('server_password', password);
  }

  Future<Map<String, String>> loadServerConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'server_ip': prefs.getString('server_ip') ?? '',
      'server_port': prefs.getString('server_port') ?? '',
      'server_user': prefs.getString('server_user') ?? '',
      'server_password': prefs.getString('server_password') ?? '',
      'storage_path': prefs.getString('storage_path') ?? '',
    };
  }

  Widget _buildServerConfigOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '源服务器配置:',
          style: TextStyle(fontSize: 18),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ipController,
                decoration: InputDecoration(labelText: 'IP Address'),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _portController,
                decoration: InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _userController,
                decoration: InputDecoration(labelText: 'User'),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            String ip = _ipController.text;
            String port = _portController.text;
            String user = _userController.text;
            String password = _passwordController.text;

            await saveServerConfig(ip, port, user, password);

            _showCustomNotification('配置已保存', Colors.green);
          },
          child: Text('保存配置'),
        ),
      ],
    );
  }

  Future<void> saveStoragePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storage_path', path);
  }

  Widget _buildStoragePathOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '存储路径设置:',
          style: TextStyle(fontSize: 18),
        ),
        TextField(
          controller: _pathController,
          readOnly: true,
          decoration: InputDecoration(labelText: 'Storage Path'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            String? path = await FilePicker.platform.getDirectoryPath();
            if (path != null) {
              _pathController.text = path;

              if (await _checkPathWritable(path)) {
                await saveStoragePath(path);
                _showCustomNotification('路径已保存', Colors.green);
              } else if (path.isEmpty) {
                _showCustomNotification('路径为空', Colors.yellow);
              } else {
                _showCustomNotification('路径不可写', Colors.red);
              }
            }
          },
          child: Text('选择路径'),
        ),
      ],
    );
  }

  Future<bool> _checkPathWritable(String path) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final testFile = File('${directory.path}/test.txt');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _calculateStorageUsage(String path) async {
    final directory = Directory(path);
    int totalSize = 0;

    try {
      if (await directory.exists()) {
        final files = directory.listSync(recursive: true);
        for (var file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }
    } catch (e) {
      print('Error calculating storage usage: $e');
    }

    setState(() {
      _storageUsage = '${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    });
  }

  Widget _buildStorageInfo() {
    return Row(
      children: [
        Expanded(
          child: Text(
            '应用存储空间占用: $_storageUsage',
            style: TextStyle(fontSize: 18),
          ),
        ),
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: () {
            _calculateStorageUsage(_pathController.text);
            _showCustomNotification('存储空间已刷新', Colors.green);
          },
        ),
      ],
    );
  }

  Widget _buildClearStorageButton() {
    return ElevatedButton(
      onPressed: () {
        // Logic to clear storage space
      },
      child: Text('清除存储空间占用'),
    );
  }

  void _showCustomNotification(String message, Color color) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20.0,
        right: 10.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(color == Colors.green ? Icons.note : (color == Colors.red ? Icons.error : Icons.warning), color: Colors.white),
                SizedBox(width: 8),
                Text(
                  message,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay?.insert(overlayEntry);
    Future.delayed(Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}
