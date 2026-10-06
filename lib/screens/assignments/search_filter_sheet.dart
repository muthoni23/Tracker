import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../theme/app_colors.dart';

/// Bottom sheet matching the "Search & Filters" screen from the mockup.
/// Pops with the selected courseId ('' clears the filter, null = cancelled).
class SearchFilterSheet extends StatefulWidget {
  final String? initialCourseId;
  final List<Course> courses;
  const SearchFilterSheet({super.key, this.initialCourseId, required this.courses});

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  String _status = 'All';
  String _priority = 'All';
  String? _courseId;

  @override
  void initState() {
    super.initState();
    _courseId = widget.initialCourseId;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.surfaceColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Text('Search & Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Pending', 'Completed']
                            .map((s) => ChoiceChip(
                                  label: Text(s),
                                  selected: _status == s,
                                  onSelected: (_) => setState(() => _status = s),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'High', 'Medium', 'Low']
                            .map((p) => ChoiceChip(
                                  label: Text(p),
                                  selected: _priority == p,
                                  onSelected: (_) => setState(() => _priority = p),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text('Course', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('All'),
                        value: _courseId == null,
                        onChanged: (_) => setState(() => _courseId = null),
                      ),
                      if (widget.courses.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('No courses yet.',
                              style: TextStyle(color: colors.textSecondary)),
                        )
                      else
                        ...widget.courses.map((c) => CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(c.name),
                              secondary: CircleAvatar(radius: 6, backgroundColor: c.color),
                              value: _courseId == c.id,
                              onChanged: (_) => setState(() => _courseId = c.id),
                            )),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _status = 'All';
                            _priority = 'All';
                            _courseId = null;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(_courseId ?? ''),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
