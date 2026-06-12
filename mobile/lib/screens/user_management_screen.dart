import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import '../widgets/animated_entry.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = [];
  bool _loading = true;
  String? _error;
  String? _toast;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await UserService.getAll();
      if (mounted) setState(() { _users = users; _loading = false; });
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
    final usernameC = TextEditingController();
    final phoneC = TextEditingController();
    final passwordC = TextEditingController();
    String role = '';
    bool submitting = false;

    final roleOptions = ['Administrasi', 'Teknisi', 'Logistic'];

    if (editId != null) {
      final u = _users.firstWhere((u) => u.id == editId);
      nameC.text = u.name;
      usernameC.text = u.username;
      phoneC.text = u.phone ?? '';
      role = u.role;
    }

    final result = await showDialog<bool>(
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        editId != null ? 'Edit Pengguna' : 'Tambah Pengguna',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Nama')),
                  const SizedBox(height: 12),
                  TextField(controller: usernameC, decoration: const InputDecoration(labelText: 'Username')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role.isEmpty ? null : role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: roleOptions
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => role = v ?? ''),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Nomor Telepon')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordC,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: editId != null ? 'Password (kosongkan jika tidak diganti)' : 'Password',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                if (nameC.text.trim().isEmpty || usernameC.text.trim().isEmpty || role.isEmpty) return;
                                if (editId == null && passwordC.text.trim().length < 6) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('Password minimal 6 karakter')),
                                  );
                                  return;
                                }
                                setDialogState(() => submitting = true);
                                try {
                                  final body = <String, dynamic>{
                                    'name': nameC.text.trim(),
                                    'username': usernameC.text.trim(),
                                    'role': role,
                                    'phone': phoneC.text.trim(),
                                  };
                                  if (passwordC.text.trim().isNotEmpty) body['password'] = passwordC.text.trim();
                                  if (editId != null) {
                                    await UserService.update(editId, body);
                                  } else {
                                    await UserService.create(body);
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx, true);
                                } catch (e) {
                                  setDialogState(() => submitting = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              },
                        child: submitting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(editId != null ? 'Simpan' : 'Tambah'),
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

    if (result == true) {
      _showToast(editId != null ? 'Pengguna berhasil diperbarui' : 'Pengguna berhasil ditambahkan');
      await _loadUsers();
    }
  }

  Future<void> _deleteUser(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pengguna'),
        content: const Text('Yakin ingin menghapus pengguna ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await UserService.delete(id);
      _showToast('Pengguna berhasil dihapus');
      await _loadUsers();
    } catch (e) {
      setState(() => _error = 'Gagal menghapus data');
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Super Admin': return const Color(0xFFFF6B6B);
      case 'Administrasi': return const Color(0xFF4F46E5);
      case 'Teknisi': return const Color(0xFFEAB308);
      case 'Logistic': return const Color(0xFF22C55E);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final perm = context.watch<PermissionProvider>();
    final isSuperAdmin = auth.user?.role == 'Super Admin';
    final canView = perm.can('users', 'view', isSuperAdmin: isSuperAdmin);
    final canCreate = perm.can('users', 'create', isSuperAdmin: isSuperAdmin);
    final canEdit = perm.can('users', 'edit', isSuperAdmin: isSuperAdmin);
    final canDelete = perm.can('users', 'delete', isSuperAdmin: isSuperAdmin);
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pengguna', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      if (canCreate)
                        IconButton(
                          icon: const Icon(Icons.person_add_rounded),
                          onPressed: () => _showForm(),
                          tooltip: 'Tambah Pengguna',
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Kelola data pengguna', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
              children: [
                Column(
                  children: [
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _users.length,
                          itemBuilder: (_, i) {
                            final u = _users[i];
                            final rc = _roleColor(u.role);
                            return FadeSlideIn(index: i,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [rc.withOpacity(0.10), rc.withOpacity(0.03)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: _roleColor(u.role).withOpacity(0.1),
                                        child: Text(u.name[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: _roleColor(u.role))),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Text('@${u.username}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(color: _roleColor(u.role).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                                    child: Text(u.role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _roleColor(u.role)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  ),
                                                ),
                                                if (u.phone != null && u.phone!.isNotEmpty) ...[
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(u.phone!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (canEdit || canDelete)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (canEdit)
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 20),
                                                onPressed: () => _showForm(editId: u.id),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                splashRadius: 18,
                                              ),
                                            if (canDelete)
                                              IconButton(
                                                icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                                                onPressed: () => _deleteUser(u.id),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                splashRadius: 18,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                if (_toast != null)
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(10),
                        ),
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
