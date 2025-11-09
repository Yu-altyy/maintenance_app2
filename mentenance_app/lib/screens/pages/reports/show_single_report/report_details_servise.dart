import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mentenance_app/core/constant/constant.dart';

class MachineService {
  /// 🟢 جلب تفاصيل تقرير معين حسب ID
  static Future<Map<String, dynamic>> fetchReportDetails(int reportId) async {
    final url = Uri.parse('${AppConfig.ip}/maintenance-reports/$reportId/show');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('فشل في جلب بيانات التقرير (${response.statusCode})');
    }
  }
}
