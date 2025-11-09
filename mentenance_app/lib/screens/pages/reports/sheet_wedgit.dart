import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mentenance_app/screens/pages/reports/report_service.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

// =============================================
// Base Section Widget - القسم الأساسي
// =============================================

class _BaseSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _BaseSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// =============================================
// Input Widgets - ويدجيتات الإدخال
// =============================================

class InputField extends StatefulWidget {
  final String label;
  final String value;
  final Function(String) onChanged;
  final bool isDate;

  const InputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isDate = false,
  });

  @override
  _InputFieldState createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant InputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        SizedBox(height: 4),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          textDirection: TextDirection.rtl, // هذا مهم للعربي
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue),
            ),
            suffixIcon: widget.isDate ? Icon(Icons.calendar_today) : null,
            fillColor: Colors.grey[50],
            filled: true,
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Function(String) onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          items:
              items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
          onChanged: (value) => onChanged(value ?? ''),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.all(8),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _CheckboxList extends StatefulWidget {
  final String label;
  final List<String> items;
  final List<String> selectedItems;
  final Function(List<String>) onChanged;

  const _CheckboxList({
    required this.label,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
  });

  @override
  State<_CheckboxList> createState() => _CheckboxListState();
}

class _CheckboxListState extends State<_CheckboxList> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selectedItems);
  }

  @override
  void didUpdateWidget(covariant _CheckboxList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إذا تغيرت العناصر المختارة من خارج الودجت، نحدثها هون
    if (oldWidget.selectedItems != widget.selectedItems) {
      _selected = List<String>.from(widget.selectedItems);
    }
  }

  void _toggleItem(String item, bool? value) {
    setState(() {
      if (value == true) {
        _selected.add(item);
      } else {
        _selected.remove(item);
      }
    });
    widget.onChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        SizedBox(height: 4),
        ...widget.items.map(
          (item) => CheckboxListTile(
            title: Text(item, textDirection: TextDirection.rtl),
            value: _selected.contains(item),
            onChanged: (value) => _toggleItem(item, value),
            controlAffinity:
                ListTileControlAffinity.leading, // ✅ التشيك على اليمين
            activeColor: Colors.blue,
          ),
        ),
      ],
    );
  }
}

// =============================================
// Main Widgets - الودجيتات الرئيسية
// =============================================

class DeviceInfoWidget extends StatefulWidget {
  final String deviceId, location, model, maintenanceDate;
  final Function(String) onDeviceIdChanged,
      onLocationChanged,
      onModelChanged,
      onDateChanged;
  final Function(Map<String, dynamic>)
  onDetailsSelected; // 🆕 لإرسال التفاصيل المختارة للتقرير

