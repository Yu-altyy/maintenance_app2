import 'dart:math';
import 'dart:ui' as flutter;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/screens/admin_flow/pages/home/bottom_bar.dart';
import 'package:mentenance_app/screens/pages/home/bottem_bar.dart';
import 'package:mentenance_app/screens/pages/public_appbar.dart';
import 'package:mentenance_app/screens/pages/reports/report_sheet.dart';

class ReviwReport extends StatefulWidget {
  @override
  State<ReviwReport> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReviwReport> {
  DateFormat? _dateFormat;
  int _currentIndex = 2;

  final TextEditingController _searchController = TextEditingController();

  final List<Report> _allReports = List.generate(
    8,
    (i) => Report(
      id: 'RPT${1000 + i}',
      name: 'تقرير صيانة رقم ${i + 1}',
      date: DateTime(2025, 10, 1 + i),
      code: 'QR${Random().nextInt(999999)}',
    ),
  );

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ar', null).then((_) {
      setState(() {
        _dateFormat = DateFormat('yyyy-MM-dd', 'ar');
      });
    });
  }

  List<Report> get filteredReports {
    final query = _searchController.text.trim();
    if (query.isEmpty) return _allReports;
    return _allReports.where((r) => r.code.contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: flutter.TextDirection.rtl,
      child: Scaffold(
        appBar: const CustomAppBar(title: 'التقارير'),
        backgroundColor: Colors.grey[100],

        body:
            _dateFormat == null
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 🔍 حقل البحث حسب الكود
                      Container(
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
                          decoration: InputDecoration(
                            hintText: 'ابحث حسب رقم التقرير...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.secondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ✅ قائمة التقارير
                      Expanded(
                        child:
                            filteredReports.isEmpty
                                ? const Center(
                                  child: Text(
                                    'لا توجد تقارير مطابقة للبحث',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                                : ListView.separated(
                                  itemCount: filteredReports.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final report = filteredReports[index];
                                    return _buildReportCard(report);
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
        bottomNavigationBar: ADminBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }

  // ✅ كارت التقرير
  Widget _buildReportCard(Report report) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Column(
            children: [
              BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: report.code,
                width: 80,
                height: 80,
              ),
              const SizedBox(height: 8),
              Text(
                report.code,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  report.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _dateFormat!.format(report.date),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ موديل التقرير
class Report {
  final String id;
  final String name;
  final DateTime date;
  final String code;

  Report({
    required this.id,
    required this.name,
    required this.date,
    required this.code,
  });
}
