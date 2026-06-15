class SystemNotification {
  final int notificationId;
  final String studentId;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;

  SystemNotification({
    required this.notificationId,
    required this.studentId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory SystemNotification.fromJson(Map<String, dynamic> json) {
    return SystemNotification(
      notificationId: json['Notification_ID'] ?? 0,
      studentId: json['Student_ID']?.toString() ?? '',
      title: json['Title'] ?? '',
      message: json['Message'] ?? '',
      isRead: json['Is_Read'] == 1 || json['Is_Read'] == true,
      createdAt: json['Created_At'] ?? '',
    );
  }
}