  const DeviceInfoWidget({
    required this.deviceId,
    required this.location,
    required this.model,
    required this.maintenanceDate,
    required this.onDeviceIdChanged,
    required this.onLocationChanged,
    required this.onModelChanged,
    required this.onDateChanged,
    required this.onDetailsSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<DeviceInfoWidget> createState() => _DeviceInfoWidgetState();
}

class _DeviceInfoWidgetState extends State<DeviceInfoWidget> {
  List<dynamic> _machines = [];
  String? _selectedSerial;
  Map<String, dynamic>? _selectedMachine;
  Map<String, dynamic>? _machineDetails;

  bool _isLoading = true;
  bool _isDetailsLoading = false;

  // ✅ هنا نخزن التحديدات
  List<String> selectedSensors = [];
  List<String> selectedCompletedWorks = [];
  List<String> selectedSafetyChecks = [];
  List<String> selectedSpareParts = [];

  @override
  void initState() {
    super.initState();
    _fetchMachines();
  }

  /// ✅ جلب قائمة الماكينات
  Future<void> _fetchMachines() async {
    try {
      final machines = await MachineService.fetchMachines();
      setState(() {
        _machines = machines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في جلب بيانات الماكينات: $e')),
      );
    }
  }

  /// ✅ تخزين ID في SharedPreferences
  Future<void> _saveMachineId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedMachineId', id);
    print('✅ Machine ID saved: $id');
  }

  /// ✅ جلب تفاصيل الآلة من الـ API
  Future<void> _fetchMachineDetails(String machineId) async {
    if (machineId.isEmpty) return;
    setState(() => _isDetailsLoading = true);
    try {
      final details = await MachineService.fetchMachineDetails(
        int.parse(machineId),
      );
      setState(() {
        _machineDetails = details;
        // تصفير الاختيارات عند تحميل آلة جديدة
        selectedSensors = [];
        selectedCompletedWorks = [];
        selectedSafetyChecks = [];
        selectedSpareParts = [];
      });
      print('✅ Machine Details loaded for ID: $machineId');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل في جلب تفاصيل الآلة: $e')));
    } finally {
      setState(() => _isDetailsLoading = false);
    }
  }

  void _updateSelectedData() {
    // 🟢 إرسال كل التحديدات لواجهة التقرير
    widget.onDetailsSelected({
      "selectedSensors": selectedSensors,
      "selectedCompletedWorks": selectedCompletedWorks,
      "selectedSafetyChecks": selectedSafetyChecks,
      "selectedSpareParts": selectedSpareParts,
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSection(
      title: 'معلومات الجهاز',
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 Dropdown لاختيار السيريال نمبر
                  DropdownButtonFormField<String>(
                    value: _selectedSerial,
                    decoration: InputDecoration(
                      labelText: 'الرقم التسلسلي (Serial Number)',
                      labelStyle: const TextStyle(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: const Icon(
                        Icons.qr_code_2,
                        color: Colors.blue,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down_circle_outlined,
                      color: Colors.blue,
                    ),
                    items:
                        _machines
                            .map(
                              (m) => DropdownMenuItem<String>(
                                value: m['serial_number'],
                                child: Text(
                                  m['serial_number'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedSerial = value;
                        _selectedMachine = _machines.firstWhere(
                          (m) => m['serial_number'] == value,
                        );
                        _machineDetails = null;
                      });

                      final machineId =
                          _selectedMachine?['machine_id'].toString() ?? '';

                      widget.onDeviceIdChanged(machineId);
                      widget.onModelChanged(_selectedMachine?['model'] ?? '');
                      widget.onLocationChanged(
                        _selectedMachine?['location'] ?? '',
                      );

                      await _saveMachineId(machineId);
                      await _fetchMachineDetails(machineId);
                    },
                  ),

                  const SizedBox(height: 22),

                  /// 🔹 كارد معلومات الآلة
                  if (_selectedMachine != null)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.memory, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedMachine!['model'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedMachine!['location'],
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  /// 🔹 تحميل تفاصيل الآلة
                  if (_isDetailsLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  /// 🔹 عند توفر تفاصيل الآلة
                  if (_machineDetails != null && !_isDetailsLoading) ...[
                    const SizedBox(height: 16),

                    _CheckboxList(
                      label: 'حساسات كشف التزوير:',
                      items: List<String>.from(
                        (_machineDetails!['available_sensors'] ?? []).map(
                          (e) => e['name'] ?? 'غير معروف',
                        ),
                      ),
                      selectedItems: selectedSensors,
                      onChanged: (v) {
                        setState(() => selectedSensors = v);
                        _updateSelectedData();
                      },
                    ),

                    const Divider(thickness: 1.2, color: Colors.grey),

                    _CheckboxList(
                      label: 'الأعمال المنجزة:',
                      items: List<String>.from(
                        (_machineDetails!['available_completed_works'] ?? [])
                            .map((e) => e['name'] ?? 'غير معروف'),
                      ),
                      selectedItems: selectedCompletedWorks,
                      onChanged: (v) {
                        setState(() => selectedCompletedWorks = v);
                        _updateSelectedData();
                      },
                    ),

                    const Divider(thickness: 1.2, color: Colors.grey),

                    _CheckboxList(
                      label: 'فحوصات السلامة:',
                      items: List<String>.from(
                        (_machineDetails!['available_safety_checks'] ?? []).map(
                          (e) => e['name'] ?? 'غير معروف',
                        ),
                      ),
                      selectedItems: selectedSafetyChecks,
                      onChanged: (v) {
                        setState(() => selectedSafetyChecks = v);
                        _updateSelectedData();
                      },
                    ),

                    const Divider(thickness: 1.2, color: Colors.grey),

                    _CheckboxList(
                      label: 'قطع الغيار المتاحة:',
                      items: List<String>.from(
                        (_machineDetails!['available_spare_parts'] ?? []).map(
                          (e) =>
                              '${e['name'] ?? 'بدون اسم'} (${e['part_number'] ?? ''})',
                        ),
                      ),
                      selectedItems: selectedSpareParts,
                      onChanged: (v) {
                        setState(() => selectedSpareParts = v);
                        _updateSelectedData();
                      },
                    ),
                  ],
                ],
              ),
    );
  }
}

class MaintenanceTypeWidget extends StatelessWidget {
  final String maintenanceType;
  final Function(String) onChanged;

  const MaintenanceTypeWidget({
    required this.maintenanceType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseSection(
      title: 'نوع الصيانة',
      child: Column(
        children: [
          RadioListTile(
            title: Text('تشغيلية'),
            value: 'تشغيلية',
            groupValue: maintenanceType,
            onChanged: (value) => onChanged(value.toString()),
          ),
          RadioListTile(
            title: Text('وقائية'),
            value: 'وقائية',
            groupValue: maintenanceType,
            onChanged: (value) => onChanged(value.toString()),
          ),
          RadioListTile(
            title: Text('عاجلة'),
            value: 'عاجلة',
            groupValue: maintenanceType,
            onChanged: (value) => onChanged(value.toString()),
          ),
          RadioListTile(
            title: Text('تصحيحية'),
            value: 'تصحيحية',
            groupValue: maintenanceType,
            onChanged: (value) => onChanged(value.toString()),
          ),
          RadioListTile(
            title: Text('تطويرية'),
            value: 'تطويرية',
            groupValue: maintenanceType,
            onChanged: (value) => onChanged(value.toString()),
          ),
        ],
      ),
    );
  }
}

class DeviceStatusWidget extends StatelessWidget {
  final String operationStatus, countingAccuracy;
  final List<String> selectedSensors;
  final Function(String) onOperationStatusChanged, onCountingAccuracyChanged;
  final Function(List<String>) onSensorsChanged;

  const DeviceStatusWidget({
    required this.operationStatus,
    required this.countingAccuracy,
    required this.selectedSensors,
    required this.onOperationStatusChanged,
    required this.onCountingAccuracyChanged,
    required this.onSensorsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseSection(
      title: 'حالة الجهاز',
      child: Column(
        children: [
          _DropdownField(
            label: 'حالة التشغيل:',
            value: operationStatus,
            items: [
              'يعمل بشكل طبيعي',
              'يعمل مع مشاكل',
              'لا يعمل',
              'تحت الصيانة',
            ],
            onChanged: onOperationStatusChanged,
          ),
          SizedBox(height: 12),
          _DropdownField(
            label: 'دقة العد:',
            value: countingAccuracy,
            items: [
              'ممتازة (100%)',
              'جيدة (95-99%)',
              'مقبولة (90-94%)',
              'ضعيفة (أقل من 90%)',
            ],
            onChanged: onCountingAccuracyChanged,
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }
}

class NotesWidget extends StatefulWidget {
  final String notes;
  final Function(String) onNotesChanged;

  const NotesWidget({
    required this.notes,
    required this.onNotesChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<NotesWidget> createState() => _NotesWidgetState();
}

class _NotesWidgetState extends State<NotesWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.notes);
  }

  @override
  void didUpdateWidget(covariant NotesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes) {
      _controller.text = widget.notes;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSection(
      title: 'ملاحظات إضافية',
      child: TextField(
        controller: _controller,
        onChanged: widget.onNotesChanged,
        maxLines: 3,
        textDirection: TextDirection.rtl, // الكتابة من اليمين لليسار
        decoration: InputDecoration(
          hintText: 'أدخل أي ملاحظات أو تعليقات إضافية',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

class ClientInfoWidget extends StatefulWidget {
  final String clientName, clientId;
  final Function(String) onClientNameChanged, onClientIdChanged;
  final Function(Uint8List?) onSignatureChanged;

  const ClientInfoWidget({
    required this.clientName,
    required this.clientId,
    required this.onClientNameChanged,
    required this.onClientIdChanged,
    required this.onSignatureChanged,
  });

  @override
  _ClientInfoWidgetState createState() => _ClientInfoWidgetState();
}

class _ClientInfoWidgetState extends State<ClientInfoWidget> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  Uint8List? _signatureImage;
  bool _isSigned = false;

  @override
  void initState() {
    super.initState();
    _signatureController.addListener(
      () => setState(() => _isSigned = !_signatureController.isEmpty),
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  void _clearSignature() {
    setState(() {
      _signatureController.clear();
      _signatureImage = null;
      _isSigned = false;
      widget.onSignatureChanged(null);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('تم مسح التوقيع')));
  }

  Future<void> _saveSignature() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('الرجاء التوقيع أولاً')));
      return;
    }
    try {
      final signatureData = await _signatureController.toPngBytes();
      if (signatureData != null) {
        setState(() => _signatureImage = signatureData);
        widget.onSignatureChanged(signatureData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ التوقيع بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في حفظ التوقيع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSection(
      title: 'معلومات العميل',
      child: Column(
        children: [
          InputField(
            label: 'اسم العميل:',
            value: widget.clientName,
            onChanged: widget.onClientNameChanged,
          ),
          SizedBox(height: 12),
          InputField(
            label: 'رقم العميل:',
            value: widget.clientId,
            onChanged: widget.onClientIdChanged,
          ),
          SizedBox(height: 12),
          _buildSignatureSection(),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'توقيع العميل:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            SizedBox(width: 8),
            if (_isSigned) _buildBadge('تم التوقيع', Colors.green),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(
              color: _isSigned ? Colors.green : Colors.grey,
              width: _isSigned ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Signature(
              controller: _signatureController,
              height: 180,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'قم بالتوقيع في المساحة أعلاه باستخدام إصبعك',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _clearSignature,
                icon: Icon(Icons.clear, size: 18),
                label: Text('مسح التوقيع'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveSignature,
                icon: Icon(Icons.save, size: 18),
                label: Text('حفظ التوقيع'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSigned ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        if (_signatureImage != null) ...[
          SizedBox(height: 16),
          Text(
            'التوقيع المحفوظ:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          SizedBox(height: 8),
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(_signatureImage!, fit: BoxFit.contain),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

//printing button widget
class SavePrintButton extends StatefulWidget {
  final VoidCallback onSave;
  final Map<String, dynamic> reportData;

  const SavePrintButton({required this.onSave, required this.reportData});

  @override
  _SavePrintButtonState createState() => _SavePrintButtonState();
}

class _SavePrintButtonState extends State<SavePrintButton> {
  bool _isLoading = false;
  pw.Font? _arabicFont;
  int _reportNumber = 1; // رقم التقرير
  int _invoiceNumber = 1001; // رقم الفاتورة

  final double baseFontSize = 20; // حجم خط كبير للطباعة

  @override
  void initState() {
    super.initState();
    _loadFont();
    // توليد أرقام عشوائية للتقرير والفاتورة
    _reportNumber = DateTime.now().millisecondsSinceEpoch % 10000;
    _invoiceNumber = DateTime.now().millisecondsSinceEpoch % 9000 + 1000;
  }

  Future<void> _loadFont() async {
    try {
      final fontData = await rootBundle.load('assets/fonts/Dubai-Regular.ttf');
      _arabicFont = pw.Font.ttf(fontData);
    } catch (e) {
      _arabicFont = pw.Font.helvetica();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _handleSaveAndPrint(),
        icon:
            _isLoading
                ? SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Icon(Icons.save_alt, size: 32),
        label: Text(
          _isLoading ? 'جاري المعالجة...' : 'حفظ وطباعة التقرير',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading ? Colors.grey : Colors.green,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 65),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
      ),
    );
  }

  Future<void> _handleSaveAndPrint() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // 🟢 إرسال التقرير واستقبال الرد
      final response = await MachineService.submitReport(
        maintenanceType: widget.reportData['maintenanceType'] ?? '',
        operationalStatus: widget.reportData['operationStatus'] ?? '',
        countingAccuracy: widget.reportData['countingAccuracy'] ?? '',
        technicianNotes: widget.reportData['notes'] ?? '',
        clientName: widget.reportData['clientName'] ?? '',
        clientPhone: widget.reportData['clientId'] ?? '',
        clientSignature: widget.reportData['signature'],

        selectedSensors:
            (widget.reportData['selectedSensors'] ?? [])
                .map<Map<String, dynamic>>(
                  (s) => {'sensor_name': s.toString(), 'status': 'يعمل الحساس'},
                )
                .toList(),

        completedWorks:
            (widget.reportData['completedWorks'] ?? [])
                .map<Map<String, dynamic>>(
                  (w) => {
                    'completed_work_id': 1,
                    'machine_id': 1,
                    'name': w.toString(),
                    'status': 'تم',
                  },
                )
                .toList(),

        safetyChecks:
            (widget.reportData['safetyChecks'] ?? [])
                .map<Map<String, dynamic>>(
                  (c) => {
                    'safety_check_id': 1,
                    'machine_id': 1,
                    'name': c.toString(),
                    'result': 'اجتاز',
                  },
                )
                .toList(),

        selectedSpareParts:
            (widget.reportData['selectedParts'] ?? [])
                .map<Map<String, dynamic>>((p) {
                  final txt = p.toString();
                  final name =
                      txt.contains('(') ? txt.split('(').first.trim() : txt;
                  final pn =
                      txt.contains('(')
                          ? txt
                              .substring(txt.indexOf('(') + 1, txt.indexOf(')'))
                              .trim()
                          : '';
                  return {'part_name': name, 'part_number': pn, 'quantity': 1};
                })
                .toList(),
      );

      // ✅ استخراج البيانات
      final data = (response['data'] ?? {}) as Map<String, dynamic>;
      final warranty = (data['WARRANTY_STATUS'] ?? {}) as Map<String, dynamic>;
      final deviceHealth =
          (data['DEVICE_HEALTH'] ?? {}) as Map<String, dynamic>;
      final workDetails = (data['WORK_DETAILS'] ?? {}) as Map<String, dynamic>;
      final client = (data['CLIENT_INFO'] ?? {}) as Map<String, dynamic>;
      final invoice = (data['INVOICE'] ?? {}) as Map<String, dynamic>;

      final sensors = List<Map<String, dynamic>>.from(
        (deviceHealth['checked_sensors'] ?? []),
      );
      final parts = List<Map<String, dynamic>>.from(
        (workDetails['parts_used_per_machine'] ?? []),
      );
      final items = List<Map<String, dynamic>>.from((invoice['items'] ?? []));

      // 🧾 تحميل الخط العربي
      final fontData = await rootBundle.load('assets/fonts/Dubai-Regular.ttf');
      final arabicFont = pw.Font.ttf(fontData);

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(24),
          build:
              (context) => [
                pw.Center(
                  child: pw.Text(
                    'تقرير الصيانة الفني مع الفاتورة',
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // 🟢 رقم التقرير
                _buildSectionTitle('رقم التقرير', arabicFont),
                _buildKeyValue(
                  'رقم التقرير',
                  data['REPORT_ID']?.toString() ?? '',
                  arabicFont,
                ),

                pw.SizedBox(height: 15),

                // 🟩 حالة الكفالة
                _buildSectionTitle('حالة الكفالة', arabicFont),
                _buildKeyValue(
                  'نوع الكفالة',
                  warranty['warranty_name'] ?? 'غير محدد',
                  arabicFont,
                ),
                _buildKeyValue(
                  'الحالة',
                  (warranty['is_warranted'] == true)
                      ? 'سارية المفعول ✅'
                      : 'منتهية ❌',
                  arabicFont,
                ),
                _buildKeyValue(
                  'تاريخ البداية',
                  warranty['start_date']?.toString()?.split('T')?.first ?? '',
                  arabicFont,
                ),
                _buildKeyValue(
                  'تاريخ الانتهاء',
                  warranty['end_date']?.toString()?.split('T')?.first ?? '',
                  arabicFont,
                ),

                pw.SizedBox(height: 15),

                // 🟦 معلومات الجهاز
                _buildSectionTitle('معلومات الجهاز', arabicFont),
                _buildKeyValue(
                  'الرقم التسلسلي',
                  (data['MACHINE_INFO'] ?? {})['serial_number'] ?? '',
                  arabicFont,
                ),
                _buildKeyValue(
                  'الموديل',
                  (data['MACHINE_INFO'] ?? {})['model'] ?? '',
                  arabicFont,
                ),
                _buildKeyValue(
                  'الموقع',
                  (data['MACHINE_INFO'] ?? {})['location'] ?? '',
                  arabicFont,
                ),
                _buildKeyValue(
                  'نوع الصيانة',
                  (data['MACHINE_INFO'] ?? {})['maintenance_type'] ?? '',
                  arabicFont,
                ),

                pw.SizedBox(height: 15),

                // 🟨 حالة الجهاز
                _buildSectionTitle('حالة الجهاز', arabicFont),
                _buildKeyValue(
                  'الحالة التشغيلية',
                  (deviceHealth['operational_status'] ?? ''),
                  arabicFont,
                ),
                _buildKeyValue(
                  'دقة العد',
                  (deviceHealth['counting_accuracy'] ?? ''),
                  arabicFont,
                ),

                if (sensors.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  _buildKeyValue('الحساسات:', '', arabicFont),
                  ...sensors.map(
                    (sensor) => _buildKeyValue(
                      '• ${sensor['sensor_name']}',
                      sensor['status'] ?? '',
                      arabicFont,
                    ),
                  ),
                ],

                pw.SizedBox(height: 15),

                // 🟧 تفاصيل العمل
                _buildSectionTitle('تفاصيل العمل', arabicFont),
                _buildKeyValue(
                  'نوع المشكلة',
                  (workDetails['problem_type'] ?? ''),
                  arabicFont,
                ),
                _buildKeyValue(
                  'ملاحظات الفني',
                  (workDetails['technician_notes'] ?? ''),
                  arabicFont,
                ),

                _buildSubList(
                  'الأعمال المنجزة',
                  (workDetails['completed_works'] ?? []) as List,
                  'name',
                  'status',
                  arabicFont,
                ),
                _buildSubList(
                  'فحوصات السلامة',
                  (workDetails['safety_checks'] ?? []) as List,
                  'name',
                  'result',
                  arabicFont,
                ),
                _buildSubList(
                  'قطع الغيار المستخدمة',
                  parts,
                  'part_name',
                  'quantity',
                  arabicFont,
                ),

                pw.SizedBox(height: 20),

                // 🧾 بيانات الفاتورة الكاملة
                _buildSectionTitle('بيانات الفاتورة', arabicFont),
                _buildKeyValue(
                  'رقم الفاتورة',
                  invoice['invoice_id']?.toString() ?? '',
                  arabicFont,
                ),
                _buildKeyValue(
                  'حالة الفاتورة',
                  invoice['status'] ?? '',
                  arabicFont,
                ),
                _buildKeyValue(
                  'إجمالي المبلغ قبل الخصم',
                  invoice['final_amount_before_discount']?.toString() ?? '',
                  arabicFont,
                ),
                _buildKeyValue(
                  'نسبة الخصم (%)',
                  invoice['final_discount_percentage']?.toString() ?? '',
                  arabicFont,
                ),
                _buildKeyValue(
                  'قيمة الخصم الفعلية',
                  invoice['final_discount_value']?.toString() ?? '',
                  arabicFont,
                ),
                _buildKeyValue(
                  'قيمة الخصم العامة',
                  invoice['discount_amount']?.toString() ?? '',
                  arabicFont,
                ),
                _buildKeyValue(
                  'إجمالي المبلغ بعد الخصم',
                  invoice['final_amount_due']?.toString() ?? '',
                  arabicFont,
                ),
                _buildKeyValue(
                  'إجمالي الضرائب',
                  invoice['tax_amount']?.toString() ?? '',
                  arabicFont,
                ),
                _buildKeyValue(
                  'إجمالي المبلغ الكلي (مع الضرائب)',
                  invoice['total_amount']?.toString() ?? '',
                  arabicFont,
                ),
                _buildKeyValue(
                  'العملة',
                  invoice['currency_id']?.toString() ?? '',
                  arabicFont,
                ),

                pw.SizedBox(height: 15),

                // 🧾 جدول بنود الفاتورة
                if (items.isNotEmpty) ...[
                  _buildSectionTitle('تفاصيل بنود الفاتورة', arabicFont),
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey300,
                      width: 0.8,
                    ),
                    columnWidths: {
                      0: pw.FlexColumnWidth(3),
                      1: pw.FlexColumnWidth(1),
                      2: pw.FlexColumnWidth(1),
                      3: pw.FlexColumnWidth(1),
                      4: pw.FlexColumnWidth(2),
                      5: pw.FlexColumnWidth(2),
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.blue50),
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'الوصف',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: arabicFont,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'الكمية',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: arabicFont,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'السعر',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: arabicFont,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'الإجمالي',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: arabicFont,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'تاريخ الإنشاء',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: arabicFont,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'تاريخ التحديث',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: arabicFont,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...items.map(
                        (item) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: pw.EdgeInsets.all(6),
                              child: pw.Text(
                                item['description'] ?? '',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(font: arabicFont),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(6),
                              child: pw.Text(
                                item['quantity']?.toString() ?? '',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(font: arabicFont),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(6),
                              child: pw.Text(
                                item['unit_price']?.toString() ?? '',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(font: arabicFont),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(6),
                              child: pw.Text(
                                item['line_total']?.toString() ?? '',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(font: arabicFont),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(6),
                              child: pw.Text(
                                item['created_at']
                                        ?.toString()
                                        ?.split('T')
                                        ?.first ??
                                    '-',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  font: arabicFont,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(6),
                              child: pw.Text(
                                item['updated_at']
                                        ?.toString()
                                        ?.split('T')
                                        ?.first ??
                                    '-',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  font: arabicFont,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
        ),
      );

      // ✅ عرض PDF
      await Printing.layoutPdf(
        onLayout: (format) async => await pdf.save(),
        name: 'تقرير_صيانة_${data['REPORT_ID']}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم إنشاء التقرير ويمكنك الآن طباعته'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ خطأ أثناء إنشاء PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ فشل في إنشاء التقرير: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ----------------------------------------------------
  // 🔹 Widgets مساعدة لتنسيق التقرير
  // ----------------------------------------------------
  pw.Widget _buildSectionTitle(String title, pw.Font font) {
    return pw.Container(
      width: double.infinity,
      color: PdfColors.blue50,
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: font,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
    );
  }

  pw.Widget _buildKeyValue(String key, String? value, pw.Font font) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(value ?? '', style: pw.TextStyle(font: font, fontSize: 12)),
          pw.Text(
            key,
            style: pw.TextStyle(
              font: font,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSubList(
    String title,
    List list,
    String key,
    String valueKey,
    pw.Font font,
  ) {
    if (list.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            font: font,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
            fontSize: 13,
          ),
        ),
        pw.SizedBox(height: 4),
        ...list.map((item) {
          return pw.Padding(
            padding: pw.EdgeInsets.only(right: 10, bottom: 2),
            child: pw.Text(
              '• ${item[key]} — ${item[valueKey]}',
              style: pw.TextStyle(font: font, fontSize: 11),
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _showPrintOptions() async {
    if (!mounted) return;
    final result = await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'خيارات الطباعة',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 15),
                ListTile(
                  leading: Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red,
                    size: 36,
                  ),
                  title: Text('تصدير كملف PDF', style: TextStyle(fontSize: 28)),
                  onTap: () => Navigator.pop(context, 'pdf'),
                ),
                ListTile(
                  leading: Icon(Icons.print, color: Colors.green, size: 36),
                  title: Text('طباعة مباشرة', style: TextStyle(fontSize: 28)),
                  onTap: () => Navigator.pop(context, 'print'),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'cancel'),
                  child: Text('إلغاء', style: TextStyle(fontSize: 26)),
                ),
              ],
            ),
          ),
    );
    if (!mounted) return;
    switch (result) {
      case 'pdf':
        await _generatePdf();
        break;
      case 'print':
        await _printDirectly();
        break;
    }
  }

  Future<void> _generatePdf() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          margin: pw.EdgeInsets.all(25),
          header: (context) => _buildHeader(context),
          footer: (context) => _buildFooter(context),
          build: (context) => _buildPdfContent(),
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'تقرير_صيانة_${_reportNumber}.pdf',
      );
      _showMessage('تم تصدير التقرير كملف PDF بنجاح', Colors.green);
    } catch (e) {
      _showMessage('حدث خطأ في إنشاء PDF: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _printDirectly() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          margin: pw.EdgeInsets.all(25),
          header: (context) => _buildHeader(context),
          footer: (context) => _buildFooter(context),
          build: (context) => _buildPdfContent(),
        ),
      );

      final bytes = await pdf.save();
      await Printing.layoutPdf(onLayout: (format) async => bytes);
      _showMessage('تم إرسال التقرير للطباعة بنجاح', Colors.green);
    } catch (e) {
      _showMessage('حدث خطأ في الطباعة: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  pw.Widget _buildHeader(pw.Context context) {
    final font = _arabicFont ?? pw.Font.helvetica();
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 15),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'شركة التقنية المتطورة - تقرير صيانة',
            style: pw.TextStyle(
              fontSize: baseFontSize - 10,
              color: PdfColors.grey600,
              font: font,
            ),
          ),
          pw.Text(
            'رقم التقرير: #$_reportNumber',
            style: pw.TextStyle(
              fontSize: baseFontSize - 10,
              color: PdfColors.grey600,
              font: font,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    final font = _arabicFont ?? pw.Font.helvetica();
    return pw.Container(
      margin: pw.EdgeInsets.only(top: 15),
      child: pw.Center(
        child: pw.Text(
          'صفحة ${context.pageNumber} من ${context.pagesCount}',
          style: pw.TextStyle(
            fontSize: baseFontSize - 12,
            color: PdfColors.grey600,
            font: font,
          ),
        ),
      ),
    );
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 26)),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  List<pw.Widget> _buildPdfContent() {
    final font = _arabicFont ?? pw.Font.helvetica();
    return [
      _buildPdfHeader(font),
      _buildWarrantySection(font),
      _buildDeviceInfoSection(font),
      _buildMaintenanceTypeSection(font),
      _buildDeviceStatusSection(font),
      _buildCompletedWorksSection(font),
      _buildFaultTypeSection(font),
      _buildSparePartsSection(font),
      _buildSafetyChecksSection(font),
      _buildNotesSection(font),
      _buildClientInfoSection(font),
      _buildPostsSignatureSection(font),
    ];
  }

  // ---------- جميع الـ Sections مع خط كبير ----------

  pw.Widget _buildPdfHeader(pw.Font font) => pw.Column(
    children: [
      pw.Center(
        child: pw.Text(
          'تقرير صيانة آلات عد النقود',
          style: pw.TextStyle(
            fontSize: baseFontSize + 10,
            fontWeight: pw.FontWeight.bold,
            font: font,
          ),
        ),
      ),
      pw.SizedBox(height: 15),
      pw.Center(
        child: pw.Text(
          'إدارة الشؤون الفنية / قسم الصيانة',
          style: pw.TextStyle(
            fontSize: baseFontSize + 6,
            color: PdfColors.grey600,
            font: font,
          ),
        ),
      ),
      pw.Divider(thickness: 3),
      pw.SizedBox(height: 20),
    ],
  );

  pw.Widget _buildWarrantySection(
    pw.Font font,
  ) => _buildPdfSection('حالة الكفالة', [
    'الحالة: ${_getText(widget.reportData['warrantyStatus'] ?? '', _warrantyStatusMap)}',
    if ((widget.reportData['warrantyStatus'] ?? '') == 'expired') ...[
      'أجرة الصيانة: 50,000 ل.س',
      'أجرة المواصلات: ${(widget.reportData['transportationFee'] ?? 0).toStringAsFixed(0)} ل.س',
      'طريقة الدفع: ${_getText(widget.reportData['paymentMethod'] ?? '', _paymentMethodMap)}',
      if ((widget.reportData['paymentMethod'] ?? '') == 'bank')
        'البنك: ${_getText(widget.reportData['selectedBank'] ?? '', _bankMap)}',
    ],
  ], font);

  pw.Widget _buildDeviceInfoSection(pw.Font font) =>
      _buildPdfSection('معلومات الجهاز', [
        'معرف الجهاز: ${widget.reportData['deviceId'] ?? 'غير محدد'}',
        'الموقع: ${widget.reportData['location'] ?? 'غير محدد'}',
        'الطراز: ${widget.reportData['model'] ?? 'غير محدد'}',
      ], font);

  pw.Widget _buildMaintenanceTypeSection(pw.Font font) => _buildPdfSection(
    'نوع الصيانة',
    [_getText(widget.reportData['maintenanceType'] ?? '', _maintenanceTypeMap)],
    font,
  );

  pw.Widget _buildDeviceStatusSection(pw.Font font) =>
      _buildPdfSection('حالة الجهاز', [
        'حالة التشغيل: ${widget.reportData['operationStatus'] ?? 'غير محدد'}',
        'دقة العد: ${widget.reportData['countingAccuracy'] ?? 'غير محدد'}',
        'الحساسات: ${_listToText(widget.reportData['selectedSensors'] ?? [])}',
      ], font);

  pw.Widget _buildCompletedWorksSection(pw.Font font) => _buildListSection(
    'الأعمال المنجزة',
    widget.reportData['completedWorks'] ?? [],
    font,
  );

  pw.Widget _buildFaultTypeSection(pw.Font font) => _buildListSection(
    'نوع العطل',
    widget.reportData['faultTypes'] ?? [],
    font,
  );

  pw.Widget _buildSafetyChecksSection(pw.Font font) => _buildListSection(
    'فحوصات السلامة',
    widget.reportData['safetyChecks'] ?? [],
    font,
  );

  pw.Widget _buildSparePartsSection(pw.Font font) {
    final parts = widget.reportData['selectedParts'] ?? [];
    return _buildPdfSection('طلب قطع الغيار', [
      'طلب قطع غيار: ${(widget.reportData['sparePartsRequested'] ?? false) ? 'نعم' : 'لا'}',
      if (parts.isNotEmpty) ...['القطع المطلوبة:'] + parts,
    ], font);
  }

  pw.Widget _buildNotesSection(pw.Font font) {
    final notes = widget.reportData['notes'] ?? '';
    return notes.isEmpty
        ? pw.SizedBox.shrink()
        : _buildPdfSection('ملاحظات إضافية', [notes], font);
  }

  pw.Widget _buildClientInfoSection(pw.Font font) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      _buildPdfSection('معلومات العميل', [
        'اسم العميل: ${widget.reportData['clientName'] ?? 'غير محدد'}',
        'رقم العميل: ${widget.reportData['clientId'] ?? 'غير محدد'}',
      ], font),
      pw.SizedBox(height: 20),
      pw.Text(
        'توقيع العميل:',
        style: pw.TextStyle(
          fontSize: baseFontSize + 6,
          fontWeight: pw.FontWeight.bold,
          font: font,
        ),
      ),
      pw.SizedBox(height: 10),
      if (widget.reportData['signature'] != null)
        pw.Container(
          height: 180,
          width: 400,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
          ),
          child: pw.Image(
            pw.MemoryImage(widget.reportData['signature']!),
            fit: pw.BoxFit.contain,
          ),
        )
      else
        pw.Container(
          height: 100,
          width: 300,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
          ),
          child: pw.Center(
            child: pw.Text(
              'لم يتم التوقيع',
              style: pw.TextStyle(
                color: PdfColors.grey,
                font: font,
                fontSize: baseFontSize,
              ),
            ),
          ),
        ),
      pw.Divider(thickness: 3),
      pw.SizedBox(height: 25),
    ],
  );

  // القسم الجديد بعد التوقيع - سجل الصيانة والتكاليف
  pw.Widget _buildPostsSignatureSection(pw.Font font) {
    final bool isWarrantyExpired =
        (widget.reportData['warrantyStatus'] ?? '') == 'expired';

    return pw.Container(
      margin: pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // سجل الصيانة
          _buildPdfSection('سجل الصيانة', [
            'الرقم التسلسلي: PROSCAN-6P-001247',
            'الموقع: فرع الرياض الرئيسي',
            'التاريخ: 2025-10-01',
            'نوع العطل: ميكانيكي',
            'الإجراء المتخذ: تنظيف الحساسات، فحص الأحزمة',
          ], font),

          // التكاليف والأتعاب - تظهر فقط إذا كانت الكفالة منتهية
          if (isWarrantyExpired) ...[
            _buildPdfSection('التكاليف والأتعاب', [
              'أجرة الصيانة: 50,000 ل.س',
              'أجرة المواصلات: 10,000 ل.س',
              'حساس بصري (OS-2024-A): 25,000 ل.س',
              'أسطوانة التغذية (FR-2024-B): 40,000 ل.س',
              'المبلغ الإجمالي: 125,000 ل.س',
            ], font),

            // رقم الفاتورة - يظهر فقط إذا كانت الكفالة منتهية
            pw.Container(
              width: double.infinity,
              margin: pw.EdgeInsets.only(bottom: 20),
              padding: pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue, width: 2),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Center(
                child: pw.Text(
                  'رقم الفاتورة: #$_invoiceNumber',
                  style: pw.TextStyle(
                    fontSize: baseFontSize + 4,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                    font: font,
                  ),
                ),
              ),
            ),
          ],

          // طريقة الدفع
          _buildPdfSection('طريقة الدفع', ['طريقة الدفع: كاش'], font),

          // مقاييس الأداء
          _buildPdfSection('مقاييس الأداء', [
            'نسبة توفر الأجهزة: 98%',
            'زمن الاستجابة للصيانة الطارئة: 2 ساعة',
            'متوسط الأعطال الشهري: 1 عطل',
          ], font),

          // رسالة الشكر والمعلومات المرجعية
          pw.Container(
            width: double.infinity,
            margin: pw.EdgeInsets.only(top: 25),
            padding: pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey, width: 1),
              color: PdfColors.grey100,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'شكرا لتعاونكم',
                  style: pw.TextStyle(
                    fontSize: baseFontSize + 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                    font: font,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'هذا التقرير تم إنشاؤه تلقائيا بواسطة نظام إدارة الصيانة',
                  style: pw.TextStyle(
                    fontSize: baseFontSize + 2,
                    color: PdfColors.grey600,
                    font: font,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'رقم المرجع: 1247-20251001-MNT',
                  style: pw.TextStyle(
                    fontSize: baseFontSize + 2,
                    color: PdfColors.grey600,
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSection(String title, List<String> content, pw.Font font) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue100, width: 2),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: baseFontSize + 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
                font: font,
              ),
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children:
                  content
                      .map(
                        (item) => pw.Padding(
                          padding: pw.EdgeInsets.symmetric(vertical: 8),
                          child: pw.Text(
                            item,
                            style: pw.TextStyle(
                              fontSize: baseFontSize,
                              font: font,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildListSection(String title, List items, pw.Font font) =>
      items.isEmpty
          ? pw.SizedBox.shrink()
          : _buildPdfSection(
            title,
            items.map((i) => i.toString()).toList(),
            font,
          );

  String _getText(String key, Map<String, String> map) => map[key] ?? key;
  String _listToText(List list) => list.isEmpty ? 'لا توجد' : list.join('، ');

  final Map<String, String> _warrantyStatusMap = {
    'active': 'شاملة للكفالة',
    'expired': 'منتهية الكفالة',
  };
  final Map<String, String> _maintenanceTypeMap = {
    'operational': 'تشغيلية',
    'preventive': 'وقائية',
    'urgent': 'عاجلة',
    'corrective': 'تصحيحية',
    'developmental': 'تطويرية',
  };
  final Map<String, String> _paymentMethodMap = {
    'cash': 'كاش',
    'bank': 'تحويل بنكي',
  };
  final Map<String, String> _bankMap = {
    'bemo': 'بنك بيمو السعودي الفرنسي',
    'byblos': 'بنك بيبلوس',
    'audi': 'بنك عودة',
    'blom': 'بنك بلوم',
    'fransi': 'بنك الفرانسي',
  };
}
