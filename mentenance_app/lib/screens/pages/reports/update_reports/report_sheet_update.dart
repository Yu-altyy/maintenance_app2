import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mentenance_app/screens/pages/public_appbar.dart';
import 'package:mentenance_app/screens/pages/reports/update_reports/report_update_service.dart';
import 'package:mentenance_app/screens/pages/reports/update_reports/update_sheet_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateReportScreen extends StatefulWidget {
  @override
  _UpdateReportScreenState createState() => _UpdateReportScreenState();
}

class _UpdateReportScreenState extends State<UpdateReportScreen> {
  // ====== البيانات الأساسية ======
  String warrantyStatus = 'active';
  String deviceId = '';
  String location = '';
  String model = '';
  String maintenanceDate = '';
  String maintenanceType = '';
  String operationStatus = '';
  String countingAccuracy = '';
  String notes = '';
  String clientName = '';
  String clientId = '';

  // ✅ متغيرات القوائم القادمة من التشيك بوكس
  List<String> selectedSensors = [];
  List<String> selectedCompletedWorks = [];
  List<String> selectedSafetyChecks = [];
  List<String> selectedSpareParts = [];

  // ====== توقيع العميل ======
  Uint8List? _clientSignature;

  @override
  void initState() {
    super.initState();
    _loadReportDetails(); // 🟢 جلب البيانات أول ما تفتح الصفحة
  }

  /// 🟢 دالة لجلب بيانات التقرير من السيرفر حسب reportId المخزن في SharedPreferences
  Future<void> _loadReportDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportId = prefs.getInt('selectedReportId');

      if (reportId == null) {
        print('❌ لا يوجد reportId في SharedPreferences');
        return;
      }

      final reportData = await MachineService.fetchReportDetails(reportId);

      setState(() {
        maintenanceType = reportData['MACHINE_INFO']?['maintenance_type'] ?? '';
        operationStatus =
            reportData['DEVICE_HEALTH']?['operational_status'] ?? '';
        countingAccuracy =
            reportData['DEVICE_HEALTH']?['counting_accuracy'] ?? '';
        notes = reportData['WORK_DETAILS']?['technician_notes'] ?? '';
        clientName = reportData['CLIENT_INFO']?['client_name'] ?? '';
        clientId = reportData['CLIENT_INFO']?['client_phone'] ?? '';

        // معلومات الجهاز
        model = reportData['MACHINE_INFO']?['model'] ?? '';
        deviceId = reportData['MACHINE_INFO']?['serial_number'] ?? '';
        location = reportData['MACHINE_INFO']?['location'] ?? '';

        // القوائم
        selectedSensors = List<String>.from(
          (reportData['DEVICE_HEALTH']?['checked_sensors'] ?? []).map(
            (e) => e['sensor_name'] ?? '',
          ),
        );
        selectedCompletedWorks = List<String>.from(
          (reportData['WORK_DETAILS']?['completed_works'] ?? []).map(
            (e) => e['name'] ?? '',
          ),
        );
        selectedSafetyChecks = List<String>.from(
          (reportData['WORK_DETAILS']?['safety_checks'] ?? []).map(
            (e) => e['name'] ?? '',
          ),
        );
        selectedSpareParts = List<String>.from(
          (reportData['WORK_DETAILS']?['parts_used_per_machine'] ?? []).map(
            (e) => e['part_name'] ?? '',
          ),
        );
      });

      print('✅ تم جلب بيانات التقرير رقم $reportId بنجاح');
    } catch (e) {
      print('❌ فشل في تحميل بيانات التقرير: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل بيانات التقرير: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'تعديل تقرير الصيانة'),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      children: [
                        // ✅ معلومات الجهاز
                        DeviceInfoWidget(
                          deviceId: deviceId,
                          location: location,
                          model: model,
                          maintenanceDate: maintenanceDate,
                          onDeviceIdChanged:
                              (value) => setState(() => deviceId = value),
                          onLocationChanged:
                              (value) => setState(() => location = value),
                          onModelChanged:
                              (value) => setState(() => model = value),
                          onDateChanged:
                              (value) =>
                                  setState(() => maintenanceDate = value),
                          onDetailsSelected: (details) {
                            setState(() {
                              selectedSensors = List<String>.from(
                                details['selectedSensors'],
                              );
                              selectedCompletedWorks = List<String>.from(
                                details['selectedCompletedWorks'],
                              );
                              selectedSafetyChecks = List<String>.from(
                                details['selectedSafetyChecks'],
                              );
                              selectedSpareParts = List<String>.from(
                                details['selectedSpareParts'],
                              );
                            });
                          },
                        ),

                        // نوع الصيانة
                        MaintenanceTypeWidget(
                          maintenanceType: maintenanceType,
                          onChanged:
                              (value) =>
                                  setState(() => maintenanceType = value),
                        ),

                        // حالة الجهاز
                        DeviceStatusWidget(
                          operationStatus: operationStatus,
                          countingAccuracy: countingAccuracy,
                          selectedSensors: selectedSensors,
                          onOperationStatusChanged:
                              (value) =>
                                  setState(() => operationStatus = value),
                          onCountingAccuracyChanged:
                              (value) =>
                                  setState(() => countingAccuracy = value),
                          onSensorsChanged:
                              (sensors) =>
                                  setState(() => selectedSensors = sensors),
                        ),

                        // الملاحظات
                        NotesWidget(
                          notes: notes,
                          onNotesChanged:
                              (value) => setState(() => notes = value),
                        ),

                        // معلومات العميل والتوقيع
                        ClientInfoWidget(
                          clientName: clientName,
                          clientId: clientId,
                          onClientNameChanged:
                              (value) => setState(() => clientName = value),
                          onClientIdChanged:
                              (value) => setState(() => clientId = value),
                          onSignatureChanged:
                              (signature) =>
                                  setState(() => _clientSignature = signature),
                        ),

                        // زر الحفظ والتحديث
                        SavePrintButton(
                          onSave: _updateReport,
                          reportData: {
                            'warrantyStatus': warrantyStatus,
                            'deviceId': deviceId,
                            'location': location,
                            'model': model,
                            'maintenanceDate': maintenanceDate,
                            'maintenanceType': maintenanceType,
                            'operationStatus': operationStatus,
                            'countingAccuracy': countingAccuracy,
                            'selectedSensors': selectedSensors,
                            'completedWorks': selectedCompletedWorks,
                            'safetyChecks': selectedSafetyChecks,
                            'selectedParts': selectedSpareParts,
                            'notes': notes,
                            'clientName': clientName,
                            'clientId': clientId,
                            'signature': _clientSignature,
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🟡 دالة تحديث التقرير
  Future<void> _updateReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportId = prefs.getInt('selectedReportId');
      if (reportId == null) {
        _showMessage('❌ لم يتم العثور على رقم التقرير');
        return;
      }

      final response = await MachineService.updateReport(
        reportId: reportId,
        maintenanceType: maintenanceType,
        operationalStatus: operationStatus,
        countingAccuracy: countingAccuracy,
        technicianNotes: notes,
        clientName: clientName,
        clientPhone: clientId,
        clientSignature: _clientSignature,
      );

      _showMessage('✅ تم تحديث التقرير بنجاح');
      print('📦 رد السيرفر: $response');
    } catch (e) {
      print('❌ خطأ أثناء تحديث التقرير: $e');
      _showMessage('حدث خطأ أثناء التحديث');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _clientSignature?.clear();
    super.dispose();
  }
}
