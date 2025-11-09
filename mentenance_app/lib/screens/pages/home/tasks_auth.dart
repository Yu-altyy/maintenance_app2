import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskApiService {
  // جلب المهام من الـ API حسب technician_id المخزن
  static Future<List<Map<String, dynamic>>> fetchTasks() async {
    try {
      // 1️⃣ قراءة الـ ID من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getInt('userId');

      if (technicianId == null) {
        throw Exception(
          "لم يتم العثور على معرف الفني (userId) في SharedPreferences",
        );
      }

      // 2️⃣ بناء الرابط الصحيح
      final url = Uri.parse(
        "${AppConfig.ip}/maintenance-tasks/technician/$technicianId",
      );

      // 3️⃣ إرسال الطلب
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true) {
          List<dynamic> data = jsonData['data'];

          // 4️⃣ تنسيق البيانات قبل الإرجاع
          return data.map<Map<String, dynamic>>((task) {
            return {
              'task_id': task['task_id'], // 👈 أضفنا هذا السطر المهم
              'type': task['priority'] ?? 'غير محدد',
              'title': task['problem_type'] ?? 'غير محدد',
              'code': task['machine_serial_number'] ?? 'N/A',
              'branch': task['branch_name'] ?? 'غير محدد',
              'estTime': 45, // وقت تقديري
              'distance': 2.0, // ثابت مؤقتًا
              'startNow': task['status'] == 'In Progress',
            };
          }).toList();
        } else {
          throw Exception("فشل في جلب البيانات من السيرفر");
        }
      } else {
        throw Exception("فشل الاتصال بالخادم: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("حدث خطأ أثناء جلب المهام: $e");
    }
  }
}
