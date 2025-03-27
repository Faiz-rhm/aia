import 'package:flutter/material.dart';

import 'src/constants/app_colors.dart';

import 'src/home_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: AppColors.backgroundColor
      ),
      home: const HomeScreen(),
    );
  }
}

