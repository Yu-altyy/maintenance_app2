import 'package:flutter/material.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/screens/pages/home/home_page.dart';
import 'package:mentenance_app/screens/pages/reports/reportspage.dart';
import 'package:mentenance_app/screens/pages/scan/scan_page.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: currentIndex.clamp(0, 3), // لضمان عدم حدوث خطأ
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: Colors.black87,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          onTap(index); // لتحديث الـ index في الشاشة الرئيسية

          // فتح الشاشة المناسبة
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TasksPage()),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DeviceScannerScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReportsScreen()),
              );
              break;
            case 3:
              // الزكي أو أي صفحة إضافية يمكن إضافتها هنا لاحقًا
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "المهام"),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: "مسح",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "التقارير",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: "ذكي"),
        ],
      ),
    );
  }
}
