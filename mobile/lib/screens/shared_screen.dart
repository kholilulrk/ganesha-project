import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job.dart';
import '../services/job_service.dart';
import '../services/api_service.dart';

class SharedScreen extends StatefulWidget {
  final String token;
  const SharedScreen({super.key, required this.token});
  @override
  State<SharedScreen> createState() => _SharedScreenState();
}

class _SharedScreenState extends State<SharedScreen> {
  Job? _job;
  List<dynamic> _teknisiItems = [];
  List<dynamic> _comments = [];
  List<dynamic> _assignedUsers = [];
  bool _loading = true;
  String? _error;

  final _nameC = TextEditingController();
  final _commentC = TextEditingController();
  final _replyC = TextEditingController();
  int? _replyParentId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _commentC.dispose();
    _replyC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await JobService.getShared(widget.token);
      if (mounted) {
        setState(() {
          _job = Job.fromJson(res['job'] as Map<String, dynamic>);
          _teknisiItems = (res['teknisi_items'] as List<dynamic>?) ?? [];
          _comments = (res['comments'] as List<dynamic>?) ?? [];
          _assignedUsers = (res['assigned_users'] as List<dynamic>?) ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Link tidak valid'; _loading = false; });
    }
  }

  void _openWA(String? phone) {
    if (phone == null || phone.isEmpty) return;
    final num = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = num.startsWith('0')
        ? 'https://wa.me/62${num.substring(1)}'
        : 'https://wa.me/$num';
    // ignore: deprecated_member_use
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Membuka WhatsApp: $url')),
    );
  }

  int tekProgressTotal() => _teknisiItems.length;
  int tekProgressDone() =>
      _teknisiItems.where((i) => i['status'] == 'selesai' || i['completed'] == true).length;
  int tekProgressPct() {
    final t = tekProgressTotal();
    return t > 0 ? (tekProgressDone() * 100 / t).round() : 0;
  }

  List<dynamic> _topComments() =>
      _comments.where((c) => c['parent_id'] == null).toList();

  List<dynamic> _replies(int parentId) =>
      _comments.where((c) => c['parent_id'] == parentId).toList();

  Future<void> _addComment() async {
    final name = _nameC.text.trim();
    final text = _commentC.text.trim();
    if (name.isEmpty || text.isEmpty) return;
    try {
      await JobService.addCommentShared(widget.token, {'name': name, 'text': text});
      _nameC.clear();
      _commentC.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim komentar')),
        );
      }
    }
  }

  Future<void> _addReply(int parentId) async {
    final text = _replyC.text.trim();
    if (text.isEmpty) return;
    try {
      await JobService.addCommentShared(widget.token, {
        'name': _nameC.text.trim().isNotEmpty ? _nameC.text.trim() : 'Anonymous',
        'text': text,
        'parent_id': parentId,
      });
      _replyC.clear();
      _replyParentId = null;
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim balasan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pekerjaan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('Link tidak valid atau sudah tidak berlaku.',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _job?.name ?? '',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusPill(
                            text: _job?.status ?? 'pending',
                            color: _job?.status == 'selesai' || _job?.status == 'done'
                                ? const Color(0xFF22C55E)
                                : _job?.status == 'progres'
                                    ? const Color(0xFF06B6D4)
                                    : const Color(0xFFEAB308),
                          ),
                        ],
                      ),
                      if (_assignedUsers.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Kontak Teknisi:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _assignedUsers.map((u) {
                            return GestureDetector(
                              onTap: () => _openWA(u['phone']),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('💬', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                    Text(
                                      u['name'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Description
                      if (_job?.description != null && _job!.description!.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Deskripsi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                                const SizedBox(height: 4),
                                Text(_job!.description!),
                              ],
                            ),
                          ),
                        ),
                      // Spektek document
                      if (_job?.spektek != null && _job!.spektek!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Referensi Dokumen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () {
                                    final path = _job!.spektek!.replaceAll('\\', '/');
                                    final url = path.startsWith('uploads/')
                                        ? '${ApiService.baseUploadUrl}/$path'
                                        : '${ApiService.baseUploadUrl}/uploads/spektek/$path';
                                    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.picture_as_pdf, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text('Lihat Dokumen',
                                          style: TextStyle(color: Colors.blue.shade600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_teknisiItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('Tugas Teknisi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const Spacer(),
                                    Text('${tekProgressDone()}/${tekProgressTotal()} \u00B7 ${tekProgressPct()}%',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: tekProgressTotal() > 0 ? tekProgressDone() / tekProgressTotal() : 0,
                                    backgroundColor: Colors.grey.shade200,
                                    color: const Color(0xFF4F46E5),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...(_teknisiItems).map((item) {
                                  final isDone = item['status'] == 'selesai' || item['completed'] == true;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['item'] ?? '',
                                            style: TextStyle(
                                              decoration: isDone ? TextDecoration.lineThrough : null,
                                              color: isDone ? Colors.grey : null,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _StatusPill(
                                          text: isDone
                                              ? 'Selesai'
                                              : item['status'] == 'progres'
                                                  ? 'Progres'
                                                  : 'Pending',
                                          color: isDone
                                              ? const Color(0xFF22C55E)
                                              : item['status'] == 'progres'
                                                  ? const Color(0xFF06B6D4)
                                                  : const Color(0xFFEAB308),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                      // Comments
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Komentar (${_comments.length})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 12),
                              ..._topComments().map((c) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(c['name'] ?? '',
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(_formatDate(c['CreatedAt']),
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(c['text'] ?? '', style: const TextStyle(fontSize: 14)),
                                      const SizedBox(height: 4),
                                      TextButton(
                                        onPressed: () => setState(() => _replyParentId = _replyParentId == c['id'] ? null : c['id']),
                                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 28), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                        child: Text('Balas', style: TextStyle(fontSize: 12, color: Colors.blue.shade600)),
                                      ),
                                      if (_replyParentId == c['id']) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _replyC,
                                                decoration: const InputDecoration(
                                                  hintText: 'Tulis balasan...',
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton(
                                              onPressed: () => _addReply(c['id']),
                                              child: const Text('Kirim'),
                                            ),
                                          ],
                                        ),
                                      ],
                                      // Replies
                                      ..._replies(c['id']).map((r) {
                                        return Padding(
                                          padding: const EdgeInsets.only(left: 20, top: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(r['name'] ?? '',
                                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(_formatDate(r['CreatedAt']),
                                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(r['text'] ?? '', style: const TextStyle(fontSize: 13)),
                                            ],
                                          ),
                                        );
                                      }),
                                      if (_replies(c['id']).isNotEmpty) const Divider(height: 1),
                                    ],
                                  ),
                                );
                              }),
                              if (_topComments().isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: Text('Belum ada komentar',
                                        style: TextStyle(color: Colors.grey.shade500)),
                                  ),
                                ),
                              const Divider(height: 16),
                              TextField(
                                controller: _nameC,
                                decoration: const InputDecoration(
                                  hintText: 'Nama Anda',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _commentC,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Tulis komentar...',
                                  contentPadding: EdgeInsets.all(12),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: _addComment,
                                  child: const Text('Kirim'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _formatDate(String? d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d);
      return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return d;
    }
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
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
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
