import 'package:flutter/material.dart';
import 'package:mentenance_app/screens/admin_flow/pages/add_task/api_service.dart';
import 'package:mentenance_app/screens/admin_flow/pages/edit_task/edit_task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditTask extends StatefulWidget {
  const EditTask({super.key});

  @override
  State<EditTask> createState() => _EditMainTaskPageState();
}

class _EditMainTaskPageState extends State<EditTask> {
  List<Map<String, dynamic>> technicians = [];
  List<Map<String, dynamic>> machines = [];

  String? selectedMachineId;
  String? selectedTechnicianId;
  String? scheduledDate;

  final TextEditingController problemTypeController = TextEditingController();
  final TextEditingController reportedProblemController =
      TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// 🔹 تحميل بيانات القوائم وبيانات المهمة معًا
  Future<void> _initializeData() async {
    await _loadDropdownData();
    await _loadTaskData();
    setState(() => _isLoading = false);
  }

  /// 🟢 تحميل بيانات الـ dropdowns
  Future<void> _loadDropdownData() async {
    final techs = await ApiService.getTechnicians();
    final machs = await ApiService.getMachines();
    setState(() {
      technicians = techs;
      machines = machs;
    });
  }

  /// 🟢 تحميل بيانات المهمة حسب الـ ID في SharedPreferences
  Future<void> _loadTaskData() async {
    final data = await EditTaskService.fetchTaskData();
    if (data != null) {
      setState(() {
        // تعبئة البيانات القادمة من الـ API
        selectedTechnicianId = data['technician_id']?.toString();
        problemTypeController.text = data['problem_type'] ?? '';
        reportedProblemController.text = data['reported_problem'] ?? '';
        priorityController.text = data['priority'] ?? '';
        scheduledDate = data['scheduled_date']?.split(' ')?.first ?? '';

        // ⚙️ محاولة ربط الجهاز حسب الرقم التسلسلي
        final machine = machines.firstWhere(
          (m) => m['machine_serial_number'] == data['machine_serial_number'],
          orElse: () => {},
        );
        if (machine.isNotEmpty) {
          selectedMachineId = machine['machine_id'].toString();
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      initialDate: now,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E9E8E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        scheduledDate =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  InputDecoration _decor(String label, {IconData? icon}) => InputDecoration(
    labelText: label,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.teal, width: 1.4),
    ),
  );

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: const [
      BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 6)),
    ],
  );

  String _machineLabel(Map<String, dynamic> m) {
    final serial = (m['machine_serial_number'] ?? '').toString();
    final type = (m['machine_type_name'] ?? '').toString();
    return '$serial - $type';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Main Task"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Container(
                  decoration: _cardDecoration,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 🟢 Machine Dropdown
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: _decor(
                            "Machine",
                            icon: Icons.precision_manufacturing,
                          ),
                          value: selectedMachineId,
                          hint: const Text("Select a machine"),
                          items:
                              machines.map((m) {
                                final id = m['machine_id'].toString();
                                return DropdownMenuItem<String>(
                                  value: id,
                                  child: Text(_machineLabel(m)),
                                );
                              }).toList(),
                          onChanged:
                              (v) => setState(() => selectedMachineId = v),
                        ),
                        const SizedBox(height: 12),

                        // 🟢 Technician Dropdown
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: _decor(
                            "Technician",
                            icon: Icons.engineering,
                          ),
                          value: selectedTechnicianId,
                          hint: const Text("Select a technician"),
                          items:
                              technicians.map((t) {
                                final id = t['technician_id'].toString();
                                return DropdownMenuItem<String>(
                                  value: id,
                                  child: Text(t['name']),
                                );
                              }).toList(),
                          onChanged:
                              (v) => setState(() => selectedTechnicianId = v),
                        ),

                        const SizedBox(height: 12),
                        TextFormField(
                          controller: problemTypeController,
                          decoration: _decor(
                            "Problem Type",
                            icon: Icons.category,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: reportedProblemController,
                          decoration: _decor(
                            "Reported Problem",
                            icon: Icons.description_outlined,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Priority",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children:
                              ['High', 'Medium', 'Low'].map((p) {
                                final selected = priorityController.text == p;
                                return ChoiceChip(
                                  label: Text(p),
                                  selected: selected,
                                  onSelected:
                                      (_) => setState(
                                        () => priorityController.text = p,
                                      ),
                                  selectedColor: const Color(
                                    0xFF1E9E8E,
                                  ).withOpacity(0.2),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: _decor(
                              "Scheduled Date",
                              icon: Icons.event,
                            ),
                            child: Text(scheduledDate ?? "Select a date"),
                          ),
                        ),
                        const SizedBox(height: 20),

                        /// ✅ زر التعديل بعد الدمج مع الـ API
                        ElevatedButton.icon(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final id = prefs.getInt('selectedTaskId');

                            if (id == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "❌ لم يتم العثور على ID المهمة",
                                  ),
                                ),
                              );
                              return;
                            }

                            // استدعاء API التحديث
                            final success = await EditTaskService.updateTask(
                              id: id,
                              machineId: selectedMachineId,
                              technicianId: selectedTechnicianId,
                              problemType: problemTypeController.text,
                              reportedProblem: reportedProblemController.text,
                              priority: priorityController.text,
                              scheduledDate: scheduledDate,
                            );

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("✅ تم تعديل المهمة بنجاح"),
                                ),
                              );
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("❌ فشل تعديل المهمة"),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text(
                            "Edit",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
