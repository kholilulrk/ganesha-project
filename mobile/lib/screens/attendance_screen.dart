import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attendance.dart';
import '../providers/auth_provider.dart';
import '../services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Attendance> _records = [];
  bool _loading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  String _filterRole = '';

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _loading = true);
    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final records = await AttendanceService.getReport(
        date: dateStr,
        role: _filterRole.isNotEmpty ? _filterRole : null,
      );
      if (mounted) setState(() {
        _records = records;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = '$e';
        _loading = false;
        _records = [];
      });
    }
  }

  Future<void> _deleteRecord(Attendance att) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Absensi'),
        content: Text('Hapus absensi ${att.user?.name ?? ''} tanggal ${att.date}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AttendanceService.delete(att.id);
      await _fetchReport();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSuperAdmin = auth.user?.role == 'Super Admin';
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF4F46E5).withOpacity(0.08), const Color(0xFF7C3AED).withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data Absensi', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Riwayat absensi dan lembur karyawan', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                              _fetchReport();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF4F46E5)),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filterRole.isEmpty ? null : _filterRole,
                            hint: const Text('Semua', style: TextStyle(fontSize: 13)),
                            items: ['Teknisi', 'Logistic', 'Administrasi'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (v) {
                              setState(() => _filterRole = v ?? '');
                              _fetchReport();
                            },
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: _fetchReport,
                        color: const Color(0xFF4F46E5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: TextStyle(color: Colors.red.shade600)))
                    : _records.isEmpty
                        ? Center(child: Text('Belum ada data absensi', style: TextStyle(color: Colors.grey.shade500)))
                        : RefreshIndicator(
                            onRefresh: _fetchReport,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _records.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final att = _records[i];
                                return _AttendanceTile(
                                  attendance: att,
                                  isSuperAdmin: isSuperAdmin,
                                  onDelete: () => _deleteRecord(att),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final Attendance attendance;
  final bool isSuperAdmin;
  final VoidCallback onDelete;

  const _AttendanceTile({
    required this.attendance,
    required this.isSuperAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    IconData typeIcon;
    switch (attendance.type) {
      case 'hadir':
        typeColor = const Color(0xFF22C55E);
        typeIcon = Icons.check_circle;
        break;
      case 'lembur':
        typeColor = const Color(0xFFF59E0B);
        typeIcon = Icons.nightlight_round;
        break;
      case 'tidak_hadir':
        typeColor = const Color(0xFFEF4444);
        typeIcon = Icons.cancel;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: typeColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendance.user?.name ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        attendance.displayType,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: typeColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (attendance.clockIn != null)
                      Text('Masuk ${attendance.clockIn}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
                if (attendance.isLembur) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Lembur: ${attendance.lemburStart ?? "-"} → ${attendance.lemburEnd ?? "Sedang lembur"}${attendance.durasiLembur != null ? " · ${attendance.durasiLembur}" : ""}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
                if (attendance.isTidakHadir && attendance.reason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Alasan: ${attendance.reason}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ),
              ],
            ),
          ),
          if (isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
