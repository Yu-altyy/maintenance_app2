import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpensesService {
  /// جلب كل المصاريف حسب ID الفني المخزن في الشيرد
  static Future<List<Map<String, dynamic>>> fetchExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final technicianId = prefs.getInt('userId'); // 👈 نقرأ ID الفني
    if (token == null || technicianId == null) return [];

    final url = Uri.parse(
      '${AppConfig.ip}/technician-expenses/technician/$technicianId',
    );
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List data = body['data'] ?? [];

      return data.map<Map<String, dynamic>>((e) {
        return {
          'id': e['id'],
          'task': '${e['machine_name']} - ${e['serial_number']}',
          'type': e['expense_type'] ?? 'غير محدد',
          'amount': e['amount'] ?? 0,
          'currency': e['symbol'] ?? '',
          'date': e['date']?.toString().split('T').first ?? '',
          'status': e['status'] ?? '',
          'description': e['description'] ?? '',
          'image': e['receipt_image_url'],
          'color':
              e['status'] == 'Approved'
                  ? Colors.green[700]
                  : e['status'] == 'Pending'
                  ? Colors.orange[700]
                  : Colors.red[700],
        };
      }).toList();
    } else {
      throw Exception('فشل في جلب المصاريف: ${response.statusCode}');
    }
  }

  //delete expense
  static Future<void> deleteExpense(int expenseId) async {
    final url = Uri.parse('${AppConfig.ip}/technician-expenses/$expenseId');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        debugPrint('✅ تم حذف المصروف بنجاح');
      } else {
        throw Exception(data['message'] ?? 'فشل في حذف المصروف');
      }
    } else {
      throw Exception('فشل في الاتصال بالسيرفر عند الحذف');
    }
  }
}

//add expencis
class ApiService {
  // جلب المهام
  static Future<List<Map<String, dynamic>>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final technicianId = prefs.getInt('userId');

    if (technicianId == null) {
      throw Exception('لم يتم العثور على معرف الفني في البيانات المخزنة');
    }

    final url = Uri.parse(
      '${AppConfig.ip}/maintenance-tasks/technician/$technicianId',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['success']) {
      final List tasks = data['data'];

      return tasks.map<Map<String, dynamic>>((task) {
        final problemType = task['problem_type'] ?? 'غير محدد';
        final clientName = task['client_name'] ?? 'غير معروف';
        final taskDate =
            task['created_at'] != null
                ? task['created_at'].toString().substring(0, 10)
                : '';

        // ✅ تحويل آمن للـ ID إلى int حتى لو كان String أو null
        final taskId =
            int.tryParse(
              task['task_id']?.toString() ?? task['id']?.toString() ?? '0',
            ) ??
            0;

        return {
          'task_id': taskId,
          'display_text': '$problemType - $clientName - $taskDate',
        };
      }).toList();
    } else {
      throw Exception(data['message'] ?? 'فشل في جلب المهام');
    }
  }

  // جلب أنواع المصاريف
  static Future<List<Map<String, dynamic>>> getExpenseTypes() async {
    final url = Uri.parse(
      '${AppConfig.ip}/technician-expenses/expense-types/list',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['success']) {
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception(data['message'] ?? 'فشل في جلب أنواع المصاريف');
    }
  }

  // جلب العملات
  static Future<List<Map<String, dynamic>>> getCurrencies() async {
    final url = Uri.parse(
      '${AppConfig.ip}/technician-expenses/currencies/list',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['success']) {
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception(data['message'] ?? 'فشل في جلب العملات');
    }
  }

  // إضافة مصروف جديد مع رفع الصورة
  static Future<void> addExpense({
    required int taskId,
    required int expenseTypeId,
    required int currencyId,
    required double amount,
    required String expenseDate,
    String? description,
    File? receiptImage,
  }) async {
    final url = Uri.parse('${AppConfig.ip}/technician-expenses');
    final request = http.MultipartRequest('POST', url);

    // الحقول العادية
    request.fields.addAll({
      'task_id': taskId.toString(),
      'expense_type_id': expenseTypeId.toString(),
      'currency_id': currencyId.toString(),
      'amount': amount.toString(),
      'expense_date': expenseDate,
      'description': description ?? '',
    });

    // رفع الصورة (اختياري)
    if (receiptImage != null) {
      final file = await http.MultipartFile.fromPath(
        'receipt_image_url',
        receiptImage.path,
      );
      request.files.add(file);
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = json.decode(responseBody);

    if (response.statusCode != 201 || data['success'] == false) {
      throw Exception(data['message'] ?? 'فشل في إضافة المصروف');
    }
  }
}
