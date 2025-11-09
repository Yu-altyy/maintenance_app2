import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mentenance_app/core/constant/constant.dart';

class TasksAuthAdminservice {
  // جلب المهام من الـ API
  static Future<List<Map<String, dynamic>>> fetchTasks() async {
    final url = Uri.parse(
      "${AppConfig.ip}/maintenance-tasks",
    ); // Endpoint المهام

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] == true) {
        List<dynamic> data = jsonData['data'];
        return data.map<Map<String, dynamic>>((task) {
          return {
            'id': task['task_id'], // ✅ استخدم task_id بدل id
            'type': task['priority'],
            'title': task['problem_type'] ?? 'غير محدد',
            'code': task['machine_serial_number'] ?? 'N/A',
            'branch': task['branch_name'] ?? 'غير محدد',
            'estTime': 45,
            'distance': 2.0,
            'startNow': task['status'] == 'In Progress',
          };
        }).toList();
      } else {
        throw Exception("فشل في جلب البيانات من السيرفر");
      }
    } else {
      throw Exception("فشل الاتصال بالخادم: ${response.statusCode}");
    }
  }
}

class TechniciansApiService {
  static Future<List<Map<String, dynamic>>> fetchTechnicians() async {
    const String url =
        '${AppConfig.ip}/maintenance-tasks/technicians'; // غيّر حسب مسار API عندك

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('البيانات غير متوفرة');
      }
    } else {
      throw Exception('فشل الاتصال بالسيرفر');
    }
  }
}
