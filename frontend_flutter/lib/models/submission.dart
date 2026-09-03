class Submission {
  final int id;
  final int taskId;
  final int submittedBy;
  final String submitterName;
  final String? submitterEmployeeId;
  final String? link;
  final String? zipPath;
  final bool hasFile;
  final String? submittedAt;
  final String? adminNotes;

  Submission({
    required this.id,
    required this.taskId,
    required this.submittedBy,
    required this.submitterName,
    this.submitterEmployeeId,
    this.link,
    this.zipPath,
    this.hasFile = false,
    this.submittedAt,
    this.adminNotes,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] as int,
      taskId: json['task_id'] as int,
      submittedBy: json['submitted_by'] as int,
      submitterName: json['submitter_name'] ?? 'Unknown',
      submitterEmployeeId: json['submitter_employee_id'],
      link: json['link'],
      zipPath: json['zip_path'],
      hasFile: json['has_file'] ?? false,
      submittedAt: json['submitted_at'],
      adminNotes: json['admin_notes'],
    );
  }
}
