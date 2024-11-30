import 'package:flutter/material.dart';
import 'splash_screen.dart'; // 导入 SplashScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline OSM App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // 将 HomePage 替换为 SplashScreen
    );
  }
}
