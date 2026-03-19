import 'package:flutter/material.dart';
import '../gateway/api_gateway.dart';
import 'layout/main_layout.dart';

void main() {
  AppGateway.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home:   MainLayout(),
    );
  }
}