import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MachineService {
  /// 🟢 جلب قائمة الماكينات
  static Future<List<Map<String, dynamic>>> fetchMachines() async {
    final url = Uri.parse('${AppConfig.ip}/maintenance-reports/machines');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('فشل في جلب بيانات الماكينات');
    }
  }

  /// 🟢 جلب تفاصيل آلة حسب ID
  static Future<Map<String, dynamic>> fetchMachineDetails(int machineId) async {
    final url = Uri.parse(
      '${AppConfig.ip}/maintenance-reports/machines/$machineId/getMachineDetails',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('فشل في جلب تفاصيل الماكينة');
    }
  }

  /// 🟢 جلب تفاصيل تقرير معين حسب ID
  static Future<Map<String, dynamic>> fetchReportDetails(int reportId) async {
    final url = Uri.parse('${AppConfig.ip}/maintenance-reports/$reportId/show');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('فشل في جلب بيانات التقرير');
    }
  }

  /// 🟡 تحديث تقرير صيانة موجود (PUT + Multipart)
  /// 🟡 تحديث تقرير صيانة موجود (PUT + Multipart)
  static Future<Map<String, dynamic>> updateReport({
    required int reportId,
    required String maintenanceType,
    required String operationalStatus,
    required String countingAccuracy,
    required String technicianNotes,
    required String clientName,
    required String clientPhone,
    Uint8List? clientSignature,
    List<Map<String, dynamic>>? completedWorks,
    List<Map<String, dynamic>>? safetyChecks,
    List<Map<String, dynamic>>? selectedSensors,
    List<Map<String, dynamic>>? selectedSpareParts,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final machineId = prefs.getString('selectedMachineId');

    if (machineId == null) {
      throw Exception('❌ لا يوجد Machine ID محفوظ.');
    }

    final url = Uri.parse(
      '${AppConfig.ip}/maintenance-reports/$reportId/update',
    );
    var request = http.MultipartRequest('POST', url);
    request.fields['_method'] = 'PUT'; // مهم للـ Laravel

    // ✅ ترجمة القيم
    final countingAccuracyMap = {
      'ممتازة (100%)': 'ممتازة 100%',
      'جيدة (95-99%)': 'جيدة 95-99 %',
      'مقبولة (90-94%)': 'مقبولة 90-94%',
      'ضعيفة (أقل من 90%)': 'ضعيفة اقل من 90%',
    };

    // 🔹 الحقول الأساسية
    request.fields['machine_id'] = machineId;
    request.fields['maintenance_type'] = maintenanceType;
    request.fields['operational_status'] = operationalStatus;
    request.fields['counting_accuracy'] =
        countingAccuracyMap[countingAccuracy] ?? countingAccuracy;
    request.fields['technician_notes'] = technicianNotes;
    request.fields['client_name'] = clientName;
    request.fields['client_phone'] = clientPhone;

    // ✅ تحويل الحساسات إلى الصيغة الصحيحة
    if (selectedSensors != null && selectedSensors.isNotEmpty) {
      for (int i = 0; i < selectedSensors.length; i++) {
        var sensor = selectedSensors[i];
        // لو المفتاح sensor_id مش موجود، نستخدم part_id أو رقم افتراضي
        request.fields['sensors_status[$i][sensor_id]'] =
            sensor['sensor_id']?.toString() ??
            sensor['id']?.toString() ??
            '1'; // رقم افتراضي مؤقت
        request.fields['sensors_status[$i][status]'] =
            sensor['status']?.toString() ?? '';
      }
    }

    // ✅ الأعمال المنجزة
    if (completedWorks != null && completedWorks.isNotEmpty) {
      for (int i = 0; i < completedWorks.length; i++) {
        var work = completedWorks[i];
        work.forEach((key, value) {
          request.fields['completed_works[$i][$key]'] = value.toString();
        });
      }
    }

    // ✅ فحوص السلامة
    if (safetyChecks != null && safetyChecks.isNotEmpty) {
      for (int i = 0; i < safetyChecks.length; i++) {
        var check = safetyChecks[i];
        check.forEach((key, value) {
          request.fields['safety_checks[$i][$key]'] = value.toString();
        });
      }
    }

    // ✅ تحويل قطع الغيار إلى الصيغة الصحيحة
    if (selectedSpareParts != null && selectedSpareParts.isNotEmpty) {
      for (int i = 0; i < selectedSpareParts.length; i++) {
        var part = selectedSpareParts[i];
        request.fields['parts_used[$i][spare_part_id]'] =
            part['spare_part_id']?.toString() ??
            part['part_id']?.toString() ??
            '1'; // رقم افتراضي مؤقت
        request.fields['parts_used[$i][machine_id]'] =
            part['machine_id']?.toString() ?? '';
        request.fields['parts_used[$i][quantity]'] =
            part['quantity']?.toString() ?? '';
      }
    }

    // ✅ التوقيع كصورة فعلية
    if (clientSignature != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'client_signature',
          clientSignature,
          filename: 'signature.png',
        ),
      );
    }

    // 🧩 Debug log
    print('==============================');
    print('📤 بيانات التحديث المرسلة للسيرفر:');
    request.fields.forEach((key, value) {
      print('➡️ $key: $value');
    });
    print('📎 يحتوي على توقيع؟ ${clientSignature != null}');
    print('==============================');

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      print('✅ تم تحديث التقرير بنجاح!');
      return data;
    } else {
      print('❌ فشل في تحديث التقرير (${response.statusCode}): $responseBody');
      throw Exception('فشل في تحديث التقرير: $responseBody');
    }
  }
}
