import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/data/services/auth.dart';
import 'package:mentenance_app/screens/pages/forget_password/reset_password.dart';
import 'package:mentenance_app/screens/pages/public_appbar.dart';

class VerificationCodePage extends StatefulWidget {
  final String resetToken; // التوكن من صفحة البريد
  const VerificationCodePage({Key? key, required this.resetToken})
    : super(key: key);

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _remainingSeconds = 60;
  bool _expired = false;
  bool _verifying = false;

  final VerificationService _service = VerificationService();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _remainingSeconds = 60;
    _expired = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        setState(() => _expired = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildCodeField(int index) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        enabled: !_expired && !_verifying,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          filled: true,
          fillColor: AppColors.white1,
        ),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        onChanged: (val) {
          if (val.isNotEmpty && index < _controllers.length - 1) {
            _focusNodes[index + 1].requestFocus();
          }
          if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          // تحقق تلقائي عند إدخال 6 خانات
          if (_controllers.every((c) => c.text.isNotEmpty)) {
            _verifyCode();
          }
        },
      ),
    );
  }

  Future<void> _verifyCode() async {
    if (_verifying) return;
    setState(() => _verifying = true);

    final code = _controllers.map((c) => c.text).join();

    try {
      final msg = await _service.verifyCode(
        resetToken: widget.resetToken,
        code: code,
      );

      _showMessage(msg);

      // ✅ عند نجاح التحقق الانتقال لصفحة إعادة تعيين كلمة المرور وتمرير resetToken
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(resetToken: widget.resetToken),
        ),
      );
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
      for (var c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    } finally {
      setState(() => _verifying = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: 'التحقق من الكود'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text(
              'أدخل رمز التحقق المكون من 6 أرقام',
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, _buildCodeField),
            ),
            const SizedBox(height: 20),
            Text(
              _expired
                  ? 'انتهت المهلة، أعد إرسال الكود'
                  : 'الوقت المتبقي: $_remainingSeconds ثانية',
              style: const TextStyle(color: AppColors.secondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _expired ? _startTimer : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('إعادة إرسال الكود'),
            ),
          ],
        ),
      ),
    );
  }
}
