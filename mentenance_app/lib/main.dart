import 'package:flutter/material.dart';
import 'package:mentenance_app/screens/admin_flow/pages/add_task/add_task_page.dart';
import 'package:mentenance_app/screens/admin_flow/pages/home/home_page.dart';
import 'package:mentenance_app/screens/pages/expenses/expenses.dart';
import 'package:mentenance_app/screens/pages/forget_password/reset_password.dart';
import 'package:mentenance_app/screens/pages/forget_password/verify_email.dart';
import 'package:mentenance_app/screens/pages/home/home_page.dart';
import 'package:mentenance_app/screens/pages/login/login.dart';
import 'package:mentenance_app/screens/pages/reports/report_sheet.dart';
import 'package:mentenance_app/screens/pages/reports/reportspage.dart';
import 'package:mentenance_app/screens/pages/scan/scan_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Dubai', primarySwatch: Colors.blue),
      home: LoginPage(),
    );
  }
}
