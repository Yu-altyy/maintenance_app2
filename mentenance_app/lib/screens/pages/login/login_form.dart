import 'package:flutter/material.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/data/services/auth.dart';
import 'package:mentenance_app/screens/admin_flow/pages/home/home_page.dart';
import 'package:mentenance_app/screens/pages/home/home_page.dart';
import 'package:mentenance_app/screens/pages/login/login_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isObscure = true;
  bool _loading = false;
  bool _rememberMe = false;

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onLoginPressed() async {
    final user_email = _usernameController.text.trim();
    final user_password = _passwordController.text;

    if (user_email.isEmpty || user_password.isEmpty) {
      _showMessage('من فضلك املأ اسم المستخدم وكلمة المرور');
      return;
    }

    setState(() => _loading = true);

    try {
      // تسجيل الدخول
      await _authService.login(
        user_email: user_email,
        user_password: user_password,
      );

      // جلب بيانات المستخدم بعد تسجيل الدخول
      final storedUser = await AuthService.getUserData();
      final role = storedUser?['role'] ?? '';
      final userId = storedUser?['id'];

      // حفظ الـ ID في SharedPreferences (كـ int)
      if (userId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', userId);
        debugPrint('✅ User ID saved in SharedPreferences: $userId');
      } else {
        debugPrint('⚠️ User ID is null, not saved.');
      }

      _showMessage('تم تسجيل الدخول بنجاح');

      if (!mounted) return;

      // التوجيه حسب الدور
      if (role == 'Maintenance Manager') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else if (role == 'Maintenance Technician') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TasksPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginSplash()),
        );
      }
    } catch (e) {
      final msg =
          e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : 'حدث خطأ غير معروف';
      _showMessage(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: AppColors.white1,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            spreadRadius: 3,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "تسجيل الدخول",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          TextField(
            controller: _usernameController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "اسم المستخدم أو البريد الإلكتروني",
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color.fromARGB(0, 255, 255, 255),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _passwordController,
            obscureText: _isObscure,
            decoration: InputDecoration(
              hintText: "كلمة المرور",
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color.fromARGB(0, 255, 255, 255),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged:
                        (val) => setState(() => _rememberMe = val ?? false),
                  ),
                  const Text("تذكرني"),
                ],
              ),
              TextButton(
                onPressed: () {
                  // TODO: forgot password flow
                },
                child: const Text(
                  "نسيت كلمة المرور؟",
                  style: TextStyle(color: AppColors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.zero,
            ),
            onPressed: _loading ? null : _onLoginPressed,
            child:
                _loading
                    ? const SizedBox(
                      height: 50,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                    : Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        height: 50,
                        child: const Text(
                          "تسجيل الدخول",
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            "تسجيل الدخول السريع",
            style: TextStyle(color: AppColors.grey, fontSize: 14),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.fingerprint,
                  size: 40,
                  color: AppColors.primary,
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 30),
              IconButton(
                icon: const Icon(
                  Icons.face,
                  size: 40,
                  color: AppColors.primary,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
