import 'package:flutter/material.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/screens/pages/home/home_page.dart';
import 'package:mentenance_app/screens/pages/notifications/notification.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      child: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 1,
        automaticallyImplyLeading: false,
        toolbarHeight: 50, // 👈 يقلل ارتفاع الشريط نفسه
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // زر التحديث
                IconButton(
                  icon: const Icon(Icons.refresh, size: 22),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const TasksPage(),
                        transitionDuration: Duration.zero,
                      ),
                    );
                  },
                ),
                // زر الإشعارات
                IconButton(
                  icon: const Icon(Icons.notifications, size: 22),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 👇 نضبط الارتفاع الكلي للـ AppBar
  @override
  Size get preferredSize => const Size.fromHeight(55);
}
