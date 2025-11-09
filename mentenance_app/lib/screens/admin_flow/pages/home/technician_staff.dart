import 'package:flutter/material.dart';

/// 🟢 كرت لفني واحد - تصميم أنيق
class TechnicalStaffCard extends StatelessWidget {
  final String name;
  final String email;
  final String phone;

  const TechnicalStaffCard({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الاسم: $email',
              style: const TextStyle(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'رقم الهاتف: $phone',
              style: const TextStyle(color: Colors.black45, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🟢 ويدجيت قائمة الفنيين
class TechnicalStaffWidget extends StatelessWidget {
  const TechnicalStaffWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // مثال على بيانات الفنيين
    final staffList = [
      {
        'name': 'محمد الأحمد',
        'specialty': 'كهرباء وصيانة أجهزة',
        'branch': 'فرع الرياض الرئيسي',
      },
      {
        'name': 'علي الحربي',
        'specialty': 'شبكات وأجهزة كمبيوتر',
        'branch': 'فرع جدة',
      },
      {
        'name': 'سارة الشمري',
        'specialty': 'صيانة هواتف وأجهزة ذكية',
        'branch': 'فرع الدمام',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: staffList.length,
      itemBuilder: (context, index) {
        final staff = staffList[index];
        return TechnicalStaffCard(
          name: staff['name']!,
          email: staff['email']!,
          phone: staff['phone']!,
        );
      },
    );
  }
}
