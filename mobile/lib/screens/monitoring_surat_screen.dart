import 'package:flutter/material.dart';
import '../models/surat.dart';
import '../services/surat_service.dart';

class MonitoringSuratScreen extends StatefulWidget {
  const MonitoringSuratScreen({super.key});
  @override
  State<MonitoringSuratScreen> createState() => _MonitoringSuratScreenState();
}

class _MonitoringSuratScreenState extends State<MonitoringSuratScreen> {
  List<Surat> _surats = [];
  bool _loading = true;
  String? _error;
  bool _showForm = false;
  bool _editing = false;
  int? _editId;

  final _namaC = TextEditingController();
  final _startC = TextEditingController();
  String _jenisSurat = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _namaC.dispose();
    _startC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _surats = await SuratService.getAll();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openForm([Surat? s]) {
    _editing = s != null;
    _editId = s?.id;
    _namaC.text = s?.namaSurat ?? '';
    _startC.text = s != null
        ? '${s.startAktif.year.toString().padLeft(4, '0')}-${s.startAktif.month.toString().padLeft(2, '0')}-${s.startAktif.day.toString().padLeft(2, '0')}'
        : '';
    _jenisSurat = s?.jenisSurat ?? '';
    setState(() => _showForm = true);
  }

  void _closeForm() {
    setState(() {
      _showForm = false;
      _editing = false;
      _editId = null;
      _namaC.clear();
      _startC.clear();
      _jenisSurat = '';
    });
  }

  Future<void> _submit() async {
    if (_namaC.text.isEmpty || _startC.text.isEmpty || _jenisSurat.isEmpty) return;
    try {
      if (_editing) {
        await SuratService.update(_editId!, {
          'nama_surat': _namaC.text,
          'start_aktif': _startC.text,
          'jenis_surat': _jenisSurat,
        });
      } else {
        await SuratService.create({
          'nama_surat': _namaC.text,
          'start_aktif': _startC.text,
          'jenis_surat': _jenisSurat,
        });
      }
      _closeForm();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Surat'),
        content: const Text('Yakin ingin menghapus surat ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await SuratService.delete(id);
      await _load();
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _load,
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
                                      Text('Monitoring Aktif Surat', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('Kelola surat aktif dan masa berlaku', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                    ],
                                  ),
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
                                      onTap: () => _openForm(),
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
                      if (_showForm)
                        SliverToBoxAdapter(
                          child: _buildForm(theme),
                        ),
                      if (_surats.isEmpty && !_showForm)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text('Belum ada surat', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => _openForm(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Tambah Surat'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final surat = _surats[index];
                                return _SuratCard(
                                  surat: surat,
                                  onEdit: () => _openForm(surat),
                                  onDelete: () => _delete(surat.id),
                                );
                              },
                              childCount: _surats.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                    child: Icon(_editing ? Icons.edit : Icons.add, color: const Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(_editing ? 'Edit Surat' : 'Tambah Surat', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _closeForm,
                    style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _namaC,
                decoration: const InputDecoration(labelText: 'Nama Surat', hintText: 'Nama surat'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _startC,
                decoration: const InputDecoration(
                  labelText: 'Start Aktif',
                  prefixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    _startC.text = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  }
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _jenisSurat.isEmpty ? null : _jenisSurat,
                decoration: const InputDecoration(labelText: 'Jenis Surat'),
                items: const [
                  DropdownMenuItem(value: 'SIK', child: Text('SIK (Surat Izin Kerja)')),
                  DropdownMenuItem(value: 'SC', child: Text('SC (Security Clearance)')),
                ],
                onChanged: (v) => setState(() => _jenisSurat = v ?? ''),
              ),
              if (_jenisSurat.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Masa berlaku: ${_jenisSurat == 'SIK' ? '1 bulan' : '3 bulan'} setelah tanggal aktif',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: _closeForm, child: const Text('Batal')),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _submit,
                    child: Text(_editing ? 'Simpan' : 'Tambah'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuratCard extends StatelessWidget {
  final Surat surat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SuratCard({
    required this.surat,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(DateTime d) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = surat.isExpired;
    final isExpiring = surat.isExpiring;

    Color? borderColor;
    List<Color>? gradientColors;
    if (isExpired) {
      gradientColors = [Colors.red.withOpacity(0.10), Colors.red.withOpacity(0.03)];
      borderColor = Colors.red.withOpacity(0.2);
    } else if (isExpiring) {
      gradientColors = [Colors.amber.withOpacity(0.12), Colors.amber.withOpacity(0.04)];
      borderColor = Colors.amber.withOpacity(0.3);
    } else {
      gradientColors = [const Color(0xFF4F46E5).withOpacity(0.08), const Color(0xFF4F46E5).withOpacity(0.02)];
      borderColor = Colors.grey.shade200;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: borderColor),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: surat.jenisSurat == 'SIK'
                            ? const Color(0xFF4F46E5).withOpacity(0.1)
                            : const Color(0xFF22C55E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        surat.jenisSurat,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: surat.jenisSurat == 'SIK'
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF22C55E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        surat.namaSurat,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isExpired ? Colors.grey : null,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (v) {
                        if (v == 'edit') onEdit();
                        if (v == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoItem(label: 'Start Aktif', value: _formatDate(surat.startAktif)),
                    const SizedBox(width: 20),
                    _InfoItem(label: 'Masa Berlaku', value: _formatDate(surat.masaBerlaku)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      surat.sisaWaktu,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isExpired ? Colors.red : isExpiring ? Colors.amber : null,
                      ),
                    ),
                    if (isExpired)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Kadaluarsa', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600)),
                      ),
                    if (isExpiring && !isExpired)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Segera', style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
