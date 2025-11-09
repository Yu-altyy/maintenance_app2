import 'package:flutter/material.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/screens/admin_flow/pages/home/bottom_bar.dart';
import 'package:mentenance_app/screens/admin_flow/pages/review_tasks/expenses_tab.dart';

// استيراد التابين المنفصلين
import 'tasks_tab.dart';

class ReviwTask extends StatefulWidget {
  const ReviwTask({super.key});

  @override
  State<ReviwTask> createState() => _ReviwTaskState();
}

class _ReviwTaskState extends State<ReviwTask>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            child: AppBar(
              backgroundColor: AppColors.secondary,
              toolbarHeight: 120,
              title: const Text('الصفحة الرئيسية'),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [Tab(text: 'المهام'), Tab(text: 'المصاريف')],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [TasksTab(), ExpensesTab()],
        ),
        bottomNavigationBar: ADminBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}
