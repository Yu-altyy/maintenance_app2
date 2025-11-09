import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/screens/pages/expenses/update_expense_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditExpenseTab extends StatefulWidget {
  const EditExpenseTab({Key? key}) : super(key: key);

  @override
  State<EditExpenseTab> createState() => _EditExpenseTabState();
}

class _EditExpenseTabState extends State<EditExpenseTab> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _selectedTask;
  Map<String, dynamic>? _selectedExpenseType;
  Map<String, dynamic>? _selectedCurrency;
  double _amount = 0.0;
  DateTime _expenseDate = DateTime.now();
  String _description = '';
  File? _receiptImage;
  String? _currentImageUrl;

  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _expenseTypes = [];
  List<Map<String, dynamic>> _currencies = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final tasks = await UpdateExpenseService.getTasks();
      final expenseTypes = await UpdateExpenseService.getExpenseTypes();
      final currencies = await UpdateExpenseService.getCurrencies();
      final expenseData = await UpdateExpenseService.getExpenseDetails();

      setState(() {
        _tasks = tasks;
        _expenseTypes = expenseTypes;
        _currencies = currencies;

        // تعبئة البيانات
        _amount = double.tryParse(expenseData['amount'].toString()) ?? 0.0;
        _description = expenseData['description'] ?? '';
        _expenseDate = DateTime.parse(expenseData['expense_date']);
        final imagePath = expenseData['receipt_image_url'] ?? '';

        if (imagePath.isNotEmpty) {
          _currentImageUrl =
              imagePath.startsWith('http')
                  ? imagePath
                  : '${AppConfig.ip}$imagePath';
        } else {
          _currentImageUrl = null;
        }

        _selectedTask = tasks.firstWhere(
          (t) => t['task_id'] == (expenseData['task']?['task_id'] ?? 0),
          orElse: () => {},
        );
        _selectedExpenseType = expenseTypes.firstWhere(
          (t) => t['expense_type_name'] == expenseData['expense_type'],
          orElse: () => {},
        );
        _selectedCurrency = currencies.firstWhere(
          (c) =>
              c['currency_name'] == expenseData['currency']?['currency_name'],
          orElse: () => {},
        );

        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnackBar('فشل في جلب بيانات المصروف: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder:
            (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.image,
                      size: 50,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'اختر مصدر الصورة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildImageOption(
                          Icons.camera_alt,
                          'الكاميرا',
                          Colors.orangeAccent,
                          ImageSource.camera,
                        ),
                        _buildImageOption(
                          Icons.photo_library,
                          'المعرض',
                          Colors.teal,
                          ImageSource.gallery,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _receiptImage = File(image.path);
          _currentImageUrl = null;
        });
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء اختيار الصورة: $e');
    }
  }

  Widget _buildImageOption(
    IconData icon,
    String label,
    Color color,
    ImageSource source,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(context, source),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.secondary),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _expenseDate) {
      setState(() => _expenseDate = picked);
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final prefs = await SharedPreferences.getInstance();
        final expenseId = prefs.getInt('selectedExpenseId');
        if (expenseId == null) throw Exception('لم يتم العثور على رقم ');

        await UpdateExpenseService.updateExpense(
          expenseId: expenseId,
          taskId: _selectedTask?['task_id'],
          expenseTypeId: _selectedExpenseType?['expense_type_id'],
          currencyId: _selectedCurrency?['currency_id'],
          amount: _amount,
          expenseDate:
              '${_expenseDate.year}-${_expenseDate.month.toString().padLeft(2, '0')}-${_expenseDate.day.toString().padLeft(2, '0')}',
          description: _description,
          receiptImage: _receiptImage,
        );

        _showSnackBar('تم تحديث المصروف بنجاح ✅');
      } catch (e) {
        _showSnackBar('فشل في تحديث المصروف: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        title: const Text('تعديل المصروف'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildDropdownField(
                label: 'المهمة',
                value: _selectedTask,
                items: _tasks,
                onChanged: (v) => setState(() => _selectedTask = v),
                validator: (v) => v == null ? 'يرجى اختيار المهمة' : null,
                icon: Icons.assignment,
                valueKey: 'task_id',
                labelKey: 'display_text',
              ),
              const SizedBox(height: 15),
              _buildDropdownField(
                label: 'نوع المصروف',
                value: _selectedExpenseType,
                items: _expenseTypes,
                onChanged: (v) => setState(() => _selectedExpenseType = v),
                validator: (v) => v == null ? 'يرجى اختيار نوع المصروف' : null,
                icon: Icons.category,
                valueKey: 'expense_type_id',
                labelKey: 'expense_type_name',
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildDropdownField(
                      label: 'العملة',
                      value: _selectedCurrency,
                      items: _currencies,
                      onChanged: (v) => setState(() => _selectedCurrency = v),
                      validator: (v) => v == null ? 'يرجى اختيار العملة' : null,
                      icon: Icons.currency_exchange,
                      valueKey: 'currency_id',
                      labelKey: 'currency_name',
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(flex: 3, child: _buildAmountField()),
                ],
              ),
              const SizedBox(height: 15),
              _buildDateField(),
              const SizedBox(height: 15),
              _buildDescriptionField(),
              const SizedBox(height: 15),
              _buildImageUploadSection(),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'تحديث المصروف',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required Map<String, dynamic>? value,
    required List<Map<String, dynamic>> items,
    required Function(Map<String, dynamic>?) onChanged,
    required String? Function(Map<String, dynamic>?) validator,
    required IconData icon,
    required String valueKey,
    required String labelKey,
  }) {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.secondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items:
          items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e[labelKey], overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildAmountField() => TextFormField(
    initialValue: _amount.toString(),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: 'المبلغ',
      prefixIcon: const Icon(Icons.attach_money, color: AppColors.secondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    ),
    validator:
        (v) =>
            v == null || v.isEmpty
                ? 'يرجى إدخال المبلغ'
                : double.tryParse(v) == null
                ? 'يرجى إدخال مبلغ صحيح'
                : null,
    onSaved: (v) => _amount = double.parse(v!),
  );

  Widget _buildDateField() => InkWell(
    onTap: () => _selectDate(context),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'تاريخ المصروف',
        prefixIcon: const Icon(
          Icons.calendar_today,
          color: AppColors.secondary,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_expenseDate.year}-${_expenseDate.month.toString().padLeft(2, '0')}-${_expenseDate.day.toString().padLeft(2, '0')}',
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ],
      ),
    ),
  );

  Widget _buildDescriptionField() => TextFormField(
    initialValue: _description,
    maxLines: 3,
    decoration: InputDecoration(
      labelText: 'وصف المصروف (اختياري)',
      prefixIcon: const Icon(Icons.description, color: AppColors.secondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    ),
    onSaved: (v) => _description = v ?? '',
  );

  Widget _buildImageUploadSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'صورة الإيصال (اختياري)',
        style: TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 8),
      Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
        ),
        child: Center(
          child:
              _receiptImage != null
                  ? Stack(
                    children: [
                      Image.file(
                        _receiptImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => _receiptImage = null),
                        ),
                      ),
                    ],
                  )
                  : _currentImageUrl != null
                  ? Stack(
                    children: [
                      Image.network(
                        _currentImageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed:
                              () => setState(() => _currentImageUrl = null),
                        ),
                      ),
                    ],
                  )
                  : IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: AppColors.secondary,
                    ),
                    onPressed: _pickImage,
                  ),
        ),
      ),
    ],
  );
}
