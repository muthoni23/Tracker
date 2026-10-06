import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/assignment.dart';
import '../models/course.dart';

/// Reads/writes assignments and courses scoped to the signed-in user:
///   users/{uid}/courses/{courseId}
///   users/{uid}/assignments/{assignmentId}
/// This is real Firestore data — nothing here is sample/dummy data.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _courses(String uid) =>
      _db.collection('users').doc(uid).collection('courses');

  CollectionReference<Map<String, dynamic>> _assignments(String uid) =>
      _db.collection('users').doc(uid).collection('assignments');

  Stream<List<Course>> watchCourses(String uid) {
    return _courses(uid).snapshots().map((snap) =>
        snap.docs.map((d) => Course.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Assignment>> watchAssignments(String uid) {
    return _assignments(uid).orderBy('dueDate').snapshots().map((snap) =>
        snap.docs.map((d) => Assignment.fromMap(d.id, d.data())).toList());
  }

  Future<String> addCourse(
    String uid, {
    required String name,
    required Color color,
    required IconData icon,
  }) async {
    final docRef = _courses(uid).doc();
    final course = Course(id: docRef.id, name: name, color: color, icon: icon);
    await docRef.set(course.toMap());
    return docRef.id;
  }

  /// Updates an existing course document in place — never creates a new one.
  /// Also keeps the denormalized `courseName` on any assignments that
  /// reference this course in sync, so renamed courses show correctly
  /// without changing the overall Firestore structure.
  Future<void> updateCourse(
    String uid,
    String courseId, {
    required String name,
    required Color color,
    required IconData icon,
  }) async {
    final batch = _db.batch();
    batch.update(_courses(uid).doc(courseId), {
      'name': name,
      'color': color.value,
      'iconCode': icon.codePoint,
    });

    final affected =
        await _assignments(uid).where('courseId', isEqualTo: courseId).get();
    for (final doc in affected.docs) {
      batch.update(doc.reference, {'courseName': name});
    }

    await batch.commit();
  }

  Future<void> deleteCourse(String uid, String courseId) {
    return _courses(uid).doc(courseId).delete();
  }

  Future<String> addAssignment(
    String uid, {
    required String title,
    required String courseId,
    required String courseName,
    required DateTime dueDate,
    AssignmentPriority priority = AssignmentPriority.medium,
    String description = '',
    List<String> attachmentNames = const [],
  }) async {
    final docRef = _assignments(uid).doc();
    final assignment = Assignment(
      id: docRef.id,
      title: title,
      courseId: courseId,
      courseName: courseName,
      dueDate: dueDate,
      priority: priority,
      description: description,
      attachmentNames: attachmentNames,
    );
    await docRef.set(assignment.toMap());
    return docRef.id;
  }

  /// Updates an existing assignment document in place — never creates a
  /// duplicate. `courseId`/`courseName` are updated together so they stay
  /// in sync if the assignment is moved to a different course.
  Future<void> updateAssignment(
    String uid,
    String assignmentId, {
    required String title,
    required String courseId,
    required String courseName,
    required DateTime dueDate,
    required AssignmentPriority priority,
    required String description,
    List<String>? attachmentNames,
  }) {
    final data = <String, dynamic>{
      'title': title,
      'courseId': courseId,
      'courseName': courseName,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.index,
      'description': description,
    };
    if (attachmentNames != null) {
      data['attachmentNames'] = attachmentNames;
    }
    return _assignments(uid).doc(assignmentId).update(data);
  }

  Future<void> updateAssignmentStatus(
      String uid, String assignmentId, AssignmentStatus status) {
    return _assignments(uid)
        .doc(assignmentId)
        .update({'status': status.index});
  }

  Future<void> deleteAssignment(String uid, String assignmentId) {
    return _assignments(uid).doc(assignmentId).delete();
  }
}
