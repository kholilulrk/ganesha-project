import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vendor.dart';
import '../services/vendor_service.dart';
import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';

class VendorScreen extends StatefulWidget {
  const VendorScreen({super.key});
  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  List<Vendor> _vendors = [];
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
      final list = await VendorService.getAll();
      if (mounted) setState(() { _vendors = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _showVendorForm(Vendor? existing) async {
    final nameC = TextEditingController(text: existing?.name ?? '');
    final contactC = TextEditingController(text: existing?.contactPerson ?? '');
    final phoneC = TextEditingController(text: existing?.phone ?? '');
    final emailC = TextEditingController(text: existing?.email ?? '');
    final addressC = TextEditingController(text: existing?.address ?? '');
    final descC = TextEditingController(text: existing?.description ?? '');
    String? formError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(existing != null ? 'Edit Vendor' : 'Tambah Vendor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (formError != null)
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(formError!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                  ),
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Nama Perusahaan', hintText: 'Nama vendor')),
                const SizedBox(height: 12),
                TextField(controller: contactC, decoration: const InputDecoration(labelText: 'Kontak Person', hintText: 'Nama kontak')),
                const SizedBox(height: 12),
                TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Telepon', hintText: 'No telepon'), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email', hintText: 'Email'), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                TextField(controller: addressC, decoration: const InputDecoration(labelText: 'Alamat', hintText: 'Alamat lengkap'), maxLines: 2),
                const SizedBox(height: 12),
                TextField(controller: descC, decoration: const InputDecoration(labelText: 'Keterangan', hintText: 'Catatan tambahan'), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (nameC.text.trim().isEmpty) {
                  formError = 'Nama perusahaan wajib diisi';
                  return;
                }
                try {
                  final body = {
                    'name': nameC.text.trim(),
                    'contact_person': contactC.text.trim().isEmpty ? null : contactC.text.trim(),
                    'phone': phoneC.text.trim().isEmpty ? null : phoneC.text.trim(),
                    'email': emailC.text.trim().isEmpty ? null : emailC.text.trim(),
                    'address': addressC.text.trim().isEmpty ? null : addressC.text.trim(),
                    'description': descC.text.trim().isEmpty ? null : descC.text.trim(),
                  };
                  if (existing != null) {
                    await VendorService.update(existing.id, body);
                  } else {
                    await VendorService.create(body);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _load();
                } catch (e) {
                  formError = '$e';
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVendor(Vendor v) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Vendor'),
        content: Text('Yakin ingin menghapus "${v.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await VendorService.delete(v.id);
      await _load();
    } catch (_) {}
  }

  Future<void> _showPaymentTerms(Vendor v) async {
    List<PaymentTerm> terms = [];
    bool loadingTerms = true;
    String? termsError;

    final tcNumber = TextEditingController();
    final tcPercentage = TextEditingController();
    final tcAmount = TextEditingController();
    final tcDueDate = TextEditingController();
    final tcDescription = TextEditingController();
    bool editingTerm = false;
    int? editTermId;

    Future<void> loadTerms() async {
      try {
        terms = await VendorService.getPaymentTerms(v.id);
      } catch (e) {
        termsError = '$e';
      }
      loadingTerms = false;
    }

    await loadTerms();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> refreshTerms() async {
              try {
                final t = await VendorService.getPaymentTerms(v.id);
                setDialogState(() { terms = t; termsError = null; });
              } catch (e) {
                setDialogState(() => termsError = '$e');
              }
            }

            void resetTermForm() {
              editingTerm = false;
              editTermId = null;
              tcNumber.text = (terms.length + 1).toString();
              tcPercentage.text = '';
              tcAmount.text = '';
              tcDueDate.text = '';
              tcDescription.text = '';
            }

            return AlertDialog(
              title: Text('Termin — ${v.name}'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (termsError != null)
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(termsError!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                        ),
                      if (terms.isEmpty && !loadingTerms)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text('Belum ada termin pembayaran', style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ...terms.map((t) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Termin ${t.termNumber}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    if (t.percentage != null)
                                      Text('${t.percentage!.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    if (t.amount != null)
                                      Text('Rp ${t.amount!.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    if (t.dueDate != null)
                                      Text('Jatuh tempo: ${t.dueDate}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                    if (t.description != null && t.description!.isNotEmpty)
                                      Text(t.description!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade500),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                onPressed: () {
                                  setDialogState(() {
                                    editingTerm = true;
                                    editTermId = t.id;
                                    tcNumber.text = t.termNumber.toString();
                                    tcPercentage.text = t.percentage?.toStringAsFixed(0) ?? '';
                                    tcAmount.text = t.amount?.toStringAsFixed(0) ?? '';
                                    tcDueDate.text = t.dueDate ?? '';
                                    tcDescription.text = t.description ?? '';
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade300),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                onPressed: () async {
                                  await VendorService.deletePaymentTerm(v.id, t.id);
                                  await refreshTerms();
                                },
                              ),
                            ],
                          ),
                        )),
                      const Divider(),
                      Text(editingTerm ? 'Edit Termin' : 'Tambah Termin', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: tcNumber,
                              decoration: const InputDecoration(labelText: 'Termin ke-', isDense: true),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: tcPercentage,
                              decoration: const InputDecoration(labelText: 'Persentase (%)', isDense: true),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: tcAmount,
                              decoration: const InputDecoration(labelText: 'Jumlah (Rp)', isDense: true),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) tcDueDate.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Jatuh Tempo', isDense: true),
                                child: Text(tcDueDate.text.isEmpty ? 'Pilih' : tcDueDate.text, style: TextStyle(fontSize: 13, color: tcDueDate.text.isEmpty ? Colors.grey : null)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: tcDescription,
                        decoration: const InputDecoration(labelText: 'Keterangan', isDense: true),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setDialogState(resetTermForm),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                final body = {
                                  'term_number': int.tryParse(tcNumber.text) ?? 1,
                                  'percentage': double.tryParse(tcPercentage.text),
                                  'amount': double.tryParse(tcAmount.text),
                                  'due_date': tcDueDate.text.isEmpty ? null : tcDueDate.text,
                                  'description': tcDescription.text.isEmpty ? null : tcDescription.text,
                                };
                                if (editingTerm && editTermId != null) {
                                  await VendorService.updatePaymentTerm(v.id, editTermId!, body);
                                } else {
                                  await VendorService.createPaymentTerm(v.id, body);
                                }
                                resetTermForm();
                                await refreshTerms();
                              } catch (e) {
                                setDialogState(() => termsError = '$e');
                              }
                            },
                            child: const Text(editingTerm ? 'Simpan' : 'Tambah'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
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
    final canCreate = perm.can('vendor', 'create', isSuperAdmin: isSuperAdmin);
    final canEdit = perm.can('vendor', 'edit', isSuperAdmin: isSuperAdmin);
    final canDelete = perm.can('vendor', 'delete', isSuperAdmin: isSuperAdmin);

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vendor', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Data vendor dan termin pembayaran', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                  if (canCreate)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF4F46E5)),
                      onPressed: () => _showVendorForm(null),
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
                    : _vendors.isEmpty
                        ? const Center(child: Text('Belum ada vendor'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _vendors.length,
                              itemBuilder: (_, i) {
                                final v = _vendors[i];
                                final jobName = v.job?['name'] ?? '-';
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
                                              child: Text(v.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.payments_outlined, size: 18),
                                                  color: const Color(0xFF10B981),
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(4),
                                                  onPressed: () => _showPaymentTerms(v),
                                                ),
                                                if (canEdit)
                                                  IconButton(
                                                    icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade500),
                                                    constraints: const BoxConstraints(),
                                                    padding: const EdgeInsets.all(4),
                                                    onPressed: () => _showVendorForm(v),
                                                  ),
                                                if (canDelete)
                                                  IconButton(
                                                    icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300),
                                                    constraints: const BoxConstraints(),
                                                    padding: const EdgeInsets.all(4),
                                                    onPressed: () => _deleteVendor(v),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        _infoRow(Icons.person_outline, v.contactPerson ?? '-'),
                                        _infoRow(Icons.phone_outlined, v.phone ?? '-'),
                                        _infoRow(Icons.email_outlined, v.email ?? '-'),
                                        _infoRow(Icons.work_outline, jobName),
                                        if (v.address != null && v.address!.isNotEmpty)
                                          _infoRow(Icons.location_on_outlined, v.address!),
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

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
