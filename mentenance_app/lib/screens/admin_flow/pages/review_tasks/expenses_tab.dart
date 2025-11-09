import 'package:flutter/material.dart';
import 'package:mentenance_app/screens/admin_flow/pages/review_tasks/review_service.dart';
import 'package:mentenance_app/core/constant/constant.dart';

class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  String _selectedExpenseFilter = 'الكل';
  bool _isLoading = true;
  List<Map<String, dynamic>> _expenses = [];
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final data = await ExpensesService.fetchAllExpenses();
      setState(() {
        _expenses = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ فشل في جلب المصاريف: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredExpenses {
    if (_selectedExpenseFilter == 'الكل') return _expenses;
    return _expenses
        .where((e) => e['status'] == _selectedExpenseFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            const SizedBox(height: 10),
            _buildExpenseFilterDropdown(),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredExpenses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final expense = filteredExpenses[index];
                  final isExpanded = _expandedIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedIndex = isExpanded ? null : index;
                      });
                    },
                    child: AnimatedExpenseCard(
                      expense: expense,
                      isExpanded: isExpanded,
                    ),
                  );
                },
              ),
            ),
          ],
        );
  }

  Widget _buildExpenseFilterDropdown() {
    final filters = ['الكل', 'Approved', 'Rejected', 'Pending'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedExpenseFilter,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
        items:
            filters
                .map((f) => DropdownMenuItem<String>(value: f, child: Text(f)))
                .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _selectedExpenseFilter = value);
        },
      ),
    );
  }
}

// -------------------- كرت متحرك للمصاريف --------------------
class AnimatedExpenseCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  final bool isExpanded;
  const AnimatedExpenseCard({
    super.key,
    required this.expense,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final double collapsedHeight = 115;
    final double expandedHeight = 400;

    // ✅ تجهيز الصورة الذكي
    final imagePath = expense['image'] ?? '';
    String? currentImageUrl;
    if (imagePath.isNotEmpty) {
      if (imagePath.startsWith('http')) {
        currentImageUrl = imagePath;
      } else {
        currentImageUrl = currentImageUrl = '${AppConfig.ip}$imagePath';
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isExpanded ? expandedHeight : collapsedHeight,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 الرأس
          Row(
            children: [
              CircleAvatar(
                radius: 22,
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
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense['date'],
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
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
                  const SizedBox(height: 6),
                  Text(
                    '${expense['amount']} ${expense['currency']}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 🔹 المحتوى الإضافي
          if (isExpanded) ...[
            const Divider(height: 20),
            _buildInfoRow(Icons.category, 'نوع المصروف', expense['type']),
            const SizedBox(height: 6),
            _buildInfoRow(
              Icons.info_outline,
              'الوصف',
              expense['description'] ?? 'غير متوفر',
            ),
            const SizedBox(height: 10),

            // 🔹 الصورة (مع العرض الكامل)
            if (currentImageUrl != null)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false,
                      pageBuilder:
                          (_, __, ___) =>
                              FullScreenImageViewer(imageUrl: currentImageUrl!),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    currentImageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          height: 140,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                  ),
                ),
              ),

            const SizedBox(height: 14),

            // 🔹 زرّي القبول والرفض
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final success = await ExpensesService.approveExpense(
                      expense['id'],
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? '✅ تم قبول المصروف بنجاح'
                              : '❌ فشل في قبول المصروف',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    'قبول',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    final success = await ExpensesService.rejectExpense(
                      expense['id'],
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? '❌ تم رفض المصروف بنجاح'
                              : '⚠️ فشل في رفض المصروف',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    'رفض',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              height: 1.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// 🔍 شاشة عرض الصورة بالحجم الكامل مع التكبير
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.9),
        body: SafeArea(
          child: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white70,
                      size: 80,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
