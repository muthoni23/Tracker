enum AssignmentPriority { low, medium, high }

enum AssignmentStatus { pending, completed, overdue }

class Assignment {
  final String id;
  final String title;
  final String courseId;
  final String courseName;
  final DateTime dueDate;
  final AssignmentPriority priority;
  final AssignmentStatus status;
  final String description;
  final List<String> attachmentNames;

  const Assignment({
    required this.id,
    required this.title,
    required this.courseId,
    required this.courseName,
    required this.dueDate,
    this.priority = AssignmentPriority.medium,
    this.status = AssignmentStatus.pending,
    this.description = '',
    this.attachmentNames = const [],
  });

  String get priorityLabel {
    switch (priority) {
      case AssignmentPriority.high:
        return 'High';
      case AssignmentPriority.medium:
        return 'Medium';
      case AssignmentPriority.low:
        return 'Low';
    }
  }

  bool get isCompleted => status == AssignmentStatus.completed;

  factory Assignment.fromMap(String id, Map<String, dynamic> map) {
    return Assignment(
      id: id,
      title: map['title'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      dueDate: DateTime.tryParse(map['dueDate'] ?? '') ?? DateTime.now(),
      priority: AssignmentPriority.values[map['priority'] ?? 1],
      status: AssignmentStatus.values[map['status'] ?? 0],
      description: map['description'] ?? '',
      attachmentNames: List<String>.from(map['attachmentNames'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'courseId': courseId,
        'courseName': courseName,
        'dueDate': dueDate.toIso8601String(),
        'priority': priority.index,
        'status': status.index,
        'description': description,
        'attachmentNames': attachmentNames,
      };

  Assignment copyWith({AssignmentStatus? status}) => Assignment(
        id: id,
        title: title,
        courseId: courseId,
        courseName: courseName,
        dueDate: dueDate,
        priority: priority,
        status: status ?? this.status,
        description: description,
        attachmentNames: attachmentNames,
      );
}
