import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/announcement.dart';
import '../services/announcement_service.dart';
import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';

class PengumumanScreen extends StatefulWidget {
  const PengumumanScreen({super.key});
  @override
  State<PengumumanScreen> createState() => _PengumumanScreenState();
}

class _PengumumanScreenState extends State<PengumumanScreen> {
  List<Announcement> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await AnnouncementService.getAll();
      if (mounted) setState(() { _list = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  String _statusLabel(Announcement a) {
    final now = DateTime.now();
    if (!a.isActive) return 'Nonaktif';
    if (now.isBefore(a.startAt)) return 'Terjadwal';
    if (now.isAfter(a.endAt)) return 'Kadaluarsa';
    return 'Aktif';
  }

  Color _statusColor(Announcement a) {
    final now = DateTime.now();
    if (!a.isActive) return Colors.grey;
    if (now.isBefore(a.startAt)) return const Color(0xFF4F46E5);
    if (now.isAfter(a.endAt)) return Colors.red;
    return const Color(0xFF22C55E);
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _toggle(Announcement a) async {
    try {
      await AnnouncementService.toggle(a.id);
      await _load();
    } catch (_) {}
  }

  Future<void> _delete(Announcement a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pengumuman'),
        content: Text('Hapus "${a.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AnnouncementService.delete(a.id);
      await _load();
    } catch (_) {}
  }

  Future<void> _showForm(Announcement? existing) async {
    final titleC = TextEditingController(text: existing?.title ?? '');
    final contentC = TextEditingController(text: existing?.content ?? '');
    DateTime? startAt = existing?.startAt;
    DateTime? endAt = existing?.endAt;
    String? formError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing != null ? 'Edit Pengumuman' : 'Tambah Pengumuman'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (formError != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(formError!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                      ),
                    TextField(
                      controller: titleC,
                      decoration: const InputDecoration(labelText: 'Judul', hintText: 'Judul pengumuman'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentC,
                      decoration: const InputDecoration(labelText: 'Konten', hintText: 'Isi pengumuman'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startAt ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) setDialogState(() => startAt = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Mulai'),
                              child: Text(startAt != null ? _formatDate(startAt!) : 'Pilih tanggal'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endAt ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) setDialogState(() => endAt = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Selesai'),
                              child: Text(endAt != null ? _formatDate(endAt!) : 'Pilih tanggal'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    if (titleC.text.trim().isEmpty) {
                      setDialogState(() => formError = 'Judul wajib diisi');
                      return;
                    }
                    if (startAt == null || endAt == null) {
                      setDialogState(() => formError = 'Tanggal mulai dan selesai wajib diisi');
                      return;
                    }
                    if (endAt!.isBefore(startAt!)) {
                      setDialogState(() => formError = 'Tanggal akhir harus setelah tanggal mulai');
                      return;
                    }
                    try {
                      final body = {
                        'title': titleC.text.trim(),
                        'content': contentC.text.trim(),
                        'start_at': _formatDate(startAt!),
                        'end_at': _formatDate(endAt!),
                      };
                      if (existing != null) {
                        await AnnouncementService.update(existing.id, body);
                      } else {
                        await AnnouncementService.create(body);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _load();
                    } catch (e) {
                      setDialogState(() => formError = '$e');
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perm = context.watch<PermissionProvider>();
    final isSuperAdmin = context.watch<AuthProvider>().user?.role == 'Super Admin';
    final canCreate = perm.can('pengumuman', 'create', isSuperAdmin: isSuperAdmin);
    final canEdit = perm.can('pengumuman', 'edit', isSuperAdmin: isSuperAdmin);
    final canDelete = perm.can('pengumuman', 'delete', isSuperAdmin: isSuperAdmin);

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF4F46E5).withOpacity(0.08), const Color(0xFF7C3AED).withOpacity(0.05)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pengumuman', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  if (canCreate)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF4F46E5)),
                      onPressed: () => _showForm(null),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: TextStyle(color: Colors.red.shade700)))
                    : _list.isEmpty
                        ? const Center(child: Text('Belum ada pengumuman'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _list.length,
                              itemBuilder: (_, i) {
                                final a = _list[i];
                                final statusColor = _statusColor(a);
                                final statusLabel = _statusLabel(a);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(a.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                                            ),
                                          ],
                                        ),
                                        if (a.content != null && a.content!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(a.content!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.date_range, size: 12, color: Colors.grey.shade400),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${_formatDate(a.startAt)} — ${_formatDate(a.endAt)}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                            ),
                                            const Spacer(),
                                            if (canEdit)
                                              IconButton(
                                                icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade500),
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                                onPressed: () => _showForm(a),
                                              ),
                                            if (canEdit)
                                              IconButton(
                                                icon: Icon(
                                                  a.isActive ? Icons.visibility : Icons.visibility_off,
                                                  size: 18, color: Colors.grey.shade500,
                                                ),
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                                onPressed: () => _toggle(a),
                                              ),
                                            if (canDelete)
                                              IconButton(
                                                icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300),
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                                onPressed: () => _delete(a),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
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
