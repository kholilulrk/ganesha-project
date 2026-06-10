import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/document.dart';
import '../models/user.dart';
import '../services/document_service.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class DocumentManagementScreen extends StatefulWidget {
  const DocumentManagementScreen({super.key});
  @override
  State<DocumentManagementScreen> createState() => _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen> {
  List<Document> _documents = [];
  List<User> _allUsers = [];
  bool _loading = true;
  String? _error;
  String? _toast;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        DocumentService.getAll(),
        UserService.getAll(),
      ]);
      if (mounted) {
        setState(() {
          _documents = results[0] as List<Document>;
          _allUsers = results[1] as List<User>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _showForm({int? editId}) async {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    String tipeDokumen = '';
    String shareMode = 'all';
    List<int> sharedTo = [];
    File? selectedFile;
    bool submitting = false;

    if (editId != null) {
      final doc = _documents.firstWhere((d) => d.id == editId);
      nameC.text = doc.namaDokumen;
      descC.text = doc.deskripsi ?? '';
      tipeDokumen = doc.tipeDokumen;
      shareMode = doc.shareMode;
      if (doc.sharedTo != null && doc.sharedTo!.isNotEmpty) {
        sharedTo = doc.sharedTo!.split(',').map((s) => int.tryParse(s.trim()) ?? 0).where((id) => id > 0).toList();
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(editId != null ? 'Edit Dokumen' : 'Upload Dokumen',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameC,
                    decoration: const InputDecoration(labelText: 'Nama Dokumen', hintText: 'Nama dokumen'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: tipeDokumen.isEmpty ? null : tipeDokumen,
                    decoration: const InputDecoration(labelText: 'Tipe Dokumen'),
                    items: const [
                      DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                      DropdownMenuItem(value: 'Excel', child: Text('Excel')),
                      DropdownMenuItem(value: 'Word', child: Text('Word')),
                      DropdownMenuItem(value: 'JPG', child: Text('JPG')),
                      DropdownMenuItem(value: 'PNG', child: Text('PNG')),
                    ],
                    onChanged: (v) => setDialogState(() => tipeDokumen = v ?? ''),
                  ),
                  const SizedBox(height: 12),
                  if (editId != null) ...[
                    const Text('File Saat Ini', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        final doc = _documents.firstWhere((d) => d.id == editId);
                        final fileUrl = '${ApiService.baseUploadUrl}/${doc.filePath.replaceAll('\\', '/')}';
                        launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.description, size: 18, color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _documents.firstWhere((d) => d.id == editId).filePath.split('/').last,
                                style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.open_in_new, size: 16, color: Colors.blue.shade400),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Ganti File (opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                  ],
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'xls', 'xlsx', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
                      );
                      if (result != null && result.files.isNotEmpty) {
                        setDialogState(() => selectedFile = File(result.files.single.path!));
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            selectedFile != null ? selectedFile!.path.split('/').last : 'Pilih File',
                            style: TextStyle(color: selectedFile != null ? Colors.grey.shade800 : Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: descC, decoration: const InputDecoration(labelText: 'Deskripsi'), maxLines: 3),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: shareMode,
                    decoration: const InputDecoration(labelText: 'Bagikan ke'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Semua Role')),
                      DropdownMenuItem(value: 'specific', child: Text('Role Tertentu')),
                    ],
                    onChanged: (v) => setDialogState(() => shareMode = v ?? 'all'),
                  ),
                  if (shareMode == 'specific') ...[
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView(
                        shrinkWrap: true,
                        children: _allUsers.map((u) => CheckboxListTile(
                          dense: true,
                          title: Text('${u.name} (${u.username})', style: const TextStyle(fontSize: 13)),
                          subtitle: Text(u.role, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          value: sharedTo.contains(u.id),
                          onChanged: (v) {
                            setDialogState(() {
                              if (v == true) { sharedTo.add(u.id); } else { sharedTo.remove(u.id); }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        )).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: submitting ? null : () async {
                          if (nameC.text.trim().isEmpty || tipeDokumen.isEmpty) return;
                          if (editId == null && selectedFile == null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Pilih file terlebih dahulu')),
                            );
                            return;
                          }
                          setDialogState(() => submitting = true);
                          try {
                            if (editId != null) {
                              await DocumentService.update(editId, {
                                'nama_dokumen': nameC.text.trim(),
                                'tipe_dokumen': tipeDokumen,
                                'deskripsi': descC.text.trim(),
                                'share_mode': shareMode,
                                'shared_to': sharedTo.join(','),
                              }, file: selectedFile);
                            } else {
                              await DocumentService.create(selectedFile!, {
                                'nama_dokumen': nameC.text.trim(),
                                'tipe_dokumen': tipeDokumen,
                                'deskripsi': descC.text.trim(),
                                'share_mode': shareMode,
                                'shared_to': sharedTo.join(','),
                              });
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            setDialogState(() => submitting = false);
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        },
                        child: submitting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(editId != null ? 'Simpan' : 'Upload'),
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

    _showToast(editId != null ? 'Dokumen berhasil diperbarui' : 'Dokumen berhasil diupload');
    await _loadAll();
  }

  Future<void> _deleteDoc(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Dokumen'),
        content: const Text('Yakin ingin menghapus dokumen ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await DocumentService.delete(id);
      _showToast('Dokumen berhasil dihapus');
      await _loadAll();
    } catch (e) {
      setState(() => _error = 'Gagal menghapus data');
    }
  }

  Future<void> _showDetailPreview(Document doc) async {
    final fileUrl = '${ApiService.baseUploadUrl}/${doc.filePath.replaceAll('\\', '/')}';
    final isPdf = doc.tipeDokumen == 'PDF';
    final isImage = ['JPG', 'PNG'].contains(doc.tipeDokumen);

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: _tipeColor(doc.tipeDokumen).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(_tipeIcon(doc.tipeDokumen), color: _tipeColor(doc.tipeDokumen), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(doc.namaDokumen, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              _MetaRow(label: 'Tipe', value: doc.tipeDokumen),
              _MetaRow(label: 'Deskripsi', value: doc.deskripsi ?? '-'),
              _MetaRow(label: 'Bagikan ke', value: doc.shareMode == 'all' ? 'Semua Role' : doc.sharedTo ?? '-'),
              const SizedBox(height: 16),
              if (isPdf || isImage)
                SizedBox(
                  height: isPdf ? 120 : 250,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isImage
                        ? Image.network(fileUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                            child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                          ))
                        : Container(
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
                                  const SizedBox(height: 8),
                                  Text(
                                    doc.namaDokumen,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(_tipeIcon(doc.tipeDokumen), size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('Pratinjau tidak tersedia', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Buka File'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await Clipboard.setData(ClipboardData(text: fileUrl));
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Link file disalin!')),
                            );
                          }
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.link, size: 16),
                      label: const Text('Salin Link'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    setState(() {});
  }

  String _sharedToNames(String? sharedTo) {
    if (sharedTo == null || sharedTo.isEmpty) return '-';
    final ids = sharedTo.split(',').map((s) => int.tryParse(s.trim()) ?? 0).where((id) => id > 0).toList();
    return ids.map((id) {
      final u = _allUsers.cast<User?>().firstWhere((u) => u!.id == id, orElse: () => null);
      return u?.name ?? '#$id';
    }).join(', ');
  }

  Color _tipeColor(String tipe) {
    switch (tipe) {
      case 'PDF': return const Color(0xFFFF4D4D);
      case 'Excel': return const Color(0xFF22C55E);
      case 'Word': return const Color(0xFF4F46E5);
      case 'JPG': return const Color(0xFFEAB308);
      case 'PNG': return const Color(0xFFFF9F43);
      default: return Colors.grey;
    }
  }

  IconData _tipeIcon(String tipe) {
    switch (tipe) {
      case 'PDF': return Icons.picture_as_pdf;
      case 'Excel': return Icons.table_chart;
      case 'Word': return Icons.description;
      default: return Icons.image;
    }
  }

  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return '-';
    try {
      final dt = DateTime.parse(d);
      return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
    } catch (_) { return '-'; }
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

  @override
  Widget build(BuildContext context) {
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
                  Row(
                    children: [
                      Expanded(
                        child: Text('Dokumen', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ),
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
                            onTap: () => _showForm(),
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
                  const SizedBox(height: 4),
                  Text('Kelola dokumen pekerjaan', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadAll,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: _documents.length,
                          itemBuilder: (_, i) {
                            final doc = _documents[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _showDetailPreview(doc),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44, height: 44,
                                        decoration: BoxDecoration(
                                          color: _tipeColor(doc.tipeDokumen).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(_tipeIcon(doc.tipeDokumen), color: _tipeColor(doc.tipeDokumen), size: 22),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(doc.namaDokumen, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _tipeColor(doc.tipeDokumen).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(doc.tipeDokumen, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _tipeColor(doc.tipeDokumen))),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  doc.shareMode == 'all' ? 'Semua Role' : 'Selected',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.more_vert, size: 18),
                                        onSelected: (v) {
                                          if (v == 'edit') _showForm(editId: doc.id);
                                          if (v == 'delete') _deleteDoc(doc.id);
                                          if (v == 'download') {
                                            final fileUrl = '${ApiService.baseUploadUrl}/${doc.filePath.replaceAll('\\', '/')}';
                                            Clipboard.setData(ClipboardData(text: fileUrl));
                                            _showToast('Link file disalin');
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'download', child: ListTile(leading: Icon(Icons.download, size: 18), title: Text('Download', style: TextStyle(fontSize: 13)), dense: true, contentPadding: EdgeInsets.zero)),
                                          const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit, size: 18), title: Text('Edit', style: TextStyle(fontSize: 13)), dense: true, contentPadding: EdgeInsets.zero)),
                                          const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, size: 18, color: Colors.red), title: Text('Hapus', style: TextStyle(fontSize: 13, color: Colors.red)), dense: true, contentPadding: EdgeInsets.zero)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                if (_toast != null)
                  Positioned(
                    bottom: 24, left: 24, right: 24,
                    child: Material(
                      elevation: 4, borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(10)),
                        child: Text(_toast!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
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

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
