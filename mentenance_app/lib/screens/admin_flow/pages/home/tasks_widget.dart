import 'package:flutter/material.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/screens/admin_flow/pages/edit_task/edit_task.dart';
import 'package:mentenance_app/screens/admin_flow/pages/edit_task/edit_task_service.dart';
import 'package:mentenance_app/screens/pages/scan/scan_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskCard extends StatelessWidget {
  final int id;
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
            // الشريط العلوي
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

            // المعلومات
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(code, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(branch, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),

            // الوقت والمسافة
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
              ],
            ),

            const SizedBox(height: 20),

            // الأزرار في الأسفل (تعديل + حذف)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditTask()),
                    );
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('selectedTaskId', id);
                    print("تم حفظ ID المهمة في SharedPreferences: $id");
                  },
                  child: Text(
                    'تعديل',
                    style: TextStyle(color: AppColors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    // تأكيد قبل الحذف
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text("تأكيد الحذف"),
                            content: const Text(
                              "هل أنت متأكد أنك تريد حذف هذه المهمة؟",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text("إلغاء"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text("حذف"),
                              ),
                            ],
                          ),
                    );

                    if (confirm != true) return;

                    // تنفيذ الحذف
                    final success = await EditTaskService.deleteTask(id);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ تم حذف المهمة بنجاح')),
                      );
                      // يمكنك هنا مثلاً إعادة تحميل القائمة أو إزالة البطاقة من الواجهة
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('❌ فشل حذف المهمة')),
                      );
                    }
                  },
                  child: const Text(
                    'حذف',
                    style: TextStyle(color: Colors.white, fontSize: 16),
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
