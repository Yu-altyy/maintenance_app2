// lib/screens/pages/expenses/expenses_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentenance_app/core/constant/constant.dart';

class ExpensesService {
  // 🔹 جلب كل المصاريف من السيرفر
  static Future<List<Map<String, dynamic>>> fetchAllExpenses() async {
    final url = Uri.parse('${AppConfig.ip}/technician-expenses');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded['success'] == true) {
        return (decoded['data'] as List).map((expense) {
          final status = expense['status'] ?? 'Unknown';
          Color color;

          switch (status) {
            case 'Approved':
              color = Colors.green[700]!;
              break;
            case 'Pending':
              color = Colors.orange[700]!;
              break;
            case 'Rejected':
              color = Colors.red[700]!;
              break;
            default:
              color = Colors.grey;
          }

          return {
            'id': expense['id'],
            'task': expense['machine_name'] ?? 'غير محدد',
            'type': expense['expense_type'] ?? 'غير محدد',
            'amount': expense['amount'] ?? 0,
            'currency': expense['symbol'] ?? '',
            'date': expense['date'] ?? '',
            'status': status,
            'color': color,
            'description': expense['description'] ?? '',
            'image': expense['receipt_image_url'] ?? '',
          };
        }).toList();
      } else {
        throw Exception(decoded['message']);
      }
    } else {
      throw Exception('فشل الاتصال بالسيرفر: ${response.statusCode}');
    }
  }

  // 🔹 قبول مصروف
  static Future<bool> approveExpense(int expenseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null)
        throw Exception('User ID not found in SharedPreferences');

      final url = Uri.parse(
        '${AppConfig.ip}/technician-expenses/$expenseId/approve',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'approved_by_user_id': userId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      } else {
        debugPrint('❌ فشل في قبول المصروف: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception عند قبول المصروف: $e');
      return false;
    }
  }

  // 🔹 رفض مصروف
  static Future<bool> rejectExpense(int expenseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null)
        throw Exception('User ID not found in SharedPreferences');

      final url = Uri.parse(
        '${AppConfig.ip}/technician-expenses/$expenseId/reject',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'approved_by_user_id': userId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      } else {
        debugPrint('❌ فشل في رفض المصروف: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception عند رفض المصروف: $e');
      return false;
    }
  }
}
