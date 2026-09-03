import 'submission.dart';

class TaskItem {
  final int id;
  final String title;
  final String? description;
  final String status; // 'pending', 'submitted', 'completed'
  final int? assignedTo;
  final String assignedEmployeeName;
  final String? assignedEmployeeId;
  final int? createdBy;
  final String creatorName;
  final String? createdAt;
  final Submission? submission;

  TaskItem({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.assignedTo,
    required this.assignedEmployeeName,
    this.assignedEmployeeId,
    this.createdBy,
    required this.creatorName,
    this.createdAt,
    this.submission,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as int,
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'pending',
      assignedTo: json['assigned_to'],
      assignedEmployeeName: json['assigned_employee_name'] ?? 'Unassigned',
      assignedEmployeeId: json['assigned_employee_id'],
      createdBy: json['created_by'],
      creatorName: json['creator_name'] ?? 'System',
      createdAt: json['created_at'],
      submission: json['submission'] != null
          ? Submission.fromJson(json['submission'])
          : null,
    );
  }
}
