import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/screens/pages/expenses/expenses_service.dart';
import 'dart:io';

class AddExpenseTab extends StatefulWidget {
  @override
  _AddExpenseTabState createState() => _AddExpenseTabState();
}

class _AddExpenseTabState extends State<AddExpenseTab> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // القيم المختارة
  Map<String, dynamic>? _selectedTask;
  Map<String, dynamic>? _selectedExpenseType;
  Map<String, dynamic>? _selectedCurrency;
  double _amount = 0.0;
  DateTime _expenseDate = DateTime.now();
  String _description = '';
  File? _receiptImage;

  // القوائم
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _expenseTypes = [];
  List<Map<String, dynamic>> _currencies = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    try {
      final tasks = await ApiService.getTasks();
      final expenseTypes = await ApiService.getExpenseTypes();
      final currencies = await ApiService.getCurrencies();

      setState(() {
        _tasks = tasks;
        _expenseTypes = expenseTypes;
        _currencies = currencies;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnackBar('فشل في جلب البيانات: $e');
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.05),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
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
                          context,
                          icon: Icons.camera_alt,
                          label: 'الكاميرا',
                          color: Colors.orangeAccent,
                          source: ImageSource.camera,
                        ),
                        _buildImageOption(
                          context,
                          icon: Icons.photo_library,
                          label: 'المعرض',
                          color: Colors.teal,
                          source: ImageSource.gallery,
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
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _receiptImage = File(image.path));
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء اختيار الصورة: $e');
    }
  }

  Widget _buildImageOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required ImageSource source,
  }) {
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

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _selectedTask = null;
      _selectedExpenseType = null;
      _selectedCurrency = null;
      _amount = 0.0;
      _expenseDate = DateTime.now();
      _description = '';
      _receiptImage = null;
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await ApiService.addExpense(
          taskId: _selectedTask!['task_id'],
          expenseTypeId: _selectedExpenseType!['expense_type_id'],
          currencyId: _selectedCurrency!['currency_id'],
          amount: _amount,
          expenseDate:
              '${_expenseDate.year}-${_expenseDate.month.toString().padLeft(2, '0')}-${_expenseDate.day.toString().padLeft(2, '0')}',
          description: _description,
          receiptImage: _receiptImage, // ✅ الآن نرسل الصورة الفعلية
        );

        _showSuccessDialog();
      } catch (e) {
        _showSnackBar('فشل في إضافة المصروف: $e');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text('تمت الإضافة بنجاح'),
              ],
            ),
            content: Text(
              'تم إضافة المصروف بنجاح وسيتم مراجعته من قبل المدير.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetForm();
                },
                child: Text('موافق'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildInfoCard(),
            SizedBox(height: 20),
            _buildDropdownField(
              label: 'المهمة',
              value: _selectedTask,
              items: _tasks,
              onChanged: (v) => setState(() => _selectedTask = v),
              validator: (v) => v == null ? 'يرجى اختيار المهمة' : null,
              icon: Icons.assignment,
              valueKey: 'task_id',
              labelKey: 'display_text', // 👈 صار يقرأ النص الجديد
            ),

            SizedBox(height: 15),
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
            SizedBox(height: 15),
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
                SizedBox(width: 15),
                Expanded(flex: 3, child: _buildAmountField()),
              ],
            ),
            SizedBox(height: 15),
            _buildDateField(),
            SizedBox(height: 15),
            _buildDescriptionField(),
            SizedBox(height: 15),
            _buildImageUploadSection(),
            SizedBox(height: 25),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() => Card(
    color: AppColors.secondary,
    elevation: 2,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.info, color: AppColors.secondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'جميع المصاريف تخضع للمراجعة والموافقة من قبل المدير المختص',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildDropdownField({
    required String label,
    required Map<String, dynamic>? value,
    required List<Map<String, dynamic>> items,
    required Function(Map<String, dynamic>?) onChanged,
    required String? Function(Map<String, dynamic>?) validator,
    required IconData icon,
    required String valueKey,
    required String labelKey,
  }) => DropdownButtonFormField<Map<String, dynamic>>(
    value: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.secondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    items:
        items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e[labelKey],
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            )
            .toList(),
    onChanged: onChanged,
    validator: validator,
  );

  Widget _buildAmountField() => TextFormField(
    keyboardType: TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: 'المبلغ',
      prefixIcon: Icon(Icons.attach_money, color: AppColors.secondary),
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
        prefixIcon: Icon(Icons.calendar_today, color: AppColors.secondary),
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
          Icon(Icons.arrow_drop_down, color: Colors.grey),
        ],
      ),
    ),
  );

  Widget _buildDescriptionField() => TextFormField(
    maxLines: 3,
    decoration: InputDecoration(
      labelText: 'وصف المصروف (اختياري)',
      prefixIcon: Icon(Icons.description, color: AppColors.secondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    ),
    onSaved: (v) => _description = v ?? '',
  );

  Widget _buildImageUploadSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('صورة الإيصال (اختياري)', style: TextStyle(color: Colors.grey[700])),
      SizedBox(height: 8),
      Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
        ),
        child: Center(
          child:
              _receiptImage == null
                  ? IconButton(
                    icon: Icon(Icons.camera_alt, color: AppColors.secondary),
                    onPressed: _pickImage,
                  )
                  : Stack(
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
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => _receiptImage = null),
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    ],
  );

  Widget _buildActionButtons() => Row(
    children: [
      Expanded(
        child: ElevatedButton(
          onPressed: _submitForm,

          child: Text('إضافة المصروف'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      SizedBox(width: 10),
      Expanded(
        child: OutlinedButton(
          onPressed: _resetForm,
          child: Text('إعادة ضبط'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.secondary),
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ],
  );
}
