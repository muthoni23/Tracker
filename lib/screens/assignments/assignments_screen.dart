import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/assignment.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/assignment_tile.dart';
import 'add_assignment_screen.dart';
import 'assignment_details_screen.dart';
import 'search_filter_sheet.dart';

class AssignmentsScreen extends StatefulWidget {
  final String? filterCourseId;
  const AssignmentsScreen({super.key, this.filterCourseId});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final _service = FirestoreService();
  String _tab = 'All'; // All / Pending / Completed
  String? _courseFilter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _courseFilter = widget.filterCourseId;
  }

  List<Assignment> _applyFilters(List<Assignment> assignments) {
    return assignments.where((a) {
      if (_tab == 'Pending' && a.isCompleted) return false;
      if (_tab == 'Completed' && !a.isCompleted) return false;
      if (_courseFilter != null && a.courseId != _courseFilter) return false;
      if (_query.isNotEmpty && !a.title.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Not signed in.')));

    return Scaffold(
      body: SafeArea(
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
                final items = _applyFilters(assignSnap.data ?? []);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Assignments',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                          IconButton(
                            icon: const Icon(Icons.filter_list),
                            onPressed: () async {
                              final result = await showModalBottomSheet<String?>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => SearchFilterSheet(
                                  initialCourseId: _courseFilter,
                                  courses: courses,
                                ),
                              );
                              if (result != null) {
                                setState(() => _courseFilter = result.isEmpty ? null : result);
                              }
                            },
                          ),
                        ],
                      ),
                      TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Search assignments...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _TabChip(label: 'All', selected: _tab == 'All', onTap: () => setState(() => _tab = 'All')),
                          const SizedBox(width: 8),
                          _TabChip(label: 'Pending', selected: _tab == 'Pending', onTap: () => setState(() => _tab = 'Pending')),
                          const SizedBox(width: 8),
                          _TabChip(label: 'Completed', selected: _tab == 'Completed', onTap: () => setState(() => _tab = 'Completed')),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: items.isEmpty
                            ? Center(
                                child: Text('No assignments here yet.',
                                    style: TextStyle(color: context.surfaceColors.textSecondary)),
                              )
                            : ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (context, i) {
                                  final a = items[i];
                                  final course = courses.where((c) => c.id == a.courseId).isNotEmpty
                                      ? courses.firstWhere((c) => c.id == a.courseId)
                                      : null;
                                  return AssignmentTile(
                                    assignment: a,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AssignmentDetailsScreen(assignment: a, course: course),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddAssignmentScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.surfaceColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : colors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
