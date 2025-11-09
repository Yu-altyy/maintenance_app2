import 'package:flutter/material.dart';
import 'package:mentenance_app/screens/pages/expenses/edit_expences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'expenses_service.dart';

class ExpensesListTab extends StatefulWidget {
  @override
  _ExpensesListTabState createState() => _ExpensesListTabState();
}

class _ExpensesListTabState extends State<ExpensesListTab> {
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final data = await ExpensesService.fetchExpenses();
      setState(() {
        _expenses = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ Error loading expenses: $e');
    }
  }

  /// 🔹 تخزين ID المصروف عند الضغط على "تعديل" أو "حذف"
  Future<void> _saveExpenseId(int? id) async {
    if (id == null) {
      debugPrint('⚠️ خطأ: ID المصروف يساوي null');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedExpenseId', id);

    // ✅ طباعة للتأكد في الكونسول
    final savedId = prefs.getInt('selectedExpenseId');
    debugPrint('✅ تم حفظ ID المصروف في SharedPreferences: $savedId');
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses =
        _expenses.where((expense) {
          final matchesSearch =
              expense['task'].toString().contains(_searchQuery) ||
              expense['type'].toString().contains(_searchQuery);

          final matchesStatus =
              _selectedStatus == 'الكل'
                  ? true
                  : expense['status'] == _selectedStatus;

          return matchesSearch && matchesStatus;
        }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 10),
                    _buildFilterButtons(),
                    const SizedBox(height: 10),
                    Expanded(
                      child:
                          filteredExpenses.isEmpty
                              ? Center(
                                child: Text(
                                  'لا توجد مصاريف مطابقة',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                itemCount: filteredExpenses.length,
                                itemBuilder: (context, index) {
                                  final expense = filteredExpenses[index];
                                  return _buildExpenseCard(expense);
                                },
                              ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSearchBar() => TextField(
    decoration: InputDecoration(
      prefixIcon: const Icon(Icons.search, color: AppColors.secondary),
      hintText: 'ابحث حسب المهمة أو نوع المصروف...',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    ),
    onChanged: (value) {
      setState(() => _searchQuery = value);
    },
  );

  Widget _buildFilterButtons() {
    final filters = ['الكل', 'Approved', 'Pending', 'Rejected'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = filters[index];
          final isSelected = _selectedStatus == status;
          final color =
              status == 'Approved'
                  ? Colors.green[700]
                  : status == 'Pending'
                  ? Colors.orange[700]
                  : status == 'Rejected'
                  ? Colors.red[700]
                  : AppColors.secondary;
          return GestureDetector(
            onTap: () => setState(() => _selectedStatus = status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color!.withOpacity(0.15) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color! : Colors.grey[300]!,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 10, color: color),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) => Card(
    color: Colors.white,
    elevation: 3,
    shadowColor: Colors.black12,
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: expense['color'],
                child: const Icon(Icons.receipt_long, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense['description'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense['task'],
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.category,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(expense['type']),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(expense['date']),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text('${expense['amount']} ${expense['currency']}'),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: expense['color']!.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  expense['status'],
                  style: TextStyle(
                    color: expense['color'],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('تأكيد الحذف'),
                          content: const Text(
                            'هل أنت متأكد أنك تريد حذف هذا المصروف؟',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('إلغاء'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'حذف',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true) {
                    try {
                      await ExpensesService.deleteExpense(expense['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حذف المصروف بنجاح ✅')),
                      );
                      setState(() {
                        _expenses.removeWhere((e) => e['id'] == expense['id']);
                      });
                    } catch (e) {
                      debugPrint('❌ خطأ أثناء الحذف: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حدث خطأ أثناء الحذف: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('حذف'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),

              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  await _saveExpenseId(expense['id']); // ⬅️ أولاً خزّن الـ ID
                  debugPrint('✏️ ضغطت تعديل للمصروف ID: ${expense['id']}');

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditExpenseTab(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, color: AppColors.secondary),
                label: const Text('تعديل'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
