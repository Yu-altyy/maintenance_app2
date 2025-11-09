import 'package:flutter/material.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'add_expense_tab.dart';
import 'expenses_list_tab.dart';

class ExpensesManagerScreen extends StatefulWidget {
  @override
  _ExpensesManagerScreenState createState() => _ExpensesManagerScreenState();
}

class _ExpensesManagerScreenState extends State<ExpensesManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'نظام مصاريف الفنيين',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.secondary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelColor: Colors.white, // لون التاب المحدد
          unselectedLabelColor: Colors.white70, // لون التاب غير المحدد
          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'إضافة مصروف'),
            Tab(icon: Icon(Icons.list_alt), text: 'عرض المصاريف'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [AddExpenseTab(), ExpensesListTab()],
      ),
    );
  }
}
