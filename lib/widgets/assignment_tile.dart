import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/assignment.dart';
import '../theme/app_colors.dart';
import 'priority_badge.dart';

class AssignmentTile extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback? onTap;

  const AssignmentTile({super.key, required this.assignment, this.onTap});

  String _dueLabel(DateTime due) {
    final now = DateTime.now();
    final diff = DateTime(due.year, due.month, due.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in $diff days';
  }

  @override
  Widget build(BuildContext context) {
    final overdue = assignment.status == AssignmentStatus.overdue;
    final colors = context.surfaceColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.priorityColor(assignment.priorityLabel),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${overdue ? "Overdue" : _dueLabel(assignment.dueDate)} · '
                    '${DateFormat.jm().format(assignment.dueDate)}',
                    style: TextStyle(
                      color: overdue ? AppColors.priorityHigh : colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            PriorityBadge(priority: assignment.priorityLabel),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
