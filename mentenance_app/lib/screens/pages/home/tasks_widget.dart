import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/screens/pages/scan/scan_page.dart';

class TaskCard extends StatelessWidget {
  final int id; // 👈 معرف المهمة
  final String type;
  final String title;
  final String code;
  final String branch;
  final int estTime;
  final double distance;
  final bool startNow;

  const TaskCard({
    super.key,
    required this.id,
    required this.type,
    required this.title,
    required this.code,
    required this.branch,
    required this.estTime,
    required this.distance,
    this.startNow = false,
  });

  // اللون حسب نوع المهمة
  Color get color {
    switch (type) {
      case "Urgent":
        return const Color.fromARGB(206, 244, 67, 54);
      case "Maintenance":
        return const Color.fromARGB(202, 255, 153, 0);
      case "Update":
        return const Color.fromARGB(202, 76, 175, 79);
      default:
        return Colors.grey;
    }
  }

  // تعريب نوع المهمة
  String get typeLabel {
    switch (type) {
      case "Urgent":
        return "عاجلة";
      case "Maintenance":
        return "صيانة";
      case "Update":
        return "تحديث";
      default:
        return type;
    }
  }

  // 👇 تخزين الـ ID في SharedPreferences مع طباعته
  Future<void> _storeTaskId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('startTask', id);

    // 👇 طباعة القيمة بعد التخزين
    final storedId = prefs.getInt('startTask');
    debugPrint('✅ تم تخزين معرف المهمة في SharedPreferences: $storedId');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
        border: Border(right: BorderSide(color: color, width: 6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // نوع المهمة + الوقت
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  startNow ? "بدأت قبل 30 دقيقة" : "موعد البدء: 10:00 ص",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(code, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(branch, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  "المدة: $estTime دقيقة",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "${distance.toStringAsFixed(1)} كم",
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await _storeTaskId(); // 👈 تخزين وطباعة الـ ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeviceScannerScreen(),
                      ),
                    );
                  },
                  child: Text(
                    startNow ? "ابدأ الآن" : "ابدأ",
                    style: TextStyle(color: AppColors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
