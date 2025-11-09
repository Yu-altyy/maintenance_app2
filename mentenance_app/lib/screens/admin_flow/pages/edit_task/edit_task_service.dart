import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentenance_app/core/constant/constant.dart';

class EditTaskService {
  /// 🔹 جلب بيانات مهمة واحدة حسب الـ ID المخزّن في SharedPreferences
  static Future<Map<String, dynamic>?> fetchTaskData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('selectedTaskId');

      if (id == null) {
        print("⚠️ لم يتم العثور على ID في SharedPreferences");
        return null;
      }

      final url = Uri.parse("${AppConfig.ip}/maintenance-tasks/$id/show");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          print("✅ تم جلب بيانات المهمة بنجاح للـ ID: $id");
          return jsonData['data'];
        } else {
          print("⚠️ لا توجد بيانات لهذه المهمة.");
        }
      } else {
        print("❌ فشل في الاتصال بالسيرفر: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ خطأ أثناء جلب بيانات المهمة: $e");
    }

    return null;
  }

  //update task function
  static Future<bool> updateTask({
    required int id,
    String? machineId,
    String? problemType,
    String? reportedProblem,
    String? priority,
    String? scheduledDate,
    String? technicianId,
  }) async {
    try {
      final url = Uri.parse("${AppConfig.ip}/maintenance-tasks/$id/update");

      final body = {
        if (machineId != null) 'machine_id': machineId,
        if (problemType != null) 'problem_type': problemType,
        if (reportedProblem != null) 'reported_problem': reportedProblem,
        if (priority != null) 'priority': priority,
        if (scheduledDate != null) 'scheduled_date': scheduledDate,
        if (technicianId != null) 'technician_id': technicianId,
      };

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true) {
          print("✅ Task updated successfully");
          return true;
        } else {
          print("⚠️ Update failed: ${jsonData['message']}");
        }
      } else {
        print("❌ HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception during update: $e");
    }
    return false;
  }

  //delete task function
  // 🟥 دالة حذف المهمة
  static Future<bool> deleteTask(int id) async {
    try {
      final url = Uri.parse("${AppConfig.ip}/maintenance-tasks/$id/destroy");
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true) {
          print("✅ تم حذف المهمة بنجاح (ID: $id)");
          return true;
        } else {
          print("⚠️ فشل الحذف: ${jsonData['message']}");
        }
      } else {
        print("❌ خطأ في الاتصال (${response.statusCode})");
      }
    } catch (e) {
      print("❌ استثناء أثناء الحذف: $e");
    }
    return false;
  }
}
