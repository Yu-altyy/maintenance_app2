import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:local_auth/local_auth.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// التحقق من توفر البصمة أو الوجه
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// جلب أنواع المصادقة المتاحة (بصمة / وجه)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// مصادقة بصمة الإصبع
  Future<bool> authenticateFingerprint() async {
    try {
      final available = await getAvailableBiometrics();
      // بدل ما نفحص fingerprint بس، نفحص strong أو weak كمان
      if (available.contains(BiometricType.fingerprint) ||
          available.contains(BiometricType.strong) ||
          available.contains(BiometricType.weak)) {
        return await _auth.authenticate(
          localizedReason: 'استخدم بصمة الإصبع لتسجيل الدخول',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
      }
      return false;
    } catch (e) {
      print("Biometric error: $e");
      return false;
    }
  }

  /// مصادقة وجه
  Future<bool> authenticateFace() async {
    try {
      final available = await getAvailableBiometrics();
      if (available.contains(BiometricType.face)) {
        return await _auth.authenticate(
          localizedReason: 'استخدم بصمة الوجه لتسجيل الدخول',
          options: const AuthenticationOptions(biometricOnly: true),
        );
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

class AuthService {
  static const String _loginPath = '/login';

  AuthService();

  /// تسجيل الدخول وتخزين التوكن في SharedPreferences
  Future<void> login({
    required String user_email,
    required String user_password,
  }) async {
    final uri = Uri.parse('${AppConfig.ip}$_loginPath');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'user_email': user_email,
        'user_password': user_password,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['token'] as String?;
      final user = body['user'] as Map<String, dynamic>?;

      if (token == null || user == null) {
        throw Exception('استجابة الخادم غير مكتملة.');
      }

      // تخزين التوكن وبيانات المستخدم في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user_data', jsonEncode(user));
    } else if (response.statusCode == 401) {
      final body = (response.body.isEmpty) ? {} : jsonDecode(response.body);
      final message =
          (body is Map && body['message'] != null)
              ? body['message'].toString()
              : 'بيانات الدخول غير صحيحة';
      throw Exception(message);
    } else {
      String message = 'حدث خطأ؛ رمز الحالة: ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null)
          message = body['message'].toString();
      } catch (_) {}
      throw Exception(message);
    }
  }

  /// دالة لقراءة التوكن المخزن
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// دالة لقراءة بيانات المستخدم المخزنة
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user_data');
    if (userString != null) {
      return jsonDecode(userString) as Map<String, dynamic>;
    }
    return null;
  }
}

//send email for verification
class EmailAuthService {
  static const String _forgotPasswordPath = '/api/forgot-password';
  static const String _verifyCodePath = '/api/verify-reset-code';

  /// طلب رمز التحقق (يرجع reset_token)
  static Future<String> requestResetCode({required String user_email}) async {
    final uri = Uri.parse('${AppConfig.ip}$_forgotPasswordPath');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_email': user_email}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final resetToken = body['reset_token'] as String?;
      if (resetToken == null) throw Exception('لم يتم استلام reset_token');
      return resetToken;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'حدث خطأ أثناء إرسال الرمز');
    }
  }

  /// تحقق من الرمز باستخدام reset_token
  static Future<void> verifyCode({
    required String resetToken,
    required String code,
  }) async {
    final uri = Uri.parse('${AppConfig.ip}$_verifyCodePath');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reset_token': resetToken, 'code': code}),
    );

    if (response.statusCode == 200) {
      // نجاح التحقق
      return;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'الكود غير صالح أو انتهت صلاحيته');
    }
  }
}

//verfy code
class VerificationService {
  static const String _verifyPath = '/api/verify-reset-code';

  /// يتحقق من الكود ويرجع رسالة النجاح أو يرمي استثناء عند الفشل
  Future<String> verifyCode({
    required String resetToken,
    required String code,
  }) async {
    final uri = Uri.parse('${AppConfig.ip}$_verifyPath');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'reset_token': resetToken, 'code': code}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return body['message'] ?? 'تم التحقق بنجاح';
    } else {
      throw Exception(body['message'] ?? 'الكود غير صالح');
    }
  }
}

//reset password
class ResetAuthService {
  static const String _verifyCodePath = '/verify-reset-code';
  static const String _resetPasswordPath = '/reset-password';

  static Future<void> verifyCode({
    required String resetToken,
    required String code,
  }) async {
    final uri = Uri.parse('${AppConfig.ip}$_verifyCodePath');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reset_token': resetToken, 'code': code}),
    );

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'فشل التحقق من الكود');
    }
  }

  static Future<void> resetPassword({
    required String resetToken,
    required String user_password,
    required String user_password_confirmation,
  }) async {
    final uri = Uri.parse('${AppConfig.ip}$_resetPasswordPath');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reset_token': resetToken,
        'user_password': user_password,
        'user_password_confirmation': user_password_confirmation,
      }),
    );

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'فشل إعادة تعيين كلمة المرور');
    }
  }
}
