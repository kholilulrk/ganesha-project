import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../screens/notification_screen.dart';

class ProfileBar extends StatefulWidget {
  const ProfileBar({super.key});
  @override
  State<ProfileBar> createState() => _ProfileBarState();
}

class _ProfileBarState extends State<ProfileBar> {
  int _notifBadge = 0;

  @override
  void initState() {
    super.initState();
    _notifBadge = NotificationService().unreadCount;
    NotificationService().onUnreadChanged = (count) {
      if (mounted) setState(() => _notifBadge = count);
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 4, left: 16, right: 16, bottom: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: user?.photo?.isNotEmpty == true
                  ? NetworkImage('${ApiService.baseUploadUrl}${user!.photo}')
                  : null,
              child: user?.photo?.isNotEmpty != true
                  ? Text(
                      ((user?.name.isNotEmpty == true) ? user!.name[0] : '?').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(user?.role ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
                ),
                if (_notifBadge > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
                      child: Text(
                        _notifBadge > 99 ? '99+' : '$_notifBadge',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
