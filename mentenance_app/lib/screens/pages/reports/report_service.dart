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

  /// 🟢 إرسال تقرير الصيانة إلى السيرفر
  static Future<Map<String, dynamic>> submitReport({
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
    final taskId = prefs.getInt('startTask');
    final machineId = prefs.getString('selectedMachineId');

    if (taskId == null || machineId == null) {
      throw Exception('❌ لا يوجد Task ID أو Machine ID محفوظ.');
    }

    final url = Uri.parse('${AppConfig.ip}/maintenance-reports/store');
    var request = http.MultipartRequest('POST', url);

    // ✅ السيرفر يتوقع القيم بالعربية بالضبط
    final maintenanceTypeMap = {
      'Operational': 'تشغيلية',
      'Preventive': 'وقائية',
      'Urgent': 'عاجلة',
      'Corrective': 'تصحيحية',
      'Developmental': 'تطويرية',
      // النسخ العربية
      'تشغيلية': 'تشغيلية',
      'وقائية': 'وقائية',
      'عاجلة': 'عاجلة',
      'تصحيحية': 'تصحيحية',
      'تطويرية': 'تطويرية',
    };

    final countingAccuracyMap = {
      'Excellent': 'ممتازة 100%',
      'Good': 'جيدة 95-99 %',
      'Acceptable': 'مقبولة 90-94%',
      'Weak': 'ضعيفة اقل من 90%',
      'ممتازة (100%)': 'ممتازة 100%',
      'جيدة (95-99%)': 'جيدة 95-99 %',
      'مقبولة (90-94%)': 'مقبولة 90-94%',
      'ضعيفة (أقل من 90%)': 'ضعيفة اقل من 90%',
    };

    final operationalStatusMap = {
      'يعمل بشكل طبيعي': 'يعمل بشكل طبيعي',
      'يعمل مع مشاكل': 'يعمل مع مشاكل',
      'لا يعمل': 'لا يعمل',
      'تحت الصيانة': 'تحت الصيانة',
    };

    // 🔹 تعبئة الحقول الأساسية
    request.fields['task_id'] = taskId.toString();
    request.fields['machine_id'] = machineId.toString();
    request.fields['maintenance_type'] =
        maintenanceTypeMap[maintenanceType] ?? maintenanceType;
    request.fields['operational_status'] =
        operationalStatusMap[operationalStatus] ?? operationalStatus;
    request.fields['counting_accuracy'] =
        countingAccuracyMap[countingAccuracy] ?? countingAccuracy;
    request.fields['technician_notes'] = technicianNotes;
    request.fields['client_name'] = clientName;
    request.fields['client_phone'] = clientPhone;

    // ✅ إرسال الحساسات كـ JSON (Laravel يقبلها)
    if (selectedSensors != null && selectedSensors.isNotEmpty) {
      request.fields['checked_sensors'] = jsonEncode(selectedSensors);
    }

    // ✅ الأعمال المنجزة كمصفوفة مفهرسة (Laravel-style)
    if (completedWorks != null && completedWorks.isNotEmpty) {
      for (int i = 0; i < completedWorks.length; i++) {
        var work = completedWorks[i];
        work.forEach((key, value) {
          request.fields['completed_works[$i][$key]'] = value.toString();
        });
      }
    }

    // ✅ فحوص السلامة كمصفوفة مفهرسة
    if (safetyChecks != null && safetyChecks.isNotEmpty) {
      for (int i = 0; i < safetyChecks.length; i++) {
        var check = safetyChecks[i];
        check.forEach((key, value) {
          request.fields['safety_checks[$i][$key]'] = value.toString();
        });
      }
    }

    // ✅ قطع الغيار (Laravel يقبل JSON)
    if (selectedSpareParts != null && selectedSpareParts.isNotEmpty) {
      request.fields['used_parts'] = jsonEncode(selectedSpareParts);
    }

    // 🖋️ التوقيع (اختياري)
    if (clientSignature != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'client_signature',
          clientSignature,
          filename: 'signature.png',
        ),
      );
    }

    // 🧩 Debug block
    print('==============================');
    print('📤 بيانات التقرير المرسلة للسيرفر:');
    request.fields.forEach((key, value) {
      print('➡️ $key: $value');
    });
    print('📎 يحتوي على توقيع؟ ${clientSignature != null}');
    print('==============================');

    // 🔹 إرسال الطلب
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      final data = jsonDecode(responseBody);
      print('✅ التقرير تم إنشاؤه بنجاح!');
      print(jsonEncode(data));
      return data;
    } else {
      print('❌ فشل في إنشاء التقرير (${response.statusCode}): $responseBody');
      throw Exception('فشل في إنشاء التقرير: $responseBody');
    }
  }
}
