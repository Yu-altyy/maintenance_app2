import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentenance_app/screens/admin_flow/pages/add_task/api_service.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> technicians = [];
  List<Map<String, dynamic>> machines = [];
  List<Map<String, dynamic>> subTasks = [];

  String? selectedMachineId;
  String? selectedTechnicianId;
  String? scheduledDate;
  int? userId; // 🔹 متغير لتخزين userId من SharedPreferences

  final TextEditingController problemTypeController = TextEditingController();
  final TextEditingController reportedProblemController =
      TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initUserAndData();
  }

  Future<void> _initUserAndData() async {
    await _loadUserId(); // جلب id المستخدم
    await _loadDropdownData();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(
      'userId',
    ); // 🔹 نفس المفتاح اللي بتخزنه فيه بعد تسجيل الدخول
    setState(() {
      userId = id;
    });
  }

  Future<void> _loadDropdownData() async {
    final techs = await ApiService.getTechnicians();
    final machs = await ApiService.getMachines();
    setState(() {
      technicians = techs;
      machines = machs;
    });
  }

  void _addSubTask() {
    subTasks.add({
      "machine_id": null,
      "technician_id": selectedTechnicianId,
      "problem_type": "",
      "reported_problem": "",
      "priority": "",
      "scheduled_date": "",
      "created_by_user_id": userId, // 🔹 إضافة تلقائية
    });
    setState(() {});
  }

  Future<void> _pickDate(Function(String) onPicked) async {
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
      final formatted =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      onPicked(formatted);
    }
  }

  // Helpers
  String? _toIdStr(dynamic v) => v == null ? null : v.toString();
  int? _toIdInt(String? v) => (v == null || v.isEmpty) ? null : int.tryParse(v);
  String _machineLabel(Map<String, dynamic> m) {
    final serial = (m['machine_serial_number'] ?? '').toString();
    final type = (m['machine_type_name'] ?? '').toString();
    return '$serial - $type';
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
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.teal, width: 1.4),
    ),
  );

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: const [
      BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 6)),
    ],
  );

  Widget _buildTaskForm(Map<String, dynamic> task, {bool isMain = false}) {
    final headerColor =
        isMain ? const Color(0xFF1E9E8E) : const Color(0xFF3B82F6);
    final priorities = const ['High', 'Medium', 'Low'];
    final enforceMainTech = !isMain && selectedTechnicianId != null;

    if (enforceMainTech && task["technician_id"] != selectedTechnicianId) {
      task["technician_id"] = selectedTechnicianId;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: _cardDecoration,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isMain ? Icons.task_alt : Icons.subdirectory_arrow_right,
                  color: headerColor,
                ),
                const SizedBox(width: 8),
                Text(
                  isMain ? "Main Task" : "Sub Task",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: headerColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: _decor(
                    "Machine",
                    icon: Icons.precision_manufacturing,
                  ),
                  value: _toIdStr(task["machine_id"]),
                  hint: const Text("Select a machine"),
                  items:
                      machines.map((m) {
                        final id = _toIdStr(m['machine_id'])!;
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            _machineLabel(m),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                  onChanged:
                      (v) => setState(() {
                        task["machine_id"] = v;
                        if (isMain) selectedMachineId = v;
                      }),
                ),
                const SizedBox(height: 12),

                // Technician logic
                if (!enforceMainTech)
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: _decor("Technician", icon: Icons.engineering),
                    value: _toIdStr(task["technician_id"]),
                    hint: const Text("Select a technician"),
                    items:
                        technicians.map((t) {
                          final id = _toIdStr(t['technician_id'])!;
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(t['name']),
                          );
                        }).toList(),
                    onChanged:
                        (v) => setState(() {
                          task["technician_id"] = v;
                          if (isMain) {
                            selectedTechnicianId = v;
                            for (final sub in subTasks) {
                              sub["technician_id"] = v;
                            }
                          }
                        }),
                  )
                else
                  TextFormField(
                    enabled: false,
                    initialValue:
                        technicians
                            .firstWhere(
                              (t) =>
                                  _toIdStr(t['technician_id']) ==
                                  selectedTechnicianId,
                              orElse: () => {"name": "Same as main technician"},
                            )['name']
                            .toString(),
                    decoration: _decor(
                      "Technician (locked)",
                      icon: Icons.lock_outline,
                    ),
                  ),

                const SizedBox(height: 12),
                TextFormField(
                  decoration: _decor("Problem Type", icon: Icons.category),
                  onChanged: (v) {
                    task["problem_type"] = v;
                    if (isMain) problemTypeController.text = v;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: _decor(
                    "Reported Problem",
                    icon: Icons.description_outlined,
                  ),
                  maxLines: 2,
                  onChanged: (v) {
                    task["reported_problem"] = v;
                    if (isMain) reportedProblemController.text = v;
                  },
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  children:
                      priorities.map((p) {
                        final selected =
                            (task["priority"] ?? '').toString() == p;
                        return ChoiceChip(
                          label: Text(p),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              task["priority"] = p;
                              if (isMain) priorityController.text = p;
                            });
                          },
                          selectedColor: const Color(
                            0xFF1E9E8E,
                          ).withOpacity(0.2),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap:
                      () => _pickDate((date) {
                        setState(() {
                          task["scheduled_date"] = date;
                          if (isMain) scheduledDate = date;
                        });
                      }),
                  child: InputDecorator(
                    decoration: _decor("Scheduled Date", icon: Icons.event),
                    child: Text(
                      (task["scheduled_date"]?.toString().isNotEmpty ?? false)
                          ? task["scheduled_date"]
                          : "Select a date",
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 🔹 ما في حقل "Created by" الآن لأنه يتعبّى تلقائياً من الشيرد
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (selectedMachineId == null ||
        problemTypeController.text.isEmpty ||
        reportedProblemController.text.isEmpty ||
        priorityController.text.isEmpty ||
        userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ تأكد من تعبئة الحقول المطلوبة")),
      );
      return;
    }

    final mainBody = {
      "machine_id": _toIdInt(selectedMachineId),
      "technician_id": _toIdInt(selectedTechnicianId),
      "problem_type": problemTypeController.text,
      "reported_problem": reportedProblemController.text,
      "priority": priorityController.text,
      "scheduled_date": scheduledDate,
      "created_by_user_id": userId, // 🔹 تعبئة تلقائية
      "parent_id": null,
    };

    int? parentId = await ApiService.storeMainTask(mainBody);

    if (parentId != null) {
      for (var sub in subTasks) {
        final subBody = {
          "machine_id": _toIdInt(sub["machine_id"]),
          "technician_id": _toIdInt(sub["technician_id"]),
          "problem_type": sub["problem_type"],
          "reported_problem": sub["reported_problem"],
          "priority": sub["priority"],
          "scheduled_date": sub["scheduled_date"],
          "created_by_user_id": userId, // 🔹 تعبئة تلقائية
        };
        await ApiService.storeSubTask(parentId, subBody);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ تم إرسال كل المهام بنجاح!")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ فشل إنشاء المهمة الرئيسية")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainTask = {
      "machine_id": selectedMachineId,
      "technician_id": selectedTechnicianId,
      "problem_type": problemTypeController.text,
      "reported_problem": reportedProblemController.text,
      "priority": priorityController.text,
      "scheduled_date": scheduledDate,
      "created_by_user_id": userId,
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Add Maintenance Tasks"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body:
          userId == null || technicians.isEmpty || machines.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTaskForm(mainTask, isMain: true),
                    if (subTasks.isNotEmpty)
                      ...subTasks.map((sub) => _buildTaskForm(sub)).toList(),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add Sub Task"),
                      onPressed: _addSubTask,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text(
                        "Submit All Tasks",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
