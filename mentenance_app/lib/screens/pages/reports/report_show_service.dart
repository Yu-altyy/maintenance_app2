import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mentenance_app/core/constant/constant.dart';

class Report {
  final int taskReportId;
  final int taskId;
  final String maintenanceType;
  final String operationalStatus;
  final String? countingAccuracy;
  final String? clientName;
  final String? clientPhone;
  final String createdAt;
  final Map<String, dynamic> taskDetails;

  Report({
    required this.taskReportId,
    required this.taskId,
    required this.maintenanceType,
    required this.operationalStatus,
    this.countingAccuracy,
    this.clientName,
    this.clientPhone,
    required this.createdAt,
    required this.taskDetails,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      taskReportId: json['task_report_id'],
      taskId: json['task_id'],
      maintenanceType: json['maintenance_type'] ?? 'N/A',
      operationalStatus: json['operational_status'] ?? 'غير محدد',
      countingAccuracy: json['counting_accuracy'],
      clientName: json['client_name'],
      clientPhone: json['client_phone'],
      createdAt: json['created_at'],
      taskDetails: json['task_details'] ?? {},
    );
  }
}

class ReportService {
  static Future<List<Report>> fetchReports() async {
    final url = Uri.parse('${AppConfig.ip}/maintenance-reports');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Report.fromJson(json)).toList();
    } else {
      throw Exception('فشل في تحميل التقارير');
    }
  }
}
