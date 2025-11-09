import 'package:flutter/material.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/screens/admin_flow/pages/add_task/add_task_page.dart';

class CustomHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;

  const CustomHomeAppBar({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddTaskPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ),
              TabBar(
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                controller: tabController,
                indicatorColor: Colors.white,
                tabs: const [Tab(text: 'المهام'), Tab(text: 'الفنيين')],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}
