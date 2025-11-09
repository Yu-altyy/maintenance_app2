import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mentenance_app/core/constant/constant.dart';

class ApiService {
  // 🧑‍🔧 Get active technicians
  static Future<List<Map<String, dynamic>>> getTechnicians() async {
    final response = await http.get(
      Uri.parse("${AppConfig.ip}/maintenance-tasks/technicians"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception('Failed to fetch technicians');
    }
  }

  // 🧰 Get machine list
  static Future<List<Map<String, dynamic>>> getMachines() async {
    final response = await http.get(
      Uri.parse("${AppConfig.ip}/maintenance-tasks/machine"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception('Failed to fetch machines');
    }
  }

  // 🧩 Store Main Task — returns task_id from API
  static Future<int?> storeMainTask(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("${AppConfig.ip}/maintenance-tasks/store"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data["data"]["task_id"];
    } else {
      print("Main task create failed: ${response.body}");
      return null;
    }
  }

  // 🔗 Store Sub Task — uses parentId (task_id)
  static Future<bool> storeSubTask(
    int parentId,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse("${AppConfig.ip}/maintenance-tasks/$parentId/sub-tasks"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      print("✅ Sub-task created successfully for parent $parentId");
      return true;
    } else {
      print("❌ Failed to create sub-task: ${response.body}");
      return false;
    }
  }
}
