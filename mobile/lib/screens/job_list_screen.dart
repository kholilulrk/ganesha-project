import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/job.dart';
import '../models/user.dart';
import '../models/document.dart';
import '../services/job_service.dart';
import '../services/user_service.dart';
import '../services/document_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import 'job_detail_screen.dart';
import '../widgets/animated_entry.dart';

class JobListScreen extends StatefulWidget {
  final String? filter;
  const JobListScreen({super.key, this.filter});
  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  List<Job> _jobs = [];
  List<Job> _filtered = [];
  bool _loading = true;
  final _searchC = TextEditingController();
  String _filterStatus = '';
  String _filterShare = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final f = widget.filter;
    if (f == 'pending') _filterStatus = 'pending';
    else if (f == 'progres') _filterStatus = 'progres';
    else if (f == 'done') _filterStatus = 'done';
    _loadJobs();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadJobs());
  }

  bool _passesFilter(Job j) {
    if (widget.filter == 'incomplete') return j.status != 'selesai' && j.status != 'done' && j.status != 'Selesai';
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    try {
      final jobs = await JobService.getJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _applyFilters();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    String q = _searchC.text.toLowerCase().trim();
    setState(() {
      _filtered = _jobs.where((j) {
        if (!_passesFilter(j)) return false;
        if (q.isNotEmpty && !j.name.toLowerCase().contains(q) && !(j.description ?? '').toLowerCase().contains(q)) return false;
        if (_filterStatus.isNotEmpty) {
          if (_filterStatus == 'done') {
            if (j.status != 'selesai' && j.status != 'done' && j.status != 'Selesai') return false;
          } else {
            if (j.status != _filterStatus) return false;
          }
        }
        if (_filterShare.isNotEmpty) {
          final shares = (j.share ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          if (!shares.contains(_filterShare)) return false;
        }
        return true;
      }).toList();
    });
  }

  void _filter(String q) {
    _searchC.text = q;
    _applyFilters();
  }

  Future<void> _showJobForm({Job? editJob}) async {
    final nameC = TextEditingController(text: editJob?.name ?? '');
    final descC = TextEditingController(text: editJob?.description ?? '');
    final valueC = TextEditingController(text: editJob != null ? editJob.value.toStringAsFixed(0) : '');
    final contractDateC = TextEditingController(text: _dateInput(editJob?.contractDate));
    final datelineC = TextEditingController(text: _dateInput(editJob?.dateline));
    List<String> shareRoles = editJob != null ? editJob.sharedRoles : [];
    List<int> assignedTo = editJob != null ? editJob.assignedUserIds : [];
    bool allTeknisi = false;
    String status = editJob?.status ?? 'pending';
    String spektek = editJob?.spektek ?? '';
    List<User> allUsers = [];
    List<Document> allDocuments = [];
    bool submitting = false;

    try {
      final results = await Future.wait([UserService.getAll(), DocumentService.getAll()]);
      allUsers = results[0] as List<User>;
      allDocuments = results[1] as List<Document>;
    } catch (_) {}

    final pdfDocuments = allDocuments.where((d) => d.isPdf).toList();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(editJob != null ? 'Edit Pekerjaan' : 'Tambah Pekerjaan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ]),
                const SizedBox(height: 16),
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Nama Pekerjaan')),
                const SizedBox(height: 12),
                TextField(controller: descC, decoration: const InputDecoration(labelText: 'Deskripsi'), maxLines: 2),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: valueC, decoration: const InputDecoration(labelText: 'Nilai (Rp)'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: contractDateC, decoration: const InputDecoration(labelText: 'Tgl Kontrak'), readOnly: true, onTap: () async {
                    final date = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (date != null) contractDateC.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  })),
                ]),
                const SizedBox(height: 12),
                const Text('Share (Role)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Wrap(spacing: 8, children: ['Teknisi'].map((r) => FilterChip(
                  label: Text(r, style: const TextStyle(fontSize: 13)),
                  selected: shareRoles.contains(r),
                  onSelected: (v) { setDialogState(() { if (v) shareRoles.add(r); else shareRoles.remove(r); }); },
                )).toList()),
                if (shareRoles.contains('Teknisi'))
                  CheckboxListTile(dense: true, title: const Text('Semua Teknisi', style: TextStyle(fontSize: 13)), value: allTeknisi,
                    onChanged: (v) => setDialogState(() => allTeknisi = v ?? false), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero),
                if (shareRoles.isNotEmpty && !allTeknisi) ...[
                  const SizedBox(height: 8),
                  const Text('Pilih Teknisi:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: ListView(shrinkWrap: true, children: allUsers.where((u) => u.role == 'Teknisi').map((u) => CheckboxListTile(
                      dense: true, title: Text('${u.name} (${u.username})', style: const TextStyle(fontSize: 12)),
                      value: assignedTo.contains(u.id),
                      onChanged: (v) { setDialogState(() { if (v == true) assignedTo.add(u.id); else assignedTo.remove(u.id); }); },
                      controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero,
                    )).toList()),
                  ),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<String>(value: status, isExpanded: true, decoration: const InputDecoration(labelText: 'Status'),
                    items: ['pending', 'progres', 'done'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setDialogState(() => status = v ?? 'pending'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: datelineC, decoration: const InputDecoration(labelText: 'Dateline'), readOnly: true, onTap: () async {
                    final date = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (date != null) datelineC.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  })),
                ]),
                if (pdfDocuments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: spektek.isEmpty ? null : spektek,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Referensi Dokumen (PDF)'),
                    items: pdfDocuments.map((d) => DropdownMenuItem(value: d.filePath, child: Text(d.namaDokumen, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setDialogState(() => spektek = v ?? ''),
                  ),
                ],
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: submitting ? null : () async {
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
                      if (editJob != null) {
                        await JobService.update(editJob.id, body);
                      } else {
                        await JobService.create(body);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      setDialogState(() => submitting = false);
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }, child: submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(editJob != null ? 'Simpan' : 'Tambah')),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );

    await _loadJobs();
  }

  Future<void> _deleteJob(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pekerjaan'),
        content: const Text('Yakin ingin menghapus pekerjaan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await JobService.delete(id);
      await _loadJobs();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _dateInput(String? date) {
    if (date == null || date.isEmpty) return '';
    return date.split('T').first;
  }

  Future<void> _shareJob(Job job) async {
    try {
      String token = job.shareToken ?? '';
      if (token.isEmpty) {
        final res = await JobService.generateShareLink(job.id);
        token = res['share_token'] as String;
      }
      final url = '${ApiService.baseUrl.replaceAll('/api', '')}/pekerjaan/shared/$token';
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link tersalin')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _completeJob(Job job) async {
    try {
      await JobService.complete(job.id);
      await _loadJobs();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pekerjaan selesai'), backgroundColor: Color(0xFF22C55E)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final perm = context.watch<PermissionProvider>();
    final isSuperAdmin = auth.user?.role == 'Super Admin';
    final role = auth.user?.role ?? '';
    final canCreate = perm.can('pekerjaan', 'create', isSuperAdmin: isSuperAdmin);
    final canEdit = perm.can('pekerjaan', 'edit', isSuperAdmin: isSuperAdmin);
    final canDelete = perm.can('pekerjaan', 'delete', isSuperAdmin: isSuperAdmin);

    final theme = Theme.of(context);

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadJobs,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF4F46E5).withOpacity(0.08), const Color(0xFF7C3AED).withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Data Pekerjaan', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Kelola daftar pekerjaan', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            if (canCreate)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => _showJobForm(),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add, color: Colors.white, size: 20),
                                          SizedBox(width: 6),
                                          Text('Tambah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: TextField(
                        controller: _searchC,
                        decoration: InputDecoration(
                          hintText: 'Cari pekerjaan...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchC.text.isNotEmpty
                              ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchC.clear(); _filter(''); })
                              : null,
                        ),
                        onChanged: _filter,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _filterStatus.isEmpty ? null : _filterStatus,
                              isExpanded: true,
                              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10), hintText: 'Semua Status'),
                              items: ['pending', 'progres', 'done'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) => setState(() { _filterStatus = v ?? ''; _applyFilters(); }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _filterShare.isEmpty ? null : _filterShare,
                              isExpanded: true,
                              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10), hintText: 'Semua Role'),
                              items: ['Teknisi', 'Logistic', 'Administrasi'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) => setState(() { _filterShare = v ?? ''; _applyFilters(); }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_filtered.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.work_off_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Tidak ada pekerjaan', style: TextStyle(color: Colors.grey.shade500)),
                            if (canCreate) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _showJobForm(),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Tambah Pekerjaan'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final job = _filtered[i];
                            return FadeSlideIn(
                              index: i,
                              child: _JobCard(
                                job: job,
                                userRole: role,
                                canEdit: canEdit,
                                canDelete: canDelete,
                                onTap: () async {
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)));
                                  _loadJobs();
                                },
                                onEdit: canEdit ? () => _showJobForm(editJob: job) : null,
                                onDelete: canDelete ? () => _deleteJob(job.id) : null,
                                onShare: () => _shareJob(job),
                                onComplete: role == 'Super Admin' || role == 'Administrasi' ? () => _completeJob(job) : null,
                                spektekUrl: job.spektek,
                              ),
                            );
                          },
                          childCount: _filtered.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final String? userRole;
  final bool canEdit, canDelete;
  final VoidCallback? onEdit, onDelete, onShare, onComplete;
  final String? spektekUrl;

  const _JobCard({
    required this.job, required this.onTap, this.userRole,
    this.canEdit = false, this.canDelete = false,
    this.onEdit, this.onDelete, this.onShare, this.onComplete,
    this.spektekUrl,
  });

  Color _statusColor() {
    switch (job.status) {
      case 'Selesai': case 'done': return const Color(0xFF22C55E);
      case 'Progres': case 'progres': return const Color(0xFF06B6D4);
      default: return const Color(0xFFEAB308);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: _statusColor().withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.construction_rounded, color: _statusColor(), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(job.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _statusColor().withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(job.status ?? 'Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor())),
                        ),
                      ],
                    ),
                    if (job.share != null) ...[
                      const SizedBox(height: 2),
                      Text('Share: ${job.share}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                    if (job.spektek != null && job.spektek!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf, size: 12, color: Colors.red.shade400),
                            const SizedBox(width: 4),
                            Text('SPEKTEK', style: TextStyle(fontSize: 10, color: Colors.red.shade400, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    if (userRole == 'Teknisi') ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _TaskColumn(label: 'Logistic', count: job.uncompletedLogistic, color: const Color(0xFFF59E0B)),
                          const SizedBox(width: 12),
                          _TaskColumn(label: 'Teknisi', count: job.uncompletedTeknisi, color: const Color(0xFF3B82F6)),
                        ],
                      ),
                    ],
                    if (userRole == 'Logistic' && job.uncompletedLogistic > 0) ...[
                      const SizedBox(height: 4),
                      _TaskColumn(label: 'Logistic', count: job.uncompletedLogistic, color: const Color(0xFFF59E0B)),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (v) {
                  if (v == 'detail') onTap();
                  if (v == 'edit') onEdit?.call();
                  if (v == 'delete') onDelete?.call();
                  if (v == 'share') onShare?.call();
                  if (v == 'complete') onComplete?.call();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'detail', child: ListTile(leading: Icon(Icons.visibility, size: 18), title: Text('Detail', style: TextStyle(fontSize: 13)), dense: true, contentPadding: EdgeInsets.zero)),
                  if (onShare != null) const PopupMenuItem(value: 'share', child: ListTile(leading: Icon(Icons.share, size: 18), title: Text('Bagikan', style: TextStyle(fontSize: 13)), dense: true, contentPadding: EdgeInsets.zero)),
                  if (onComplete != null) const PopupMenuItem(value: 'complete', child: ListTile(leading: Icon(Icons.check_circle, size: 18, color: Colors.green), title: Text('Selesaikan', style: TextStyle(fontSize: 13, color: Colors.green)), dense: true, contentPadding: EdgeInsets.zero)),
                  if (onEdit != null) const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit, size: 18), title: Text('Edit', style: TextStyle(fontSize: 13)), dense: true, contentPadding: EdgeInsets.zero)),
                  if (onDelete != null) const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, size: 18, color: Colors.red), title: Text('Hapus', style: TextStyle(fontSize: 13, color: Colors.red)), dense: true, contentPadding: EdgeInsets.zero)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskColumn extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _TaskColumn({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          const SizedBox(width: 6),
          Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}


