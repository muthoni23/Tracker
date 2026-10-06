import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      'How do I add a course?',
      'Go to the Courses tab and tap the add (+) button. Enter a course name, then pick a color and icon, and save. Your new course will appear right away.',
    ),
    (
      'How do I add an assignment?',
      'Open the Assignments tab (or tap "Add Assignment" from Home) and fill in the title, course, due date and priority, then save. You need at least one course before you can add an assignment.',
    ),
    (
      'How do I mark an assignment complete?',
      'Open the assignment from the Assignments list or Home screen and use the complete/checkmark action. Completed assignments count toward your progress and stop sending reminders.',
    ),
    (
      'How do I delete an assignment?',
      'Open the assignment and choose Delete. You will be asked to confirm before it is permanently removed.',
    ),
    (
      'How does progress work?',
      'Your overall progress is the percentage of your assignments marked as completed. Each course also shows its own progress based on the assignments linked to it.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.surfaceColors;
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Getting Started
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.rocket_launch_outlined, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Getting Started',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'StudyTrack follows a simple flow to help you stay on top of your work:',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  const _FlowStep(number: '1', label: 'Create a course'),
                  const _FlowStep(number: '2', label: 'Add an assignment to that course'),
                  const _FlowStep(number: '3', label: 'Track it from Home or the Assignments tab'),
                  const _FlowStep(number: '4', label: 'Mark it complete when you\'re done', isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('FAQ / Common Questions',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _faqs.length; i++) ...[
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(_faqs[i].$1,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_faqs[i].$2,
                              style: TextStyle(color: colors.textSecondary, height: 1.4)),
                        ],
                      ),
                    ),
                    if (i != _faqs.length - 1)
                      Divider(height: 1, indent: 16, endIndent: 16, color: colors.divider),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Still stuck? Double-check your internet connection — StudyTrack syncs your courses and assignments in real time, so most issues clear up once you\'re back online.',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  final String number;
  final String label;
  final bool isLast;

  const _FlowStep({required this.number, required this.label, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.surfaceColors;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(color: colors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
