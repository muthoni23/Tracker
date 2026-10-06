import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/assignment.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

class AddAssignmentScreen extends StatefulWidget {
  /// When non-null, the screen edits this existing assignment in place
  /// instead of creating a new one.
  final Assignment? existing;

  const AddAssignmentScreen({super.key, this.existing});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  late final _titleController =
      TextEditingController(text: widget.existing?.title ?? '');
  late final _notesController =
      TextEditingController(text: widget.existing?.description ?? '');
  final _service = FirestoreService();

  bool get _isEditing => widget.existing != null;

  String? _courseId;
  late AssignmentPriority _priority =
      widget.existing?.priority ?? AssignmentPriority.medium;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _courseId = existing.courseId;
      _dueDate = DateTime(existing.dueDate.year, existing.dueDate.month, existing.dueDate.day);
      _dueTime = TimeOfDay.fromDateTime(existing.dueDate);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
        context: context, initialTime: _dueTime ?? TimeOfDay.now());
    if (picked != null) setState(() => _dueTime = picked);
  }

  Future<void> _save(List<Course> courses) async {
    if (_courseId == null || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course and due date.')),
      );
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final course = courses.firstWhere((c) => c.id == _courseId);
    final time = _dueTime ?? TimeOfDay.now();
    final dueDateTime = DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      time.hour,
      time.minute,
    );

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await _service.updateAssignment(
          uid,
          widget.existing!.id,
          title: _titleController.text.trim(),
          courseId: course.id,
          courseName: course.name,
          dueDate: dueDateTime,
          priority: _priority,
          description: _notesController.text.trim(),
        );
      } else {
        await _service.addAssignment(
          uid,
          title: _titleController.text.trim(),
          courseId: course.id,
          courseName: course.name,
          dueDate: dueDateTime,
          priority: _priority,
          description: _notesController.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not save. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Not signed in.')));

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Assignment' : 'Add Assignment')),
      body: SafeArea(
        child: StreamBuilder<List<Course>>(
          stream: _service.watchCourses(uid),
          builder: (context, snap) {
            final courses = snap.data ?? [];
            final colors = context.surfaceColors;
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (courses.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Add a course first from the Courses tab, then come back to add an assignment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.surfaceColors.textSecondary),
                  ),
                ),
              );
            }
            final courseIds = courses.map((c) => c.id).toSet();
            if (_courseId == null || !courseIds.contains(_courseId)) {
              _courseId = courses.first.id;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Title (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'e.g. Database Systems Assignment'),
                  ),
                  const SizedBox(height: 18),
                  const Text('Course', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
  initialValue: _courseId,
  isExpanded: true,
  decoration: const InputDecoration(hintText: 'Select course'),
  items: courses
      .map((c) => DropdownMenuItem(
            value: c.id,
            child: Text(
              c.name,
              overflow: TextOverflow.ellipsis,
            ),
          ))
      .toList(),
  onChanged: (v) => setState(() => _courseId = v),
),
                  const SizedBox(height: 18),
                  const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: AssignmentPriority.values.map((p) {
                      final selected = _priority == p;
                      final color = AppColors.priorityColor(p.name);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                          selected: selected,
                          selectedColor: color.withOpacity(0.15),
                          labelStyle: TextStyle(color: selected ? color : colors.textPrimary),
                          onSelected: (_) => setState(() => _priority = p),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _DateTimeField(
                          icon: Icons.calendar_today_outlined,
                          label: 'Due Date',
                          value: _dueDate == null
                              ? 'Select date'
                              : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateTimeField(
                          icon: Icons.access_time,
                          label: 'Due Time',
                          value: _dueTime == null ? 'Select time' : _dueTime!.format(context),
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Notes (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Add any additional details...'),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _saving ? null : () => _save(courses),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTimeField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.surfaceColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.divider),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: colors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(value,
                      style: TextStyle(color: colors.textSecondary),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
