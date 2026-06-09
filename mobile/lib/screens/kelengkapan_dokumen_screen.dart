import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job.dart';
import '../services/job_service.dart';
import '../services/job_document_service.dart';
import '../services/api_service.dart';

class DocType {
  final String key;
  final String label;
  final String format;
  final List<String> extensions;
  const DocType(this.key, this.label, this.format, this.extensions);
}

const docTypes = [
  DocType('SIK', 'SIK (Surat Izin Kerja)', 'PDF', ['.pdf']),
  DocType('SPK', 'SPK (Surat Perintah Kerja)', 'PDF', ['.pdf']),
  DocType('SPEKTEK', 'SPEKTEK (Spesifikasi Data Teknis)', 'PDF / Excel', ['.pdf', '.xls', '.xlsx']),
  DocType('SPH', 'SPH (Surat Penawaran Harga)', 'PDF / Excel', ['.pdf', '.xls', '.xlsx']),
  DocType('BAST', 'BAST (Berita Acara Serah Terima)', 'PDF', ['.pdf']),
  DocType('BA_MULAI', 'BA Mulai', 'PDF', ['.pdf']),
];

const verifSteps = [
  ('VERIFIKASI_I', 'Verifikasi I'),
  ('VERIFIKASI_II', 'Verifikasi II'),
  ('VERIFIKASI_III', 'Verifikasi III'),
  ('SEA_TRIAL', 'Sea Trial'),
];

const progressOptions = [
  'Pembuatan SPH', 'Pengajuan SPH', 'SPH disetujui', 'DP',
  'Survey Pekerjaan', 'Pembongkaran', 'Verifikasi I', 'Pembelian Material',
  'Proses Perbaikan', 'Verifikasi II', 'Pemasangan Material', 'Uji Coba',
  'Verifikasi III', 'Penagihan Pelunasan', 'Lunas',
];

class KelengkapanDokumenScreen extends StatefulWidget {
  const KelengkapanDokumenScreen({super.key});
  @override
  State<KelengkapanDokumenScreen> createState() => _KelengkapanDokumenScreenState();
}

