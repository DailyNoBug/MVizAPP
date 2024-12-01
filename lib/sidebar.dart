import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final VoidCallback onHide;
  final ValueChanged<int> onSelectPage;
  final int selectedIndex;

  Sidebar({required this.onHide, required this.onSelectPage, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: Colors.blueGrey[50],
      child: Column(
        children: <Widget>[
          Container(
            color: Colors.lightBlue,
            child: ListTile(
              leading: Icon(Icons.dehaze),
              title: Text('Mountaion Fly Viz'),
              onTap: onHide,
            ),
          ),
          Expanded(
            child: ListView(
              children: <Widget>[
                _buildSidebarItem('飞行信息', 0),
                _buildSidebarItem('飞行数据', 1),
                _buildSidebarItem('系统设置', 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String title, int index) {
    return Container(
      color: selectedIndex == index ? Colors.blue[100] : Colors.transparent,
      child: ListTile(
        title: Text(title),
        onTap: () => onSelectPage(index),
      ),
    );
  }
}
