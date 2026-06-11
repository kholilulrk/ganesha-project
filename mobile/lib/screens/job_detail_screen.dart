import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import '../models/job.dart';
import '../models/checklist_item.dart';
import '../services/checklist_service.dart';
import '../services/job_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import '../utils/format.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;
  const JobDetailScreen({super.key, required this.job});
  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabC;
  List<ChecklistItem> _teknisi = [];
  List<ChecklistItem> _logistic = [];
  List<dynamic> _comments = [];
  List<dynamic> _assignedUsers = [];
  bool _loading = true;
  String? _error;
  int _seenCommentCount = 0;
  bool _hasTeknisi = true;
  bool _hasLogistic = true;
  Timer? _timer;
  bool _isLoadingAll = false;

  final _tekSearch = TextEditingController();
  final _logSearch = TextEditingController();
  final _tekInput = TextEditingController();
  final _logNama = TextEditingController();
  final _logQty = TextEditingController();
  final _logUnit = TextEditingController();
  final _logNotes = TextEditingController();
  final _logHarga = TextEditingController();
  final _picker = ImagePicker();
  String? _previewUrl;
  int? _editingItemId;
  final _editC = TextEditingController();
  final _editFormQty = TextEditingController();
  final _editFormUnit = TextEditingController();
  final _editFormNotes = TextEditingController();
  final _editFormHarga = TextEditingController();

  // Comment
  final _commentInputC = TextEditingController();
  final _replyC = TextEditingController();
  int? _replyParentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final user = context.read<AuthProvider>().user;
    final role = user?.role ?? '';
    final shared = widget.job.sharedRoles;
    _hasTeknisi = role == 'Administrasi' || role == 'Super Admin' || shared.contains('Teknisi');
    _hasLogistic = role == 'Super Admin' || role == 'Teknisi' || shared.contains('Logistic');
    final tabCount = 1 + (_hasTeknisi ? 1 : 0) + (_hasLogistic ? 1 : 0) + 1;
    _tabC = TabController(length: tabCount, vsync: this);
    _loadAll();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadAll());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _timer?.cancel();
      _timer = null;
    } else if (state == AppLifecycleState.resumed) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadAll());
      _loadAll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabC.dispose();
    _tekSearch.dispose();
    _logSearch.dispose();
    _tekInput.dispose();
    _logNama.dispose();
    _logQty.dispose();
    _logUnit.dispose();
    _logNotes.dispose();
    _logHarga.dispose();
    _editC.dispose();
    _editFormQty.dispose();
    _editFormUnit.dispose();
    _editFormNotes.dispose();
    _editFormHarga.dispose();
    _commentInputC.dispose();
    _replyC.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (_isLoadingAll) return;
    _isLoadingAll = true;
    setState(() => _loading = true);
    try {
      if (_hasTeknisi) {
        final tek = await ChecklistService.getItems(widget.job.id, 'Teknisi');
        _teknisi = tek;
      }
      if (_hasLogistic) {
        final log = await ChecklistService.getItems(widget.job.id, 'Logistic');
        _logistic = log;
      }
      final commentsData = await JobService.getComments(widget.job.id);
      _comments = commentsData;
      if (mounted) {
        setState(() { _loading = false; _error = null; });
      }
    } on TimeoutException {
      if (mounted) setState(() { _error = 'Koneksi terputus. Periksa internet Anda.'; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    } finally {
      _isLoadingAll = false;
    }
  }

  bool get _hasNewComments => _comments.length > _seenCommentCount;

  List<int> _tabOrder() {
    final order = <int>[3];
    if (_hasTeknisi) order.add(0);
    if (_hasLogistic) order.add(1);
    order.add(2);
    return order;
  }

  List<ChecklistItem> _filteredTek() {
    final q = _tekSearch.text.toLowerCase().trim();
    if (q.isEmpty) return _teknisi;
    return _teknisi.where((i) => i.item.toLowerCase().contains(q)).toList();
  }

  List<ChecklistItem> _filteredLog() {
    final q = _logSearch.text.toLowerCase().trim();
    if (q.isEmpty) return _logistic;
    return _logistic.where((i) => i.item.toLowerCase().contains(q)).toList();
  }

  Map<String, int> _progress(List<ChecklistItem> items) {
    final total = items.length;
    final done = items.where((i) => i.isDone).length;
    final pct = total > 0 ? (done * 100 / total).round() : 0;
    return {'total': total, 'done': done, 'pct': pct};
  }

  bool get _canManage {
    final auth = context.read<AuthProvider>();
    final perm = context.read<PermissionProvider>();
    return perm.can('checklist', 'manage', isSuperAdmin: auth.user?.role == 'Super Admin');
  }

  void _openWA(String? phone) {
    if (phone == null || phone.isEmpty) return;
    final num = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = num.startsWith('0')
        ? 'https://wa.me/62${num.substring(1)}'
        : 'https://wa.me/$num';
    launchUrl(Uri.parse(url));
  }

  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return '-';
    try {
      final dt = DateTime.parse(d);
      return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '-';
    }
  }

  Future<File> _compressImage(File file) async {
    final size = await file.length();
    if (size < 1024 * 1024) return file;
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return file;
      final resized = img.copyResize(image, width: 1920, height: 1080);
      final compressed = img.encodeJpg(resized, quality: 50);
      final dir = (await getTemporaryDirectory()).path;
      final name = DateTime.now().millisecondsSinceEpoch.toString();
      final outFile = File('$dir/$name.jpg');
      await outFile.writeAsBytes(compressed);
      if (await outFile.length() < size) return outFile;
    } catch (_) {}
    return file;
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  void _updateItemLocal(int id, String newStatus, bool newCompleted) {
    void update(List<ChecklistItem> list) {
      final idx = list.indexWhere((i) => i.id == id);
      if (idx == -1) return;
      list[idx] = ChecklistItem(
        id: list[idx].id,
        jobId: list[idx].jobId,
        role: list[idx].role,
        item: list[idx].item,
        completed: newCompleted,
        status: newStatus,
        images: list[idx].images,
        quantity: list[idx].quantity,
        unit: list[idx].unit,
        notes: list[idx].notes,
        price: list[idx].price,
      );
    }
    update(_teknisi);
    update(_logistic);
    setState(() {});
  }

  Future<void> _progresItem(int id) async {
    try {
      await ChecklistService.progres(widget.job.id, id);
      _updateItemLocal(id, 'progres', false);
      if (widget.job.status == 'pending') {
        try {
          await JobService.updateStatus(widget.job.id, 'progres');
        } catch (_) {}
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _selesaiItem(int id) async {
    try {
      await ChecklistService.selesai(widget.job.id, id);
      _updateItemLocal(id, 'selesai', true);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _addTeknisi() async {
    final text = _tekInput.text.trim();
    if (text.isEmpty) return;
    try {
      await ChecklistService.addItem(widget.job.id, {
        'role': 'Teknisi',
        'item': text,
      });
      _tekInput.clear();
      await _loadAll();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _toggleLogistic(int id) async {
    try {
      await ChecklistService.toggleItem(widget.job.id, id);
      final item = _logistic.firstWhere((i) => i.id == id);
      final newCompleted = !item.completed;
      _updateItemLocal(id, newCompleted ? 'selesai' : 'pending', newCompleted);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _addLogistic() async {
    if (_logNama.text.trim().isEmpty) return;
    try {
      await ChecklistService.addItem(widget.job.id, {
        'role': 'Logistic',
        'item': _logNama.text.trim(),
        'quantity': int.tryParse(_logQty.text) ?? 0,
        'unit': _logUnit.text.trim(),
        'notes': _logNotes.text.trim(),
        'price': double.tryParse(_logHarga.text) ?? 0,
      });
      _logNama.clear();
      _logQty.clear();
      _logUnit.clear();
      _logNotes.clear();
      _logHarga.clear();
      await _loadAll();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _pickImages(String role, int itemId) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pilih Sumber', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    final List<XFile> picked;
    if (source == ImageSource.camera) {
      final single = await _picker.pickImage(source: ImageSource.camera);
      picked = single != null ? [single] : [];
    } else {
      picked = await _picker.pickMultiImage();
    }
    if (picked.isEmpty) return;
    final item = role == 'teknisi'
        ? _teknisi.firstWhere((i) => i.id == itemId)
        : _logistic.firstWhere((i) => i.id == itemId);
    final maxImages = role == 'teknisi' ? 2 : 1;
    final existing = item.imageList.length;
    final allowed = maxImages - existing;
    if (allowed <= 0) {
      _showError(role == 'teknisi' ? 'Maksimal 2 gambar' : 'Maksimal 1 gambar');
      return;
    }
    final toUpload = picked.take(allowed).toList();
    try {
      for (final x in toUpload) {
        final compressed = await _compressImage(File(x.path));
        await ChecklistService.uploadImage(widget.job.id, itemId, role, compressed);
      }
      await _loadAll();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _deleteImage(String role, int itemId, String filename) async {
    try {
      await ChecklistService.deleteImage(widget.job.id, itemId, filename);
      await _loadAll();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _startEdit(ChecklistItem item) {
    _editingItemId = item.id;
    _editC.text = item.item;
    _editFormQty.text = item.quantity.toString();
    _editFormUnit.text = item.unit;
    _editFormNotes.text = item.notes;
    _editFormHarga.text = item.price.toString();
    setState(() {});
  }

  Future<void> _saveTekEdit(int id) async {
    try {
      await ChecklistService.updateItem(widget.job.id, id, {'item': _editC.text.trim()});
      _editingItemId = null;
      await _loadAll();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _saveLogEdit(int id) async {
    try {
      await ChecklistService.updateItem(widget.job.id, id, {
        'item': _editC.text.trim(),
        'quantity': int.tryParse(_editFormQty.text) ?? 0,
        'unit': _editFormUnit.text.trim(),
        'notes': _editFormNotes.text.trim(),
        'price': double.tryParse(_editFormHarga.text) ?? 0,
      });
      _editingItemId = null;
      await _loadAll();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _deleteItem(String role, int id) async {
    try {
      await ChecklistService.deleteItem(widget.job.id, id);
      await _loadAll();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _addComment() async {
    final text = _commentInputC.text.trim();
    if (text.isEmpty) return;
    try {
      final user = context.read<AuthProvider>().user;
      await JobService.addComment(widget.job.id, {
        'text': text,
        'name': user?.name ?? '',
      });
      _commentInputC.clear();
      await _loadAll();
      _seenCommentCount = _comments.length;
    } catch (e) {
      _showError('Gagal menambah komentar');
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      await JobService.deleteComment(widget.job.id, commentId);
      await _loadAll();
    } catch (e) {
      _showError('Gagal menghapus komentar');
    }
  }

  Future<void> _addReply(int parentId) async {
    final text = _replyC.text.trim();
    if (text.isEmpty) return;
    try {
      final user = context.read<AuthProvider>().user;
      await JobService.addComment(widget.job.id, {
        'text': text,
        'name': user?.name ?? '',
        'parent_id': parentId,
      });
      _replyC.clear();
      _replyParentId = null;
      await _loadAll();
    } catch (e) {
      _showError('Gagal mengirim balasan');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage = _canManage;
    final auth = context.read<AuthProvider>();
    final role = auth.user?.role ?? '';
    final canSelesaikan = role == 'Super Admin' || role == 'Administrasi';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.job.name, style: const TextStyle(fontSize: 16)),
        bottom: _loading
            ? null
            : TabBar(
                controller: _tabC,
                tabs: _tabOrder().map((t) {
                  if (t == 3) return const Tab(text: 'Detail');
                  if (t == 2) {
                    return Tab(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Komentar'),
                            if (_hasNewComments)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Tab(text: t == 0 ? 'Teknisi' : 'Logistic');
                }).toList(),
                onTap: (i) {
                  if (_tabOrder()[i] == 2) {
                    _seenCommentCount = _comments.length;
                    setState(() {});
                  }
                },
              ),
      ),
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: Colors.grey)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadAll,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabC,
                    children: _tabOrder().map((t) {
                      if (t == 3) return _buildDetailTab(canSelesaikan: canSelesaikan);
                      if (t == 0) return _buildTeknisiTab(canManage);
                      if (t == 1) return _buildLogisticTab(canManage);
                      return _buildKomentarTab();
                    }).toList(),
                  ),
                ),
              ],
            ),
          if (_previewUrl != null)
            _ImagePreviewOverlay(
              url: _previewUrl!,
              onClose: () => setState(() => _previewUrl = null),
            ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() => _loadAll();

  Widget _buildDetailTab({bool canSelesaikan = false}) {
    final theme = Theme.of(context);
    final job = widget.job;
    final user = context.watch<AuthProvider>().user;
    final isTeknisiLogistic = user?.role == 'Teknisi' || user?.role == 'Logistic';

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(job.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      _StatusPill(
                        text: job.status ?? 'pending',
                        color: job.status == 'selesai' || job.status == 'done'
                            ? const Color(0xFF22C55E)
                            : job.status == 'progres'
                                ? const Color(0xFF06B6D4)
                                : const Color(0xFFEAB308),
                      ),
                    ],
                  ),
                  if (job.description != null && job.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(job.description!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (!isTeknisiLogistic)
                        _InfoChip(label: 'Nilai', value: formatRupiah(job.value)),
                      if (!isTeknisiLogistic) const SizedBox(width: 12),
                      if (!isTeknisiLogistic)
                        _InfoChip(label: 'Kontrak', value: _formatDate(job.contractDate)),
                      if (!isTeknisiLogistic) const SizedBox(width: 12),
                      _InfoChip(label: 'Dateline', value: _formatDate(job.dateline)),
                    ],
                  ),
                  if (!isTeknisiLogistic && _logistic.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(children: [
                      _InfoChip(
                        label: 'Total Belanja',
                        value:
                            formatRupiah(_logistic.fold<double>(0, (s, i) => s + i.quantity * i.price)),
                      ),
                    ]),
                  ],
                  if (_assignedUsers.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    const Text('Teknisi:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _assignedUsers.map((u) {
                        return _WAContact(
                          name: u['name'] ?? '',
                          onTap: () => _openWA(u['phone']),
                        );
                      }).toList(),
                    ),
                  ],
                  if (job.spektek != null && job.spektek!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    const Text('Dokumen Referensi:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        final url = '${ApiService.baseUploadUrl}/${job.spektek!.replaceAll('\\', '/')}';
                        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf, size: 18, color: Colors.red.shade400),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                job.spektek!.split('/').last.split('\\').last,
                                style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButtons(canSelesaikan: canSelesaikan),
        ],
      ),
      ),
    );
  }

  bool _isAllChecklistsDone() {
    final all = [..._teknisi, ..._logistic];
    if (all.isEmpty) return false;
    return all.every((item) => item.isDone);
  }

  Widget _buildActionButtons({bool canSelesaikan = false}) {
    final done = _isAllChecklistsDone();
    final isCompleted = widget.job.status == 'selesai' || widget.job.status == 'done';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (!isCompleted && canSelesaikan)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: done ? _confirmComplete : null,
                icon: const Icon(Icons.check_circle, size: 18),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Selesaikan Pekerjaan'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: done ? const Color(0xFF22C55E) : null,
                ),
              ),
            ),
          if (!isCompleted && canSelesaikan) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _shareLink,
              icon: const Icon(Icons.share, size: 18),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Bagikan Link'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmComplete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Selesaikan Pekerjaan'),
        content: const Text('Yakin ingin menyelesaikan pekerjaan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Selesaikan')),
        ],
      ),
    );
    if (confirm == true) {
      _completeJob();
    }
  }

  Future<void> _completeJob() async {
    try {
      await JobService.complete(widget.job.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pekerjaan selesai!'), backgroundColor: Color(0xFF22C55E)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _shareLink() async {
    try {
      final result = await JobService.generateShareLink(widget.job.id);
      final token = result['share_token'] as String? ?? '';
      if (token.isNotEmpty) {
        final url = '${ApiService.baseUrl.replaceAll('/api', '')}/pekerjaan/shared/$token';
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link tersalin'), backgroundColor: Color(0xFF4F46E5)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildTeknisiTab(bool canManage) {
    final p = _progress(_teknisi);
    return Column(
      children: [
        _ProgressBar(done: p['done']!, total: p['total']!, pct: p['pct']!, color: const Color(0xFF4F46E5)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _tekSearch,
            decoration: InputDecoration(
              hintText: 'Cari tugas teknisi...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: _filteredTek().isEmpty
                ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: Center(child: Text('Belum ada tugas', style: TextStyle(color: Colors.grey.shade500))),
                    ),
                  ])
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTek().length,
                  itemBuilder: (_, i) => _TeknisiCard(
                    item: _filteredTek()[i],
                    canManage: canManage,
                    isEditing: _editingItemId == _filteredTek()[i].id,
                    editC: _editC,
                    onProgres: () => _progresItem(_filteredTek()[i].id),
                    onSelesai: () => _selesaiItem(_filteredTek()[i].id),
                    onPickImage: () => _pickImages('teknisi', _filteredTek()[i].id),
                    onDeleteImage: (f) => _deleteImage('teknisi', _filteredTek()[i].id, f),
                    onPreview: (url) => setState(() => _previewUrl = url),
                    onStartEdit: () => _startEdit(_filteredTek()[i]),
                    onSaveEdit: () => _saveTekEdit(_filteredTek()[i].id),
                    onCancelEdit: () => setState(() => _editingItemId = null),
                    onDelete: () => _deleteItem('teknisi', _filteredTek()[i].id),
                  ),
                ),
              ),
        ),
        if (canManage && _editingItemId == null)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tekInput,
                    decoration: InputDecoration(
                      hintText: 'Tambah tugas teknisi...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => _addTeknisi(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addTeknisi,
                  icon: const Icon(Icons.add, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLogisticTab(bool canManage) {
    final p = _progress(_logistic);
    return Column(
      children: [
        _ProgressBar(done: p['done']!, total: p['total']!, pct: p['pct']!, color: const Color(0xFF22C55E)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _logSearch,
            decoration: InputDecoration(
              hintText: 'Cari tugas logistic...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: _filteredLog().isEmpty
                ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: Center(child: Text('Belum ada tugas', style: TextStyle(color: Colors.grey.shade500))),
                    ),
                  ])
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredLog().length,
                  itemBuilder: (_, i) => _LogisticCard(
                    item: _filteredLog()[i],
                    canManage: canManage,
                    isEditing: _editingItemId == _filteredLog()[i].id,
                    editC: _editC,
                    editQtyC: _editFormQty,
                    editUnitC: _editFormUnit,
                    editNotesC: _editFormNotes,
                    editHargaC: _editFormHarga,
                    onToggle: () => _toggleLogistic(_filteredLog()[i].id),
                    onPickImage: () => _pickImages('logistic', _filteredLog()[i].id),
                    onDeleteImage: (f) => _deleteImage('logistic', _filteredLog()[i].id, f),
                    onPreview: (url) => setState(() => _previewUrl = url),
                    onStartEdit: () => _startEdit(_filteredLog()[i]),
                    onSaveEdit: () => _saveLogEdit(_filteredLog()[i].id),
                    onCancelEdit: () => setState(() => _editingItemId = null),
                    onDelete: () => _deleteItem('logistic', _filteredLog()[i].id),
                  ),
                ),
              ),
        ),
        if (canManage && _editingItemId == null)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _logNama,
                  decoration: const InputDecoration(hintText: 'Nama barang', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _logQty, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Jumlah', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _logUnit, decoration: const InputDecoration(hintText: 'Satuan', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _logNotes, decoration: const InputDecoration(hintText: 'Catatan', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _logHarga, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Harga', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addLogistic,
                      icon: const Icon(Icons.add, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildKomentarTab() {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;
    final topComments = _comments.where((c) => c['parent_id'] == null).toList();

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
              if (topComments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('Belum ada komentar', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ),
              ...topComments.map((c) {
                final cId = c['ID'] as int? ?? 0;
                final replies = _comments.where((r) => r['parent_id'] == cId).toList();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                                child: Text(
                                  ((c['name']?.toString().isNotEmpty == true) ? c['name']!.toString()[0] : '?').toUpperCase(),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              const Spacer(),
                              Text(_formatDate(c['CreatedAt']), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              if (user != null && c['user_id'] == user.id) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _deleteComment(cId),
                                  child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(c['text'] ?? '', style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => setState(() => _replyParentId = _replyParentId == cId ? null : cId),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 28), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: Text('Balas', style: TextStyle(fontSize: 12, color: Colors.blue.shade600)),
                          ),
                          if (_replyParentId == cId) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _replyC,
                                    decoration: const InputDecoration(hintText: 'Tulis balasan...', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(onPressed: () => _addReply(cId), child: const Text('Kirim')),
                              ],
                            ),
                          ],
                          if (replies.isNotEmpty) ...[
                            const Divider(height: 16),
                            ...replies.map((r) => Padding(
                              padding: const EdgeInsets.only(left: 16, top: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.grey.shade200,
                                    child: Text(
                                      ((r['name']?.toString().isNotEmpty == true) ? r['name']!.toString()[0] : '?').toUpperCase(),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(_formatDate(r['CreatedAt']), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(r['text'] ?? '', style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentInputC,
                  decoration: const InputDecoration(
                    hintText: 'Tulis komentar...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addComment,
                icon: const Icon(Icons.send, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Reusable Widgets ───

class _ProgressBar extends StatelessWidget {
  final int done, total, pct;
  final Color color;
  const _ProgressBar({required this.done, required this.total, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text('$done/$total \u00B7 $pct%',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? done / total : 0,
                backgroundColor: Colors.grey.shade200,
                color: color,
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label, value;
  const _InfoChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _WAContact extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _WAContact({required this.name, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💬', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5),
      ),
    );
  }
}

// ─── Teknisi Card ───

class _TeknisiCard extends StatelessWidget {
  final ChecklistItem item;
  final bool canManage;
  final bool isEditing;
  final TextEditingController editC;
  final VoidCallback onProgres;
  final VoidCallback onSelesai;
  final VoidCallback onPickImage;
  final void Function(String) onDeleteImage;
  final void Function(String) onPreview;
  final VoidCallback onStartEdit;
  final VoidCallback onSaveEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onDelete;

  const _TeknisiCard({
    required this.item, required this.canManage, required this.isEditing, required this.editC,
    required this.onProgres, required this.onSelesai, required this.onPickImage,
    required this.onDeleteImage, required this.onPreview, required this.onStartEdit,
    required this.onSaveEdit, required this.onCancelEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (item.isDone)
                  _StatusPill(text: 'Selesai', color: const Color(0xFF22C55E))
                else if (item.status == 'progres')
                  _ActionBadge(text: 'Selesaikan', color: const Color(0xFF06B6D4), onTap: onSelesai)
                else
                  _ActionBadge(text: 'Kerjakan', color: const Color(0xFFEAB308), onTap: onProgres),
                const SizedBox(width: 10),
                Expanded(
                  child: isEditing
                      ? TextField(
                          controller: editC, autofocus: true,
                          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                          onSubmitted: (_) => onSaveEdit(),
                        )
                      : Text(
                          item.item,
                          style: TextStyle(
                            decoration: item.isDone ? TextDecoration.lineThrough : null,
                            color: item.isDone ? Colors.grey.shade500 : Colors.grey.shade800,
                          ),
                        ),
                ),
              ],
            ),
            if (item.imageList.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ImageList(images: item.imageList, canDelete: canManage, onTap: onPreview, onDelete: onDeleteImage),
            ],
            if (canManage) ...[
              const SizedBox(height: 8),
              _ActionRow(
                isEditing: isEditing,
                onEdit: isEditing ? onSaveEdit : onStartEdit,
                onImage: onPickImage,
                onDelete: onDelete,
                onCancel: onCancelEdit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Logistic Card ───

class _LogisticCard extends StatelessWidget {
  final ChecklistItem item;
  final bool canManage;
  final bool isEditing;
  final TextEditingController editC, editQtyC, editUnitC, editNotesC, editHargaC;
  final VoidCallback onToggle, onPickImage, onStartEdit, onSaveEdit, onCancelEdit, onDelete;
  final void Function(String) onDeleteImage, onPreview;

  const _LogisticCard({
    required this.item, required this.canManage, required this.isEditing,
    required this.editC, required this.editQtyC, required this.editUnitC,
    required this.editNotesC, required this.editHargaC,
    required this.onToggle, required this.onPickImage, required this.onDeleteImage,
    required this.onPreview, required this.onStartEdit, required this.onSaveEdit,
    required this.onCancelEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: item.completed,
                  onChanged: (_) => onToggle(),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  activeColor: const Color(0xFF22C55E),
                ),
                Expanded(
                  child: isEditing
                      ? TextField(
                          controller: editC, autofocus: true,
                          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                        )
                      : Text(
                          item.item,
                          style: TextStyle(
                            decoration: item.isDone ? TextDecoration.lineThrough : null,
                            color: item.isDone ? Colors.grey.shade500 : Colors.grey.shade800,
                          ),
                        ),
                ),
              ],
            ),
            if (!isEditing && (item.quantity > 0 || item.notes.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 4),
                child: Text(
                  '${item.quantity} ${item.unit} \u00B7 ${formatRupiah(item.price)}${item.notes.isNotEmpty ? ' \u00B7 ${item.notes}' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            if (isEditing) ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: editQtyC, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Jumlah', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)))),
                const SizedBox(width: 6),
                Expanded(child: TextField(controller: editUnitC, decoration: const InputDecoration(hintText: 'Satuan', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: TextField(controller: editNotesC, decoration: const InputDecoration(hintText: 'Catatan', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)))),
                const SizedBox(width: 6),
                Expanded(child: TextField(controller: editHargaC, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Harga', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)))),
              ]),
            ],
            if (item.imageList.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ImageList(images: item.imageList, canDelete: canManage, onTap: onPreview, onDelete: onDeleteImage),
            ],
            if (canManage) ...[
              const SizedBox(height: 8),
              _ActionRow(
                isEditing: isEditing,
                onEdit: isEditing ? onSaveEdit : onStartEdit,
                onImage: onPickImage,
                onDelete: onDelete,
                onCancel: onCancelEdit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───

class _ActionBadge extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;
  const _ActionBadge({required this.text, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3),
        ),
      ),
    );
  }
}

class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _SmallIconBtn({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onEdit, onImage, onDelete, onCancel;
  const _ActionRow({required this.isEditing, required this.onEdit, required this.onImage, required this.onDelete, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SmallIconBtn(icon: isEditing ? Icons.check : Icons.edit_outlined, onTap: onEdit),
        const SizedBox(width: 6),
        _SmallIconBtn(icon: Icons.image_outlined, onTap: onImage),
        const SizedBox(width: 6),
        _SmallIconBtn(icon: Icons.delete_outline, color: Colors.red.shade400, onTap: onDelete),
        if (isEditing) ...[
          const SizedBox(width: 6),
          _SmallIconBtn(icon: Icons.close, color: Colors.grey, onTap: onCancel),
        ],
      ],
    );
  }
}

class _ImageList extends StatelessWidget {
  final List<String> images;
  final bool canDelete;
  final void Function(String) onTap, onDelete;
  const _ImageList({required this.images, required this.canDelete, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6, runSpacing: 6,
      children: images.map((img) {
        final url = '${ApiService.baseUploadUrl}/uploads/checklist/$img';
        return _ImageThumb(url: url, canDelete: canDelete, onTap: () => onTap(url), onDelete: () => onDelete(img));
      }).toList(),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final String url;
  final bool canDelete;
  final VoidCallback onTap, onDelete;
  const _ImageThumb({required this.url, required this.canDelete, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url, width: 48, height: 48, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48, height: 48, color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, size: 20),
              ),
            ),
          ),
          if (canDelete)
            Positioned(
              top: -4, right: -4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImagePreviewOverlay extends StatelessWidget {
  final String url;
  final VoidCallback onClose;
  const _ImagePreviewOverlay({required this.url, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.black87),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        onPressed: onClose,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final response = await http.get(Uri.parse(url));
                    if (response.statusCode == 200) {
                      final dir = await getTemporaryDirectory();
                      final name = url.split('/').last;
                      final file = File('${dir.path}/$name');
                      await file.writeAsBytes(response.bodyBytes);
                      await Gal.putImage(file.path, album: 'Ganesha');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gambar disimpan ke galeri'),
                            backgroundColor: Color(0xFF22C55E),
                          ),
                        );
                      }
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal menyimpan gambar'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