class _KelengkapanDokumenScreenState extends State<KelengkapanDokumenScreen> {
  List<Job> _jobs = [];
  int? _selectedJobId;
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _verifications = [];
  String _progress = '';
  String _tdm = '';
  String _tds = '';
  bool _loadingJobs = true;
  bool _loadingDocs = false;
  String? _uploadingDocType;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      _jobs = await JobService.getJobs();
    } catch (_) {}
    if (mounted) setState(() => _loadingJobs = false);
  }

  Future<void> _loadDocuments() async {
    if (_selectedJobId == null) return;
    setState(() => _loadingDocs = true);
    try {
      final data = await JobDocumentService.getDocuments(_selectedJobId!);
      _documents = (data['documents'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      _verifications = (data['verifications'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      _progress = data['progress'] as String? ?? '';
      _tdm = data['tdm'] as String? ?? '';
      _tds = data['tds'] as String? ?? '';
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loadingDocs = false);
  }

  Map<String, dynamic>? _getDocument(String type) {
    try {
      return _documents.firstWhere((d) => d['doc_type'] == type);
    } catch (_) {
      return null;
    }
  }

  bool _getVerification(String step) {
    try {
      final v = _verifications.firstWhere((v) => v['step'] == step);
      return v['checked'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _uploadDocument(String docType) async {
    final dt = docTypes.firstWhere((d) => d.key == docType);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: dt.extensions.map((e) => e.replaceFirst('.', '')).toList(),
    );
    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.single.path!);
    setState(() => _uploadingDocType = docType);
    try {
      await JobDocumentService.uploadDocument(_selectedJobId!, file.path, docType);
      await _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${dt.label} berhasil diupload'), backgroundColor: const Color(0xFF22C55E)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _uploadingDocType = null);
  }

  Future<void> _deleteDocument(String docType) async {
    final doc = _getDocument(docType);
    if (doc == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Dokumen'),
        content: const Text('Yakin ingin menghapus dokumen ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await JobDocumentService.deleteDocument(_selectedJobId!, doc['id']);
      await _loadDocuments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleVerification(String step, bool checked) async {
    try {
      await JobDocumentService.toggleVerification(_selectedJobId!, step, checked);
      await _loadDocuments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateProgress(String? val) async {
    if (val == null) return;
    try {
      await JobDocumentService.updateProgress(_selectedJobId!, val);
      setState(() => _progress = val);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _previewDocument(Map<String, dynamic> doc) {
    final fileUrl = '${ApiService.baseUploadUrl}/${(doc['file_path'] as String? ?? '').replaceAll('\\', '/')}';
    launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
  }

  Future<void> _pickJobDate(String field) async {
    final current = field == 'tdm' ? _tdm : _tds;
    DateTime initial;
    try {
      initial = current.isNotEmpty ? DateTime.parse(current) : DateTime.now();
    } catch (_) {
      initial = DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null || !mounted) return;
    final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    try {
      await JobDocumentService.updateDocDates(
        _selectedJobId!,
        tdm: field == 'tdm' ? formatted : null,
        tds: field == 'tds' ? formatted : null,
      );
      if (mounted) setState(() {
        if (field == 'tdm') _tdm = formatted;
        if (field == 'tds') _tds = formatted;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kelengkapan Dokumen', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Kelola dokumen dan progres pekerjaan', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: DropdownButtonFormField<int>(
                value: _selectedJobId,
                decoration: InputDecoration(
                  labelText: 'Pilih Pekerjaan',
                  prefixIcon: const Icon(Icons.work_outline, size: 20),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                items: _loadingJobs
                    ? null
                    : _jobs.map((j) => DropdownMenuItem(value: j.id, child: Text(j.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) {
                  setState(() => _selectedJobId = v);
                  _loadDocuments();
                },
              ),
            ),
          ),
          if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ),
            ),
          if (_selectedJobId != null && !_loadingDocs) ...[
            // Document upload section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.upload_file, color: Color(0xFF4F46E5), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Dokumen Unggahan', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.4,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final dt = docTypes[index];
                    final doc = _getDocument(dt.key);
                    final isUploading = _uploadingDocType == dt.key;
                    return _DocCard(
                      docType: dt,
                      document: doc,
                      isUploading: isUploading,
                      onUpload: () => _uploadDocument(dt.key),
                      onDelete: () => _deleteDocument(dt.key),
                      onPreview: doc != null ? () => _previewDocument(doc!) : null,
                    );
                  },
                  childCount: docTypes.length,
                ),
              ),
            ),
            // Verification section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified, color: Color(0xFF22C55E), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Verifikasi', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 3.2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final v = verifSteps[index];
                    final checked = _getVerification(v.$1);
                    return _VerifChip(
                      label: v.$2,
                      checked: checked,
                      onToggle: (val) => _toggleVerification(v.$1, val),
                    );
                  },
                  childCount: verifSteps.length,
                ),
              ),
            ),
              // Progress section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.trending_up, color: Color(0xFF06B6D4), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('Progres Pekerjaan', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _progress.isEmpty ? null : _progress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.menu, size: 20),
                      ),
                      items: progressOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: _updateProgress,
                    ),
                  ],
                ),
              ),
            ),
            // TDM / TDS section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_month, color: Color(0xFF4F46E5), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('Tanggal Dokumen', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _DateField(
                          label: 'TDM (Masuk)',
                          value: _tdm,
                          onTap: () => _pickJobDate('tdm'),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _DateField(
                          label: 'TDS (Selesai)',
                          value: _tds,
                          onTap: () => _pickJobDate('tds'),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_selectedJobId != null && _loadingDocs)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final DocType docType;
  final Map<String, dynamic>? document;
  final bool isUploading;
  final VoidCallback onUpload;
  final VoidCallback onDelete;
  final VoidCallback? onPreview;

  const _DocCard({
    required this.docType,
    this.document,
    required this.isUploading,
    required this.onUpload,
    required this.onDelete,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDoc = document != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasDoc ? const Color(0xFF22C55E).withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(docType.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                    child: Text(docType.format, style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const Spacer(),
              if (hasDoc) ...[
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: Color(0xFF22C55E)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(document!['file_name'] ?? '', style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (onPreview != null)
                      InkWell(
                        onTap: onPreview,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.remove_red_eye, size: 14, color: Colors.grey.shade500),
                        ),
                      ),
                    InkWell(
                      onTap: onDelete,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.close, size: 14, color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              SizedBox(
                width: double.infinity,
                height: 32,
                child: isUploading
                    ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                    : OutlinedButton(
                        onPressed: hasDoc ? onUpload : onUpload,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: hasDoc ? const Color(0xFF4F46E5).withOpacity(0.3) : Colors.grey.shade300),
                        ),
                        child: Text(
                          hasDoc ? 'Ganti' : 'Upload',
                          style: TextStyle(fontSize: 12, color: hasDoc ? const Color(0xFF4F46E5) : Colors.grey.shade600),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifChip extends StatelessWidget {
  final String label;
  final bool checked;
  final ValueChanged<bool> onToggle;
  const _VerifChip({required this.label, required this.checked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!checked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: checked ? const Color(0xFF22C55E).withOpacity(0.08) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: checked ? const Color(0xFF22C55E).withOpacity(0.4) : Colors.grey.shade200,
            width: checked ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              checked ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: checked ? const Color(0xFF22C55E) : Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: checked ? FontWeight.w600 : FontWeight.normal,
                color: checked ? const Color(0xFF22C55E) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _DateField({required this.label, required this.value, this.onTap});

  String _fmt(String d) {
    if (d.isEmpty) return '';
    try {
      final dt = DateTime.parse(d);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) { return d; }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue ? const Color(0xFF4F46E5).withOpacity(0.06) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasValue ? const Color(0xFF4F46E5).withOpacity(0.3) : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: hasValue ? const Color(0xFF4F46E5) : Colors.grey.shade400),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasValue ? _fmt(value) : label,
                style: TextStyle(
                  fontSize: 13,
                  color: hasValue ? const Color(0xFF4F46E5) : Colors.grey.shade500,
                  fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: onTap,
                child: Icon(Icons.edit, size: 14, color: const Color(0xFF4F46E5).withOpacity(0.5)),
              ),
          ],
        ),
      ),
    );
  }
}
