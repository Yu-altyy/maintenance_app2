import 'package:flutter/material.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/screens/pages/login/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondary, AppColors.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: const [
              SizedBox(height: 80),
              Icon(Icons.qr_code_2, size: 80, color: AppColors.white),
              SizedBox(height: 10),
              Text(
                "PROSCAN",
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "تطبيق الفنيين المتخصص",
                style: TextStyle(color: AppColors.white, fontSize: 16),
              ),
              SizedBox(height: 40),
              LoginForm(), // ← الفورم صار مكون مستقل
            ],
          ),
        ),
      ),
    );
  }
}
