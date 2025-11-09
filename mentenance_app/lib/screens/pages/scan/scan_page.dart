import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mentenance_app/screens/pages/home/bottem_bar.dart';
import 'package:mentenance_app/screens/pages/public_appbar.dart';
import 'package:mentenance_app/screens/pages/scan/widget.dart';

class DeviceScannerScreen extends StatefulWidget {
  const DeviceScannerScreen({super.key});

  @override
  State<DeviceScannerScreen> createState() => _DeviceScannerScreenState();
}

class _DeviceScannerScreenState extends State<DeviceScannerScreen> {
  int _currentIndex = 1;
  String? scannedCode;

  /// دالة طلب صلاحية الكاميرا
  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(title: 'مسح الجهاز'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// FutureBuilder لتأكيد صلاحية الكاميرا قبل عرض CameraBox
              FutureBuilder<bool>(
                future: requestCameraPermission(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData && snapshot.data == true) {
                    return CameraBox(
                      onDetect: (code) {
                        setState(() {
                          scannedCode = code;
                        });
                      },
                    );
                  }
                  return const Center(
                    child: Text(
                      'Camera permission required',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
              const ScanInstructions(),
              const SizedBox(height: 20),
              const ActionButtons(),
              const SizedBox(height: 24),
              const Text(
                'الأجهزة الممسوحة مؤخرًا',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const RecentDeviceCard(),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}
