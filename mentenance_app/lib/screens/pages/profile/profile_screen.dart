import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/data/services/auth.dart';
import 'package:mentenance_app/screens/pages/login/login.dart';
import 'package:mentenance_app/screens/pages/login/login_form.dart';
import 'package:mentenance_app/screens/pages/public_appbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TechnicianProfileScreen extends StatefulWidget {
  const TechnicianProfileScreen({super.key});

  @override
  State<TechnicianProfileScreen> createState() =>
      _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool autoSyncEnabled = true;

  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final token = await AuthService.getToken();
      final storedUser = await AuthService.getUserData();

      if (token != null && storedUser != null) {
        setState(() {
          userData = storedUser;
          isLoading = false;
        });
        return;
      }

      // في حال عدم وجود البيانات المخزنة، نعيد جلبها من السيرفر
      if (token != null) {
        final response = await http.get(
          Uri.parse("${AppConfig.ip}/api/me"),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            userData = data;
            isLoading = false;
          });

          // نخزنها للشغل القادم
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(data));
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const CustomAppBar(title: 'الملف الشخصي'),
        backgroundColor: AppColors.white,
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : userData == null
                ? const Center(child: Text('فشل في تحميل البيانات'))
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildCard(_buildProfileCard()),
                      _buildCard(_buildSettingsCard()),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(18.0), child: child),
    );
  }

  Widget _buildProfileCard() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 35,
          backgroundColor: AppColors.secondary,
          child: Icon(Icons.person, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 10),
        Text(
          userData?['user_name'] ?? 'غير معروف',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          userData?['user_email'] ?? '',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            userData?['role'] ?? 'غير محدد',
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإعدادات',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _toggleItem('الإشعارات', notificationsEnabled, (val) {
          setState(() => notificationsEnabled = val);
        }),
        _toggleItem('الوضع الداكن', darkModeEnabled, (val) {
          setState(() => darkModeEnabled = val);
        }),
        _toggleItem('المزامنة التلقائية', autoSyncEnabled, (val) {
          setState(() => autoSyncEnabled = val);
        }),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(192, 244, 67, 54),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('تسجيل الخروج'),
          onPressed: () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token');

              if (token != null) {
                try {
                  final response = await http.post(
                    Uri.parse('${AppConfig.ip}/api/logout'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Accept': 'application/json',
                    },
                  );
                  if (response.statusCode != 200) {
                    debugPrint('Logout failed on server: ${response.body}');
                  }
                } catch (e) {
                  debugPrint('Error during logout request: $e');
                }
              }

              // حذف التوكن والبيانات محلياً
              await prefs.remove('token');
              await prefs.remove('user_data');

              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            } catch (e) {
              debugPrint('Logout error: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('حدث خطأ أثناء تسجيل الخروج')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _toggleItem(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}
