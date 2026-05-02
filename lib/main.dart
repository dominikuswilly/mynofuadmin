import 'package:flutter/material.dart';
import 'theme.dart';
import 'login_screen.dart';

void main() {
  runApp(const MyNofuAdminApp());
}

class MyNofuAdminApp extends StatelessWidget {
  const MyNofuAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOFU Coffee Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
