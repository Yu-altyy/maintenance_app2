import 'dart:ui' as flutter;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mentenance_app/screens/pages/reports/report_show_service.dart';
import 'package:mentenance_app/screens/pages/reports/show_single_report/report_details_screen.dart';
import 'package:mentenance_app/screens/pages/reports/update_reports/report_sheet_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'report_service.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/screens/pages/public_appbar.dart';
import 'package:mentenance_app/screens/pages/home/bottem_bar.dart';

class ReportsScreen extends StatefulWidget {
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _currentIndex = 2;
  List<Report> _reports = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isDateInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ar', null).then((_) {
      setState(() {
        _isDateInitialized = true;
      });
    });
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final data = await ReportService.fetchReports();
      setState(() {
        _reports = data;
        _isLoading = false;
      });
    } catch (e) {
      print('خطأ في تحميل التقارير: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Report> get filteredReports {
    final query = _searchController.text.trim();
    if (query.isEmpty) return _reports;
    return _reports.where((r) {
      return r.clientName?.contains(query) == true ||
          r.maintenanceType.contains(query) ||
          r.operationalStatus.contains(query);
    }).toList();
  }

  Future<void> _saveReportId(int reportId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedReportId', reportId);
    print('✅ تم حفظ رقم التقرير: $reportId');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: flutter.TextDirection.ltr,
      child: Scaffold(
        appBar: const CustomAppBar(title: 'التقارير'),
        backgroundColor: Colors.grey[100],
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_isDateInitialized
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSearchBox(),
                      const SizedBox(height: 20),
                      Expanded(
                        child:
                            filteredReports.isEmpty
                                ? const Center(
                                  child: Text(
                                    'لا توجد تقارير متاحة حالياً',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                                : ListView.separated(
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 12),
                                  itemCount: filteredReports.length,
                                  itemBuilder: (context, index) {
                                    final report = filteredReports[index];
                                    return _buildReportCard(report);
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }

  // 🔍 مربع البحث
  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textAlign: TextAlign.right, // ✅ اجعل النص يبدأ من اليمين
        decoration: const InputDecoration(
          hintText: 'ابحث باسم العميل أو نوع الصيانة...',
          hintTextDirection:
              flutter.TextDirection.ltr, // ✅ حتى النص داخل الحقل يكون ltr
          prefixIcon: Icon(Icons.search, color: AppColors.secondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  // 🧾 كرت التقرير
  Widget _buildReportCard(Report report) {
    final date =
        _isDateInitialized
            ? DateFormat(
              'yyyy-MM-dd',
              'ar',
            ).format(DateTime.parse(report.createdAt))
            : report.createdAt;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Directionality(
        // ✅ تأكيد الاتجاه داخل الكرت
        textDirection: flutter.TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "تقرير رقم ${report.taskReportId}",
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "النوع: ${report.maintenanceType}",
              textAlign: TextAlign.right,
            ),
            Text(
              "الحالة التشغيلية: ${report.operationalStatus}",
              textAlign: TextAlign.right,
            ),
            if (report.clientName != null)
              Text(
                "العميل: ${report.clientName} (${report.clientPhone ?? ''})",
                textAlign: TextAlign.right,
              ),
            Text("تاريخ الإنشاء: $date", textAlign: TextAlign.right),
            const SizedBox(height: 12),
            Row(
              textDirection:
                  flutter.TextDirection.ltr, // ✅ يجعل الأزرار من اليمين لليسار
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(
                  label: 'عرض',
                  color: AppColors.primary,
                  onPressed: () async {
                    await _saveReportId(report.taskReportId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportDetailsPage(),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  label: 'تعديل',
                  color: AppColors.secondary,
                  onPressed: () async {
                    await _saveReportId(report.taskReportId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpdateReportScreen(),
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

  // 🎛 زر الإجراء
  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
