import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/SystemNotification.dart';
import '../Homepage/StudentHomepage.dart'; // For AppColors and AppTextStyles

class StudentNotification extends StatefulWidget {
  const StudentNotification({super.key});

  @override
  State<StudentNotification> createState() => _StudentNotificationState();
}

class _StudentNotificationState extends State<StudentNotification> {
  bool _isLoading = true;
  List<SystemNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getNotifications();
    
    if (result['success'] && result['data'] != null) {
      final List<dynamic> data = result['data'];
      setState(() {
        _notifications = data.map((json) => SystemNotification.fromJson(json)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(SystemNotification notif) async {
    if (notif.isRead) return;

    await ApiService.markNotificationAsRead(notif.notificationId);
    _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        iconTheme: const IconThemeData(color: AppColors.appBarIcon),
        title: const Text('Notifications', style: AppTextStyles.appBarTitle),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.appBarBackground))
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications right now.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    return Card(
                      color: notif.isRead ? Colors.white : Colors.blue.shade50,
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Icon(
                          Icons.notifications,
                          color: notif.isRead ? Colors.grey : AppColors.appBarBackground,
                        ),
                        title: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(notif.message),
                            const SizedBox(height: 8),
                            Text(
                              notif.createdAt,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        onTap: () => _markAsRead(notif),
                      ),
                    );
                  },
                ),
    );
  }
}
