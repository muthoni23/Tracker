import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/assignment.dart';
import '../../models/course.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/course_card.dart';
import '../../widgets/assignment_tile.dart';
import '../assignments/assignment_details_screen.dart';
import '../courses/courses_screen.dart';
import '../assignments/assignments_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AuthService.profileVersion,
      builder: (context, _, __) => _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colors = context.surfaceColors;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final name = (user?.displayName?.isNotEmpty ?? false) ? user!.displayName! : 'there';
    final service = FirestoreService();

    if (uid == null) {
      return const Center(child: Text('Not signed in.'));
    }

    return SafeArea(
      child: StreamBuilder<List<Course>>(
        stream: service.watchCourses(uid),
        builder: (context, courseSnap) {
          final courses = courseSnap.data ?? [];
          return StreamBuilder<List<Assignment>>(
            stream: service.watchAssignments(uid),
            builder: (context, assignSnap) {
              if (courseSnap.connectionState == ConnectionState.waiting &&
                  assignSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final assignments = assignSnap.data ?? [];
              final upcoming =
                  assignments.where((a) => !a.isCompleted).take(2).toList();
              final completedCount = assignments.where((a) => a.isCompleted).length;
              final overallProgress = assignments.isEmpty
                  ? 0
                  : ((completedCount / assignments.length) * 100).round();

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello,',
                            style: TextStyle(color: colors.textSecondary)),
                        Text('$name 💜',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("Keep going, you're doing great! 💪",
                        style: TextStyle(color: colors.textSecondary)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Overall Progress',
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('$overallProgress%',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: overallProgress / 100,
                              minHeight: 8,
                              backgroundColor: colors.divider,
                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$completedCount of ${assignments.length} assignments completed',
                            style: TextStyle(color: colors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Coming Up',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AssignmentsScreen()),
                          ),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    if (upcoming.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('Nothing due — add your first assignment!',
                            style: TextStyle(color: colors.textSecondary)),
                      )
                    else
                      ...upcoming.map((a) {
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
                      }),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your Courses',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CoursesScreen()),
                          ),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    if (courses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('No courses yet — add one from the Courses tab.',
                            style: TextStyle(color: colors.textSecondary)),
                      )
                    else
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: courses.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final c = courses[i];
                            final courseAssignments =
                                assignments.where((a) => a.courseId == c.id).toList();
                            final done = courseAssignments.where((a) => a.isCompleted).length;
                            final pct = courseAssignments.isEmpty
                                ? 0
                                : ((done / courseAssignments.length) * 100).round();
                            return CourseCard(
                              course: c,
                              compact: true,
                              assignmentCount: courseAssignments.length,
                              progressPercent: pct,
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
    );
  }
}
