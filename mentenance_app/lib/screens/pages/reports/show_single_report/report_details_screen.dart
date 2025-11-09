import 'package:flutter/material.dart';
import 'package:mentenance_app/screens/pages/public_appbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentenance_app/screens/pages/reports/update_reports/report_update_service.dart';

class ReportDetailsPage extends StatefulWidget {
  const ReportDetailsPage({super.key});

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  Future<Map<String, dynamic>>? reportFuture;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final prefs = await SharedPreferences.getInstance();
    final reportId = prefs.getInt('selectedReportId');
    if (reportId == null) {
      throw Exception("❌ لا يوجد reportId محفوظ في SharedPreferences");
    }

    setState(() {
      reportFuture = MachineService.fetchReportDetails(reportId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: CustomAppBar(title: 'تفاصيل التقرير'),
        body:
            reportFuture == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<Map<String, dynamic>>(
                  future: reportFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "حدث خطأ أثناء تحميل البيانات:\n${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData) {
                      return const Center(
                        child: Text(
                          "لا توجد بيانات متاحة.",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }

                    final data = snapshot.data!;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _mainHeader(data),
                          const SizedBox(height: 16),
                          _buildSection(
                            title: "معلومات الجهاز",
                            icon: Icons.memory,
                            children: [
                              _infoRow(
                                "الرقم التسلسلي",
                                data["MACHINE_INFO"]["serial_number"],
                              ),
                              _infoRow(
                                "الموديل",
                                data["MACHINE_INFO"]["model"],
                              ),
                              _infoRow(
                                "الموقع",
                                data["MACHINE_INFO"]["location"],
                              ),
                              _infoRow(
                                "نوع الصيانة",
                                data["MACHINE_INFO"]["maintenance_type"],
                              ),
                            ],
                          ),
                          _buildSection(
                            title: "حالة الجهاز",
                            icon: Icons.settings_suggest,
                            children: [
                              _infoRow(
                                "الحالة التشغيلية",
                                data["DEVICE_HEALTH"]["operational_status"],
                              ),
                              _infoRow(
                                "دقة العد",
                                data["DEVICE_HEALTH"]["counting_accuracy"],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "فحص الحساسات:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...List.generate(
                                (data["DEVICE_HEALTH"]["checked_sensors"]
                                        as List)
                                    .length,
                                (i) {
                                  final s =
                                      data["DEVICE_HEALTH"]["checked_sensors"][i];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    child: Text(
                                      "• ${s['sensor_name']} — ${s['status']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          _buildSection(
                            title: "تفاصيل العمل",
                            icon: Icons.task_alt,
                            children: [
                              _infoRow(
                                "نوع المشكلة",
                                data["WORK_DETAILS"]["problem_type"],
                              ),
                              _infoRow(
                                "ملاحظات الفني",
                                data["WORK_DETAILS"]["technician_notes"],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "الأعمال المنجزة:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ..._listItems(
                                data["WORK_DETAILS"]["completed_works"],
                                "name",
                                "status",
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "فحوصات السلامة:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ..._listItems(
                                data["WORK_DETAILS"]["safety_checks"],
                                "name",
                                "result",
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "قطع الغيار المستخدمة:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...List.generate(
                                (data["WORK_DETAILS"]["parts_used_per_machine"]
                                        as List)
                                    .length,
                                (i) {
                                  final p =
                                      data["WORK_DETAILS"]["parts_used_per_machine"][i];
                                  return Text(
                                    "• ${p['part_name']} (${p['part_number']}) — الكمية: ${p['quantity']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          _buildSection(
                            title: "معلومات العميل",
                            icon: Icons.person_outline,
                            children: [
                              _infoRow(
                                "اسم العميل",
                                data["CLIENT_INFO"]["client_name"],
                              ),
                              _infoRow(
                                "رقم الهاتف",
                                data["CLIENT_INFO"]["client_phone"],
                              ),
                              const SizedBox(height: 10),
                              if (data["CLIENT_INFO"]["client_signature"] !=
                                  null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "توقيع العميل:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        data["CLIENT_INFO"]["client_signature"],
                                        height: 120,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const Text(
                                  "لا يوجد توقيع.",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                          if (data["INVOICE"] != null)
                            _buildSection(
                              title: "بيانات الفاتورة",
                              icon: Icons.receipt_long,
                              children: [
                                _infoRow(
                                  "رقم الفاتورة",
                                  data["INVOICE"]["invoice_id"].toString(),
                                ),
                                _infoRow("الحالة", data["INVOICE"]["status"]),
                                _infoRow(
                                  "المبلغ الكلي",
                                  data["INVOICE"]["total_amount"].toString(),
                                ),
                                _infoRow(
                                  "الضريبة",
                                  data["INVOICE"]["tax_amount"].toString(),
                                ),
                              ],
                            ),
                          _buildSection(
                            title: "هيكل المهمة",
                            icon: Icons.account_tree,
                            children: [
                              _infoRow(
                                "Task ID",
                                data["TASK_HIERARCHY"]["task_id"].toString(),
                              ),
                              _infoRow(
                                "مهمة فرعية؟",
                                data["TASK_HIERARCHY"]["is_subtask"] == true
                                    ? "نعم"
                                    : "لا",
                              ),
                              _infoRow(
                                "نوع مشكلة الأصل",
                                data["TASK_HIERARCHY"]["parent_problem_type"]
                                    .toString(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }

  // 🧩 رأس الصفحة
  Widget _mainHeader(Map<String, dynamic> data) {
    final maintenanceType = data["MACHINE_INFO"]["maintenance_type"];
    final warranty = data["WARRANTY_STATUS"];
    final reportId = data["REPORT_ID"];
    final isWarranted = warranty["is_warranted"] == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardStyle(),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "تقرير صيانة رقم #$reportId",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _chip("نوع الصيانة: $maintenanceType", Colors.indigo),
              _chip(
                isWarranted ? "ضمن الكفالة" : "خارج الكفالة",
                isWarranted ? Colors.green : Colors.red,
              ),
              _chip(warranty["warranty_name"], Colors.blueGrey),
            ],
          ),
        ],
      ),
    );
  }

  // 🧩 أقسام البيانات
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // ✅ الصف بشكل "العنوان: القيمة"
  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        textDirection: TextDirection.rtl,
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(text: "$label: "),
            TextSpan(text: value?.toString() ?? "—"),
          ],
        ),
      ),
    );
  }

  List<Widget> _listItems(
    List<dynamic> items,
    String titleKey,
    String statusKey,
  ) {
    return List.generate(items.length, (i) {
      final item = items[i];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(
          "• ${item[titleKey]} — ${item[statusKey]}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    });
  }

  BoxDecoration _cardStyle() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 6)),
    ],
    border: Border.all(color: Color(0xFFE5EAF2)),
  );

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
