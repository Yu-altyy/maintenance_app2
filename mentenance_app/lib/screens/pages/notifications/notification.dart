import 'package:flutter/material.dart';
import 'package:mentenance_app/screens/pages/public_appbar.dart';

class NotificationItem {
  final String title;
  final String subtitle;
  final String time;
  final NotificationType type;

  NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    this.type = NotificationType.info,
  });
}

enum NotificationType { info, message, urgent }

class NotificationsPage extends StatelessWidget {
  final List<NotificationItem> items = [
    NotificationItem(
      title: 'مهمة صيانة عاجلة',
      subtitle: 'لديك مهمة صيانة الآن - برجاء الحضور فوراً',
      time: 'قبل 2 دقيقة',
      type: NotificationType.urgent,
    ),
    NotificationItem(
      title: 'رسالة من أحمد',
      subtitle: 'أرسل لك رسالة جديدة: هل تستطيع الحضور غداً؟',
      time: 'قبل 10 دقائق',
      type: NotificationType.message,
    ),
    NotificationItem(
      title: 'تحديث النظام',
      subtitle: 'تم جدولة تحديث يوم الجمعة القادم',
      time: 'أمس',
      type: NotificationType.info,
    ),
    NotificationItem(
      title: 'مهمة مجدولة',
      subtitle: 'مهمة فحص جهاز التكييف الساعة 3:00 م',
      time: 'اليوم 08:00',
      type: NotificationType.info,
    ),
  ];

  NotificationsPage({Key? key}) : super(key: key);

  Color _typeColor(NotificationType t) {
    switch (t) {
      case NotificationType.urgent:
        return Colors.red.shade600;
      case NotificationType.message:
        return Colors.blue.shade600;
      case NotificationType.info:
      default:
        return Colors.green.shade600;
    }
  }

  IconData _typeIcon(NotificationType t) {
    switch (t) {
      case NotificationType.urgent:
        return Icons.report_problem_outlined;
      case NotificationType.message:
        return Icons.message_outlined;
      case NotificationType.info:
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(title: 'الإشعارات'),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final it = items[index];
              return _buildCard(context, it);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, NotificationItem it) {
    final color = _typeColor(it.type);

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تم فتح: ${it.title}')));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_typeIcon(it.type), color: color, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        it.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    it.time,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(it.subtitle, style: TextStyle(color: Colors.grey.shade800)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم فتح المهمة: ${it.title}')),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('فتح المهمة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم تجاهل الإشعار: ${it.title}'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('تجاهل'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: color.withOpacity(0.6)),
                        foregroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
