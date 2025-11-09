import 'package:flutter/material.dart';
import 'package:mentenance_app/screens/pages/public_appbar.dart';
import 'package:mentenance_app/screens/pages/reports/sheet_wedgit.dart';
import 'dart:typed_data';

class MaintenanceReportScreen extends StatefulWidget {
  @override
  _MaintenanceReportScreenState createState() =>
      _MaintenanceReportScreenState();
}

class _MaintenanceReportScreenState extends State<MaintenanceReportScreen> {
  // ====== البيانات الأساسية ======
  String warrantyStatus = 'active';
  String deviceId = 'PROSCAN-6P-001247';
  String location = 'فرع الرياض الرئيسي';
  String model = 'PROSCAN-P6';
  String maintenanceDate = '2025-10-01';
  String maintenanceType = 'corrective';
  String operationStatus = 'يعمل مع مشاكل';
  String countingAccuracy = 'ضعيفة (أقل من 90%)';

  // ✅ متغيرات القوائم القادمة من التشيك بوكس
  List<String> selectedSensors = [];
  List<String> selectedCompletedWorks = [];
  List<String> selectedSafetyChecks = [];
  List<String> selectedSpareParts = [];

  List<String> faultTypes = ['ميكانيكي'];
  bool sparePartsRequested = false;
  String notes = '';
  String clientName = '';
  String clientId = '';

  // ====== توقيع العميل ======
  Uint8List? _clientSignature;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'التقرير النهائي للصيانة'),
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

                          // 🟢 نستقبل القوائم المختارة من الودجيت
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

                        // زر الحفظ والطباعة
                        SavePrintButton(
                          onSave: _saveReport,
                          reportData: {
                            // حالة الكفالة فقط
                            'warrantyStatus': warrantyStatus,

                            // معلومات الجهاز
                            'deviceId': deviceId,
                            'location': location,
                            'model': model,
                            'maintenanceDate': maintenanceDate,

                            // نوع الصيانة
                            'maintenanceType': maintenanceType,

                            // حالة الجهاز
                            'operationStatus': operationStatus,
                            'countingAccuracy': countingAccuracy,
                            'selectedSensors': selectedSensors,

                            // الأعمال المنجزة
                            'completedWorks': selectedCompletedWorks,

                            // نوع العطل
                            'faultTypes': faultTypes,

                            // قطع الغيار
                            'sparePartsRequested': sparePartsRequested,
                            'selectedParts': selectedSpareParts,

                            // فحوصات السلامة
                            'safetyChecks': selectedSafetyChecks,

                            // الملاحظات
                            'notes': notes,

                            // معلومات العميل
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

  Future<void> _saveReport() async {
    // التحقق من وجود التوقيع قبل الحفظ
    if (_clientSignature == null) {
      _showMessage('الرجاء حفظ توقيع العميل أولاً');
      return;
    }

    await Future.delayed(Duration(milliseconds: 100));
    print('تم حفظ التقرير مع التوقيع');
    _showMessage('تم حفظ التقرير بنجاح');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    // تنظيف الذاكرة من التوقيع
    _clientSignature?.clear();
    super.dispose();
  }
}
