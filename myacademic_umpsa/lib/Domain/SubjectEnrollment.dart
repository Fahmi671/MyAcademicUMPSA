import 'Subject.dart';

class SubjectEnrollment {
  final int enrollmentId;
  final String subjectCode;
  final String enrollmentDate;
  final Subject? subject;

  SubjectEnrollment({
    required this.enrollmentId,
    required this.subjectCode,
    required this.enrollmentDate,
    this.subject,
  });

  factory SubjectEnrollment.fromJson(Map<String, dynamic> json) {
    return SubjectEnrollment(
      enrollmentId: json['Enrollment_ID'] ?? 0,
      subjectCode: json['Subject_Code'] ?? '',
      enrollmentDate: json['Enrollment_Date'] ?? '',
      subject: json['subject'] != null ? Subject.fromJson(json['subject']) : null,
    );
  }
}
