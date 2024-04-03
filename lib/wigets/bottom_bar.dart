import 'package:flutter/material.dart';

List<BottomNavigationBarItem> bottomNavBarItems() {
  return const [
    BottomNavigationBarItem(
      icon: Icon(Icons.device_hub),
      label: 'Peers',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.wifi),
      label: 'Broadcast',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.work_outline_sharp),
      label: 'TestData',
    ),
  ];
}