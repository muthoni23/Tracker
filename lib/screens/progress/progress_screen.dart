import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/assignment.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _service = FirestoreService();
  bool _overviewTab = true;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not signed in.'));
    final colors = context.surfaceColors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Progress', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(
                    child: _SegButton(
                      label: 'Overview',
                      selected: _overviewTab,
                      onTap: () => setState(() => _overviewTab = true),
                    ),
                  ),
                  Expanded(
                    child: _SegButton(
                      label: 'Courses',
                      selected: !_overviewTab,
                      onTap: () => setState(() => _overviewTab = false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Course>>(
                stream: _service.watchCourses(uid),
                builder: (context, courseSnap) {
                  final courses = courseSnap.data ?? [];
                  return StreamBuilder<List<Assignment>>(
                    stream: _service.watchAssignments(uid),
                    builder: (context, assignSnap) {
                      if (assignSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final assignments = assignSnap.data ?? [];
                      final completed = assignments.where((a) => a.isCompleted).length;
                      final overdue =
                          assignments.where((a) => a.status == AssignmentStatus.overdue).length;
                      final pending = assignments.length - completed - overdue;
                      final overall =
                          assignments.isEmpty ? 0 : ((completed / assignments.length) * 100).round();

                      if (_overviewTab) {
                        return ListView(
                          children: [
                            Center(
                              child: SizedBox(
                                width: 180,
                                height: 180,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 180,
                                      height: 180,
                                      child: CircularProgressIndicator(
                                        value: overall / 100,
                                        strokeWidth: 12,
                                        backgroundColor: colors.divider,
                                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('$overall%',
                                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                                        Text('Completed', style: TextStyle(color: colors.textSecondary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                _StatCard(label: 'Completed', value: '$completed', color: AppColors.priorityLow),
                                const SizedBox(width: 12),
                                _StatCard(label: 'Pending', value: '$pending', color: AppColors.priorityMedium),
                                const SizedBox(width: 12),
                                _StatCard(label: 'Overdue', value: '$overdue', color: AppColors.priorityHigh),
                              ],
                            ),
                          ],
                        );
                      }

                      if (courses.isEmpty) {
                        return Center(
                          child: Text('No courses yet.', style: TextStyle(color: colors.textSecondary)),
                        );
                      }

                      return ListView(
                        children: [
                          const Text('Course Progress', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 12),
                          ...courses.map((c) {
                            final courseAssignments = assignments.where((a) => a.courseId == c.id).toList();
                            final done = courseAssignments.where((a) => a.isCompleted).length;
                            final pct = courseAssignments.isEmpty
                                ? 0
                                : ((done / courseAssignments.length) * 100).round();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text('$pct%', style: TextStyle(color: colors.textSecondary)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: pct / 100,
                                      minHeight: 8,
                                      backgroundColor: colors.divider,
                                      valueColor: AlwaysStoppedAnimation(c.color),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.surfaceColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.surfaceColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
