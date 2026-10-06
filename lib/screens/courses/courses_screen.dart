import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/assignment.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/course_card.dart';
import '../assignments/assignments_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _service = FirestoreService();
  String _query = '';

  Future<void> _showAddCourseDialog(String uid, {Course? editing}) async {
    final isEditing = editing != null;
    final nameController = TextEditingController(text: editing?.name ?? '');
    Color selectedColor = editing?.color ?? AppColors.coursePalette.first;
    IconData selectedIcon = editing?.icon ?? kCourseIconChoices.first;
    bool isSaving = false;
    String? errorText;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colors = context.surfaceColors;
            return AlertDialog(
              title: Text(isEditing ? 'Edit Course' : 'Add Course'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(hintText: 'e.g. Computer Science'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: AppColors.coursePalette.map((c) {
                        final selected = c.value == selectedColor.value;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(color: colors.textPrimary, width: 2)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kCourseIconChoices.map((icon) {
                        final selected = icon == selectedIcon;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected ? selectedColor.withOpacity(0.15) : colors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: selected ? Border.all(color: selectedColor) : null,
                            ),
                            child: Icon(icon, size: 20),
                          ),
                        );
                      }).toList(),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!, style: const TextStyle(color: AppColors.priorityHigh)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) {
                            setDialogState(() => errorText = 'Course name cannot be empty.');
                            return;
                          }
                          setDialogState(() {
                            isSaving = true;
                            errorText = null;
                          });
                          try {
                            if (isEditing) {
                              await _service.updateCourse(
                                uid,
                                editing.id,
                                name: nameController.text.trim(),
                                color: selectedColor,
                                icon: selectedIcon,
                              );
                            } else {
                              await _service.addCourse(
                                uid,
                                name: nameController.text.trim(),
                                color: selectedColor,
                                icon: selectedIcon,
                              );
                            }
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              errorText =
                                  isEditing ? 'Could not save changes: $e' : 'Could not add course: $e';
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteCourse(String uid, Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text(
          'This will permanently delete "${course.name}". Assignments already linked to it will remain in Firestore but will no longer be grouped under this course.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.priorityHigh),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _service.deleteCourse(uid, course.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('"${course.name}" deleted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not delete course: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not signed in.'));
    final colors = context.surfaceColors;

    return Scaffold(
      body: SafeArea(
        child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Courses',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                Container(
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () => _showAddCourseDialog(uid),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Course>>(
                stream: _service.watchCourses(uid),
                builder: (context, courseSnap) {
                  if (courseSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final courses = (courseSnap.data ?? [])
                      .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
                      .toList();
                  if (courses.isEmpty) {
                    return Center(
                      child: Text('No courses yet.\nTap + to add your first one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.textSecondary)),
                    );
                  }
                  return StreamBuilder<List<Assignment>>(
                    stream: _service.watchAssignments(uid),
                    builder: (context, assignSnap) {
                      final assignments = assignSnap.data ?? [];
                      return GridView.builder(
                        itemCount: courses.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.95,
                        ),
                        itemBuilder: (context, i) {
                          final course = courses[i];
                          final courseAssignments =
                              assignments.where((a) => a.courseId == course.id).toList();
                          final done = courseAssignments.where((a) => a.isCompleted).length;
                          final pct = courseAssignments.isEmpty
                              ? 0
                              : ((done / courseAssignments.length) * 100).round();
                          return CourseCard(
                            course: course,
                            assignmentCount: courseAssignments.length,
                            progressPercent: pct,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AssignmentsScreen(filterCourseId: course.id),
                              ),
                            ),
                            onEdit: () => _showAddCourseDialog(uid, editing: course),
                            onDelete: () => _confirmDeleteCourse(uid, course),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
