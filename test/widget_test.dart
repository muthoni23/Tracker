import 'package:flutter_test/flutter_test.dart';

import 'package:my_assignment_tracker/main.dart';

void main() {
  testWidgets('My Assignment Tracker starts correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyAssignmentTrackerApp());

    expect(find.text('StudyTrack'), findsOneWidget);
  });
}