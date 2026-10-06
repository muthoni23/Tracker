import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/assignment.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/priority_badge.dart';
import 'add_assignment_screen.dart';

class AssignmentDetailsScreen extends StatefulWidget {
  final Assignment assignment;
  final Course? course;
  const AssignmentDetailsScreen({super.key, required this.assignment, this.course});

  @override
  State<AssignmentDetailsScreen> createState() => _AssignmentDetailsScreenState();
}

class _AssignmentDetailsScreenState extends State<AssignmentDetailsScreen> {
  final _service = FirestoreService();
  late AssignmentStatus _status;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _status = widget.assignment.status;
  }

  Future<void> _updateStatus(AssignmentStatus status) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() {
      _status = status;
      _updating = true;
    });
    try {
      await _service.updateAssignmentStatus(uid, widget.assignment.id, status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not update status: $e')));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final course = widget.course;
    final colors = context.surfaceColors;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final saved = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddAssignmentScreen(existing: a),
                ),
              );
              // The list screens behind this one stream live Firestore data,
              // so pop back to them rather than showing this stale snapshot.
              if (saved == true && context.mounted) Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete assignment?'),
                  content: const Text('This can\'t be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  await _service.deleteAssignment(uid, a.id);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Could not delete: $e')));
                  }
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: course?.color ?? AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(course?.icon ?? Icons.menu_book_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        PriorityBadge(priority: a.priorityLabel),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Due ${a.dueDate.day}/${a.dueDate.month}/${a.dueDate.year} · '
                    '${TimeOfDay.fromDateTime(a.dueDate).format(context)}',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.menu_book_outlined, size: 16, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(a.courseName, style: TextStyle(color: colors.textSecondary)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                a.description.isEmpty ? 'No description added.' : a.description,
                style: TextStyle(color: colors.textPrimary, height: 1.4),
              ),
              const SizedBox(height: 24),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatusChip(
                    label: 'Pending',
                    selected: _status == AssignmentStatus.pending,
                    onTap: () => _updateStatus(AssignmentStatus.pending),
                  ),
                  const SizedBox(width: 10),
                  _StatusChip(
                    label: 'Completed',
                    selected: _status == AssignmentStatus.completed,
                    onTap: () => _updateStatus(AssignmentStatus.completed),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                icon: _updating
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, color: Colors.white),
                label: const Text('Mark as Completed'),
                onPressed: _updating ? null : () => _updateStatus(AssignmentStatus.completed),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _StatusChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.surfaceColors;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : colors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
