import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/profile_bar.dart';
import 'home_screen.dart';
import 'job_list_screen.dart';
import 'todo_screen.dart';
import 'user_management_screen.dart';
import 'permissions_screen.dart';
import 'document_management_screen.dart';
import 'monitoring_surat_screen.dart';
import 'kelengkapan_dokumen_screen.dart';
import 'notification_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _uncompletedTeknisi = 0;
  int _uncompletedLogistic = 0;
  int _notifBadge = 0;

  @override
  void initState() {
    super.initState();
    _loadBadgeCounts();
    NotificationService().onUnreadChanged = (count) {
      if (mounted) setState(() => _notifBadge = count);
    };
  }

  Future<void> _loadBadgeCounts() async {
    try {
      final data = await ApiService.get('/dashboard');
      if (mounted) {
        setState(() {
          _uncompletedTeknisi = data['uncompleted_teknisi'] ?? 0;
          _uncompletedLogistic = data['uncompleted_logistic'] ?? 0;
        });
      }
    } catch (_) {}
  }

  bool get _showBadge {
    final user = context.read<AuthProvider>().user;
    if (user == null) return false;
    if (user.role == 'Teknisi') return _uncompletedTeknisi > 0;
    if (user.role == 'Logistic') return _uncompletedLogistic > 0;
    return (_uncompletedTeknisi + _uncompletedLogistic) > 0;
  }

  bool _badgeForTab(int index) {
    // Tab 2 is Pekerjaan
    if (index == 2) return _showBadge;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final perm = context.watch<PermissionProvider>();
    final user = context.watch<AuthProvider>().user;
    final isSuperAdmin = user?.role == 'Super Admin';
    final isTeknisiOrLogistic = user?.role == 'Teknisi' || user?.role == 'Logistic';

    final screenList = <Widget>[];
    final titles = <String>[];
    final icons = <IconData>[];

    // Dashboard - always
    screenList.add(const HomeScreen());
    titles.add('Dashboard');
    icons.add(Icons.dashboard_rounded);

    // Notifications
    screenList.add(const NotificationScreen());
    titles.add('Notif');
    icons.add(Icons.notifications_rounded);

    // Data Pekerjaan - only if can view
    if (perm.can('pekerjaan', 'view', isSuperAdmin: isSuperAdmin)) {
      screenList.add(const JobListScreen());
      titles.add('Pekerjaan');
      icons.add(Icons.work_history_rounded);
    }

    // To-do List - for all roles
    screenList.add(const TodoScreen());
    titles.add('To-do');
    icons.add(Icons.checklist_rounded);

    // Dokumen - for all roles
    screenList.add(const DocumentManagementScreen());
    titles.add('Dokumen');
    icons.add(Icons.folder_rounded);

    if (!isTeknisiOrLogistic) {

      // Kelengkapan Dokumen
      screenList.add(const KelengkapanDokumenScreen());
      titles.add('Kel. Dokumen');
      icons.add(Icons.assignment_rounded);

      // Monitoring Surat
      screenList.add(const MonitoringSuratScreen());
      titles.add('Surat');
      icons.add(Icons.description_rounded);

    }

    // Pengguna - Super Admin only
    if (isSuperAdmin) {
      screenList.add(const UserManagementScreen());
      titles.add('Pengguna');
      icons.add(Icons.people_alt_rounded);
    }

    // Akses - Super Admin only
    if (isSuperAdmin) {
      screenList.add(const PermissionsScreen());
      titles.add('Akses');
      icons.add(Icons.security_rounded);
    }

    return Scaffold(
      body: Column(
        children: [
          const ProfileBar(),
          // Main content
          Expanded(
            child: IndexedStack(
              index: _currentIndex < screenList.length ? _currentIndex : 0,
              children: screenList,
            ),
          ),
          // Bottom nav
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2)),
              ],
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(screenList.length, (i) {
                    final isSelected = _currentIndex == i;
                    final iconData = icons[i];
                    final title = titles[i];
                    return _BottomNavItem(
                      icon: iconData,
                      label: title,
                      isSelected: isSelected,
                      showBadge: (i == 1 && _notifBadge > 0) || _badgeForTab(i),
                      badgeCount: i == 1 ? _notifBadge : null,
                      onTap: () => setState(() => _currentIndex = i),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool showBadge;
  final int? badgeCount;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.showBadge = false,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade600),
                ),
                if (showBadge)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: badgeCount != null && badgeCount! > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
                            child: Text(
                              badgeCount! > 99 ? '99+' : '$badgeCount',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade600)),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 16,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
