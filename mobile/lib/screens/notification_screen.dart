import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_api_service.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> _notifications = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await NotificationApiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(int id) async {
    await NotificationApiService.markRead(id);
    NotificationService().refreshUnreadCount();
    _load();
  }

  Future<void> _markAllRead() async {
    await NotificationApiService.markAllRead();
    NotificationService().refreshUnreadCount();
    _load();
  }

  String _formatDate(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllRead,
              child: Text('Tandai Dibaca', style: TextStyle(fontSize: 13, color: theme.colorScheme.primary)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Tidak ada notifikasi', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final n = _notifications[i];
                      return Material(
                        color: n.isRead ? Colors.transparent : theme.colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: n.isRead ? Colors.grey.shade100 : theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _iconForType(n.type),
                              color: n.isRead ? Colors.grey : theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.body, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(_formatDate(n.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                            ],
                          ),
                          trailing: n.isRead
                              ? null
                              : Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                          onTap: n.isRead ? null : () => _markRead(n.id),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_job':
        return Icons.work_history_rounded;
      case 'new_task':
        return Icons.checklist_rounded;
      case 'new_document':
        return Icons.description_rounded;
      case 'job_completed':
        return Icons.check_circle_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      case 'attendance_reminder':
        return Icons.edit_note_rounded;
      case 'overtime_reminder':
        return Icons.nightlight_round;
      default:
        return Icons.notifications_rounded;
    }
  }
}
