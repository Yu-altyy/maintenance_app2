import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentenance_app/core/constant/constant.dart';

class UpdateExpenseService {
  /// جلب تفاصيل مصروف حسب ID المخزن في SharedPreferences
  static Future<Map<String, dynamic>> getExpenseDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final expenseId = prefs.getInt('selectedExpenseId');
    if (expenseId == null) throw Exception('لم يتم العثور على رقم المصروف');

    final url = Uri.parse('${AppConfig.ip}/technician-expenses/$expenseId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['data'];
      throw Exception(data['message'] ?? 'فشل في جلب تفاصيل المصروف');
    } else {
      throw Exception('فشل في الاتصال بالسيرفر');
    }
  }

  /// تحديث بيانات مصروف (مع رفع الصورة)
  static Future<void> updateExpense({
    required int expenseId,
    int? taskId,
    int? expenseTypeId,
    int? currencyId,
    double? amount,
    String? expenseDate,
    String? description,
    File? receiptImage,
  }) async {
    final url = Uri.parse('${AppConfig.ip}/technician-expenses/$expenseId');
    final request = http.MultipartRequest('POST', url)
      ..fields['_method'] = 'POST'; // 👈 لأن Laravel يحتاج PUT

    if (taskId != null) request.fields['task_id'] = taskId.toString();
    if (expenseTypeId != null)
      request.fields['expense_type_id'] = expenseTypeId.toString();
    if (currencyId != null)
      request.fields['currency_id'] = currencyId.toString();
    if (amount != null) request.fields['amount'] = amount.toString();
    if (expenseDate != null) request.fields['expense_date'] = expenseDate;
    if (description != null) request.fields['description'] = description;

    if (receiptImage != null) {
      final file = await http.MultipartFile.fromPath(
        'receipt_image_url',
        receiptImage.path,
      );
      request.files.add(file);
    }

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    final data = jsonDecode(resBody);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'فشل في تحديث المصروف');
    }
  }

  /// جلب القوائم المساعدة (مهام / أنواع مصروف / عملات)
  static Future<List<Map<String, dynamic>>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final technicianId = prefs.getInt('userId');
    if (technicianId == null) throw Exception('لا يوجد معرف فني');

    final url = Uri.parse(
      '${AppConfig.ip}/maintenance-tasks/technician/$technicianId',
    );
    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success']) {
      final List tasks = data['data'];
      return tasks.map<Map<String, dynamic>>((task) {
        final taskId = int.tryParse(task['task_id'].toString()) ?? 0;
        final text = '${task['problem_type']} - ${task['client_name']}';
        return {'task_id': taskId, 'display_text': text};
      }).toList();
    } else {
      throw Exception('فشل في جلب المهام');
    }
  }

  static Future<List<Map<String, dynamic>>> getExpenseTypes() async {
    final url = Uri.parse(
      '${AppConfig.ip}/technician-expenses/expense-types/list',
    );
    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success']) {
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception('فشل في جلب أنواع المصاريف');
    }
  }

  static Future<List<Map<String, dynamic>>> getCurrencies() async {
    final url = Uri.parse(
      '${AppConfig.ip}/technician-expenses/currencies/list',
    );
    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success']) {
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception('فشل في جلب العملات');
    }
  }
}
