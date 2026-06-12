import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/document_service.dart';
import '../services/attendance_service.dart';
import '../models/attendance.dart';
import '../models/job.dart';
import '../models/surat.dart';
import '../models/user.dart';
import '../models/document.dart';
import '../models/announcement.dart';
import '../services/job_service.dart';
import 'job_detail_screen.dart';
import '../widgets/animated_entry.dart';

class HomeScreen extends StatefulWidget {
  final void Function(String? filter)? onNavigateToPekerjaan;
  const HomeScreen({super.key, this.onNavigateToPekerjaan});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  Timer? _timer;

  Attendance? _attendance;
  bool _attLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadStats();
      _checkTimeAndRefresh();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAttendance());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final data = await ApiService.get('/dashboard');
      if (mounted) setState(() => _stats = data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  bool get _isAttendanceTime {
    final now = DateTime.now();
    final totalMin = now.hour * 60 + now.minute;
    return totalMin >= 30 && now.hour < 17;
  }

  bool get _isOvertimeTime {
    final now = DateTime.now();
    return now.hour >= 17 && now.hour < 24;
  }

  Future<void> _fetchAttendance() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.role == 'Super Admin') return;
    final att = await AttendanceService.getToday();
    if (mounted) setState(() => _attendance = att);
  }

  Future<void> _checkTimeAndRefresh() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.role == 'Super Admin') return;
    if (_isOvertimeTime || _isAttendanceTime) {
      await _fetchAttendance();
    }
  }

  List<Surat> get _expiringSurats {
    if (_stats == null || _stats!['expiring_surats'] == null) return [];
    return (_stats!['expiring_surats'] as List<dynamic>)
        .map((j) => Surat.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  List<Announcement> get _activeAnnouncements {
    if (_stats == null || _stats!['announcements'] == null) return [];
    return (_stats!['announcements'] as List<dynamic>)
        .map((j) => Announcement.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  List<Job> get _recentPending {
    if (_stats == null || _stats!['recent_pending'] == null) return [];
    return (_stats!['recent_pending'] as List<dynamic>)
        .map((j) => Job.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  String _statusBadge(String? status) {
    switch (status) {
      case 'Selesai': case 'done': return 'Selesai';
      case 'Progres': case 'progres': return 'Progres';
      default: return 'Pending';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Selesai': case 'done': return const Color(0xFF22C55E);
      case 'Progres': case 'progres': return const Color(0xFF06B6D4);
      default: return const Color(0xFFEAB308);
    }
  }

  String _sisaHari(DateTime expire) {
    final diff = expire.difference(DateTime.now()).inDays;
    if (diff <= 1) return 'Besok kadaluarsa';
    return '$diff hari lagi';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final perm = context.watch<PermissionProvider>();
    final user = auth.user!;
    final isSuperAdmin = user.role == 'Super Admin';
    final isTeknisiOrLogistic = user.role == 'Teknisi' || user.role == 'Logistic';
    final canQuickCreate = perm.can('pekerjaan', 'create', isSuperAdmin: isSuperAdmin);
    final activeAnnouncements = _activeAnnouncements;
    final expiringSurats = _expiringSurats;
    final recentPending = _recentPending;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          SafeArea(
            top: true,
            minimum: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Selamat datang, ${user.name}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (_stats != null) ...[
              _StatGrid(
                stats: _stats!,
                onTotalTap: () => widget.onNavigateToPekerjaan?.call(null),
                onPendingTap: () => widget.onNavigateToPekerjaan?.call('pending'),
                onProgressTap: () => widget.onNavigateToPekerjaan?.call('progres'),
                onCompletedTap: () => widget.onNavigateToPekerjaan?.call('done'),
              ),
              const SizedBox(height: 12),
            ],

            // Attendance Card
            if (!isSuperAdmin) ...[
              FadeSlideIn(
                child: _AttendanceCard(
                  attendance: _attendance,
                  loading: _attLoading,
                  isAttendanceTime: _isAttendanceTime,
                  isOvertimeTime: _isOvertimeTime,
                  onHadir: _showHadirDialog,
                  onTidakHadir: _showTidakHadirDialog,
                  onLemburStart: _handleLemburStart,
                  onLemburEnd: _handleLemburEnd,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Active Announcements
            if (activeAnnouncements.isNotEmpty) ...[
              FadeSlideIn(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.campaign_rounded, color: Color(0xFF4F46E5), size: 20),
                          const SizedBox(width: 8),
                          const Text('Pengumuman', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text('${activeAnnouncements.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...activeAnnouncements.take(3).map((a) => FadeSlideIn(
                        index: activeAnnouncements.indexOf(a),
                        child: InkWell(
                          onTap: () => _showAnnouncementDetail(a),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                if (a.content != null && a.content!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(a.content!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Expiring Letters Warning
            if (expiringSurats.isNotEmpty && !isTeknisiOrLogistic) ...[
              FadeSlideIn(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEAB308).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEAB308), size: 20),
                          const SizedBox(width: 8),
                          const Text('Surat Akan Kadaluarsa', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFEAB308).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text('${expiringSurats.length} surat', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEAB308))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...expiringSurats.take(5).map((surat) => FadeSlideIn(
                        index: expiringSurats.indexOf(surat),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(surat.namaSurat, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('${surat.jenisSurat} · ${_sisaHari(surat.masaBerlaku)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: surat.jenisSurat == 'SIK' ? const Color(0xFF4F46E5).withOpacity(0.1) : const Color(0xFF22C55E).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(surat.jenisSurat, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                  color: surat.jenisSurat == 'SIK' ? const Color(0xFF4F46E5) : const Color(0xFF22C55E))),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Recent Opened Jobs
            if (recentPending.isNotEmpty) ...[
              FadeSlideIn(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Baru Dibuka', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 12),
                      ...recentPending.take(5).map((job) => FadeSlideIn(
                        index: recentPending.indexOf(job),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)));
                            _loadStats();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(job.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      if (job.share != null)
                                        Text(job.share!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                Text(_statusBadge(job.status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(job.status))),
                              ],
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            FadeSlideIn(
              index: 2,
              child: _QuickActions(
                user: user,
                onQuickCreate: canQuickCreate ? _showQuickCreateForm : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showQuickCreateForm() async {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    final valueC = TextEditingController();
    final contractDateC = TextEditingController();
    final datelineC = TextEditingController();
    List<String> shareRoles = [];
    List<int> assignedTo = [];
    bool allTeknisi = false;
    String status = 'pending';
    String spektek = '';
    List<User> allUsers = [];
    List<Document> allDocuments = [];
    bool submitting = false;

    try {
      final results = await Future.wait([
        UserService.getAll(),
        DocumentService.getAll(),
      ]);
      allUsers = results[0] as List<User>;
      allDocuments = results[1] as List<Document>;
    } catch (_) {}

    if (!mounted) return;
    final pdfDocuments = allDocuments.where((d) => d.isPdf).toList();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tambah Pekerjaan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Nama Pekerjaan', isDense: true)),
                  const SizedBox(height: 10),
                  TextField(controller: descC, decoration: const InputDecoration(labelText: 'Deskripsi', isDense: true), maxLines: 2),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: valueC, decoration: const InputDecoration(labelText: 'Nilai (Rp)', isDense: true), keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: contractDateC, decoration: const InputDecoration(labelText: 'Tgl Kontrak', isDense: true), readOnly: true, onTap: () async {
                        final date = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (date != null) contractDateC.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      })),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Share (Role)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    children: ['Teknisi'].map((r) => FilterChip(
                      label: Text(r, style: const TextStyle(fontSize: 13)),
                      selected: shareRoles.contains(r),
                      onSelected: (v) {
                        setDialogState(() {
                          if (v) shareRoles.add(r); else shareRoles.remove(r);
                        });
                      },
                    )).toList(),
                  ),
                  if (shareRoles.contains('Teknisi'))
                    CheckboxListTile(
                      dense: true,
                      title: const Text('Semua Teknisi', style: TextStyle(fontSize: 13)),
                      value: allTeknisi,
                      onChanged: (v) => setDialogState(() => allTeknisi = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  if (shareRoles.isNotEmpty && !allTeknisi)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
          const SizedBox(height: 4),
                        const Text('Pilih Teknisi:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: ListView(
                            shrinkWrap: true,
                            children: allUsers.where((u) => u.role == 'Teknisi').map((u) => CheckboxListTile(
                              dense: true,
                              title: Text('${u.name} (${u.username})', style: const TextStyle(fontSize: 12)),
                              value: assignedTo.contains(u.id),
                              onChanged: (v) {
                                setDialogState(() {
                                  if (v == true) assignedTo.add(u.id); else assignedTo.remove(u.id);
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: status,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Status', isDense: true),
                          items: ['pending', 'progres', 'done'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setDialogState(() => status = v ?? 'pending'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: datelineC, decoration: const InputDecoration(labelText: 'Dateline', isDense: true), readOnly: true, onTap: () async {
                        final date = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (date != null) datelineC.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      })),
                    ],
                  ),
                  if (pdfDocuments.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: spektek.isEmpty ? null : spektek,
                      decoration: const InputDecoration(labelText: 'Referensi Dokumen (PDF)', isDense: true),
                      items: pdfDocuments.map((d) => DropdownMenuItem(value: d.filePath, child: Text(d.namaDokumen, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) => setDialogState(() => spektek = v ?? ''),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: submitting ? null : () async {
                            if (nameC.text.trim().isEmpty) return;
                            setDialogState(() => submitting = true);
                            try {
                              final body = <String, dynamic>{
                                'name': nameC.text.trim(),
                                'description': descC.text.trim(),
                                'value': valueC.text.replaceAll('.', ''),
                                'contract_date': contractDateC.text,
                                'share': shareRoles.join(','),
                                'status': status,
                                'dateline': datelineC.text,
                                'assigned_to': allTeknisi ? '' : assignedTo.join(','),
                                'spektek': spektek,
                              };
                              await JobService.create(body);
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              setDialogState(() => submitting = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          },
                          child: submitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Tambah'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showHadirDialog() async {
    final location = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Absen Hadir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Pilih lokasi kerja hari ini:', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _LocationOption(
                        icon: Icons.business,
                        label: 'Di Kantor',
                        value: 'kantor',
                        onTap: () => Navigator.pop(ctx, 'kantor'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LocationOption(
                        icon: Icons.directions_car,
                        label: 'Luar Kota',
                        value: 'luar_kota',
                        onTap: () => Navigator.pop(ctx, 'luar_kota'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (location == null) return;
    setState(() => _attLoading = true);
    try {
      final att = await AttendanceService.hadir(location);
      if (mounted) setState(() => _attendance = att);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _attLoading = false);
    }
  }

  Future<void> _showTidakHadirDialog() async {
    final reasonC = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tidak Hadir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: reasonC,
                decoration: const InputDecoration(
                  labelText: 'Alasan Tidak Hadir',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, reasonC.text.trim()),
                    child: const Text('Konfirmasi'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || result.isEmpty) return;
    setState(() => _attLoading = true);
    try {
      final att = await AttendanceService.tidakHadir(result);
      if (mounted) setState(() => _attendance = att);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _attLoading = false);
    }
  }

  Future<void> _handleLemburStart() async {
    setState(() => _attLoading = true);
    try {
      final att = await AttendanceService.lemburStart();
      if (mounted) setState(() => _attendance = att);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _attLoading = false);
    }
  }

  Future<void> _handleLemburEnd() async {
    setState(() => _attLoading = true);
    try {
      final att = await AttendanceService.lemburEnd();
      if (mounted) setState(() => _attendance = att);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _attLoading = false);
    }
  }

  void _showAnnouncementDetail(Announcement a) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: Color(0xFF4F46E5), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (a.content != null && a.content!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(a.content!, style: TextStyle(fontSize: 14, color: Colors.grey.shade700),),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Stat Grid
class _StatGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final VoidCallback? onTotalTap;
  final VoidCallback? onPendingTap;
  final VoidCallback? onProgressTap;
  final VoidCallback? onCompletedTap;
  const _StatGrid({required this.stats, this.onTotalTap, this.onPendingTap, this.onProgressTap, this.onCompletedTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(icon: Icons.work_history_rounded, label: 'Total Pekerjaan', value: '${stats['total_jobs'] ?? 0}', colors: const [Color(0xFF4F46E5), Color(0xFF7C3AED)], onTap: onTotalTap),
      _StatItem(icon: Icons.pending_actions_rounded, label: 'Pending', value: '${stats['pending_jobs'] ?? 0}', colors: const [Color(0xFFF59E0B), Color(0xFFEF4444)], onTap: onPendingTap),
      _StatItem(icon: Icons.trending_up_rounded, label: 'Progress', value: '${stats['progres_jobs'] ?? 0}', colors: const [Color(0xFF06B6D4), Color(0xFF3B82F6)], onTap: onProgressTap),
      _StatItem(icon: Icons.check_circle_rounded, label: 'Selesai', value: '${stats['completed_jobs'] ?? 0}', colors: const [Color(0xFF10B981), Color(0xFF059669)], onTap: onCompletedTap),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.0),
      itemCount: items.length,
      itemBuilder: (_, i) => ScaleIn(index: i, child: items[i]),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final List<Color> colors;
  final VoidCallback? onTap;
  const _StatItem({required this.icon, required this.label, required this.value, required this.colors, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),
                    Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Quick Actions
class _QuickActions extends StatelessWidget {
  final dynamic user;
  final VoidCallback? onQuickCreate;
  const _QuickActions({required this.user, this.onQuickCreate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Menu Cepat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
        const SizedBox(height: 12),
        if (onQuickCreate != null) ...[
          _ActionTile(
            icon: Icons.add_circle_rounded,
            title: 'Buat Pekerjaan',
            subtitle: 'Tambah pekerjaan baru',
            onTap: onQuickCreate!,
            iconColor: const Color(0xFF4F46E5),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final Color iconColor;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 22)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// Attendance Card
class _AttendanceCard extends StatelessWidget {
  final Attendance? attendance;
  final bool loading;
  final bool isAttendanceTime;
  final bool isOvertimeTime;
  final VoidCallback onHadir;
  final VoidCallback onTidakHadir;
  final VoidCallback onLemburStart;
  final VoidCallback onLemburEnd;

  const _AttendanceCard({
    required this.attendance,
    required this.loading,
    required this.isAttendanceTime,
    required this.isOvertimeTime,
    required this.onHadir,
    required this.onTidakHadir,
    required this.onLemburStart,
    required this.onLemburEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isHadir = attendance?.isHadir == true;
    final isTidakHadir = attendance?.isTidakHadir == true;
    final isLembur = attendance?.isLembur == true;
    final isLemburSelesai = attendance?.isLemburSelesai == true;
    final isLuarKota = attendance?.isLuarKota == true;

    Color cardColor;
    IconData icon;
    String title;
    String subtitle;
    List<Widget>? actions;

    if (isOvertimeTime) {
      cardColor = const Color(0xFFFFF8E1);
      icon = Icons.nightlight_round;
      if (attendance == null || isTidakHadir) {
        title = 'Lembur';
        subtitle = attendance == null ? 'Belum absen hari ini' : 'Tidak bisa lembur';
        actions = null;
      } else if (isLuarKota) {
        title = 'Lembur';
        subtitle = 'Tidak bisa lembur (luar kota)';
        actions = null;
      } else if (isLembur && isLemburSelesai) {
        title = 'Lembur Selesai';
        final durasi = _hitungDurasi(attendance!.clockIn!, attendance!.clockOut!);
        subtitle = 'Durasi: $durasi';
        actions = null;
      } else if (isLembur) {
        title = 'Sedang Lembur';
        subtitle = 'Mulai ${attendance!.clockIn ?? "-"}';
        actions = [
          _ActionButton(label: 'Akhiri Lembur', color: const Color(0xFF4F46E5), onTap: onLemburEnd),
        ];
      } else if (isHadir) {
        title = 'Lembur';
        subtitle = 'Absen ${attendance!.clockIn ?? "-"} · Klik untuk lembur';
        actions = [
          _ActionButton(label: 'Mulai Lembur', color: const Color(0xFFF59E0B), onTap: onLemburStart),
        ];
      } else {
        title = 'Lembur';
        subtitle = '';
        actions = null;
      }
    } else if (isHadir || isLembur) {
      cardColor = const Color(0xFFF0FDF4);
      icon = Icons.check_circle;
      final loc = isLuarKota ? 'Luar Kota' : 'Kantor';
      title = 'Sudah Absen Hadir';
      subtitle = 'Jam ${attendance!.clockIn ?? "-"} · $loc';
      actions = null;
    } else if (isTidakHadir) {
      cardColor = const Color(0xFFFEF2F2);
      icon = Icons.cancel;
      title = 'Tidak Hadir';
      subtitle = attendance?.reason ?? '';
      actions = null;
    } else if (isAttendanceTime) {
      cardColor = Colors.white;
      icon = Icons.edit_note;
      title = 'Absen Hari Ini';
      subtitle = 'Klik Hadir atau Tidak Hadir';
      actions = [
        _ActionButton(label: 'Hadir', color: const Color(0xFF22C55E), onTap: onHadir),
        const SizedBox(width: 8),
        _ActionButton(label: 'Tidak Hadir', color: const Color(0xFFEF4444), onTap: onTidakHadir),
      ];
    } else {
      cardColor = Colors.white;
      icon = Icons.edit_note;
      title = 'Absen Hari Ini';
      subtitle = 'Waktu absen: 00:30 - 17:00';
      actions = null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor == Colors.white ? Colors.grey.shade200 : cardColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isHadir || isLembur
                  ? const Color(0xFF22C55E).withOpacity(0.15)
                  : isTidakHadir
                      ? const Color(0xFFEF4444).withOpacity(0.15)
                      : isOvertimeTime
                          ? const Color(0xFFF59E0B).withOpacity(0.15)
                          : const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20,
              color: isHadir || isLembur
                  ? const Color(0xFF22C55E)
                  : isTidakHadir
                      ? const Color(0xFFEF4444)
                      : isOvertimeTime
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          if (loading)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          else if (actions != null)
            Row(mainAxisSize: MainAxisSize.min, children: actions),
        ],
      ),
    );
  }

  String _hitungDurasi(String clockIn, String clockOut) {
    try {
      final parts1 = clockIn.split(':');
      final parts2 = clockOut.split(':');
      final h1 = int.parse(parts1[0]), m1 = int.parse(parts1[1]);
      final h2 = int.parse(parts2[0]), m2 = int.parse(parts2[1]);
      int total = (h2 * 60 + m2) - (h1 * 60 + m1);
      if (total < 0) total += 24 * 60;
      return '${total ~/ 60}j ${total % 60}m';
    } catch (_) {
      return '-';
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

class _LocationOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _LocationOption({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: const Color(0xFF4F46E5)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
