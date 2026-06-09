import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/permission.dart';
import '../services/permission_service.dart';
import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});
  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  List<RoleCount> _roles = [];
  Map<String, List<String>> _allPermissions = {};
  String? _selectedRole;
  List<String> _editedPerms = [];
  bool _saving = false;
  bool _loading = true;
  String? _error;
  String? _success;

  static const _permissionGroups = [
    _PermGroup(label: 'Pekerjaan', resource: 'pekerjaan', actions: [
      _PermAction(value: 'view', label: 'Lihat'),
      _PermAction(value: 'create', label: 'Buat'),
      _PermAction(value: 'edit', label: 'Edit'),
      _PermAction(value: 'delete', label: 'Hapus'),
    ]),
    _PermGroup(label: 'Checklist', resource: 'checklist', actions: [
      _PermAction(value: 'manage', label: 'Kelola'),
    ]),
    _PermGroup(label: 'Pengguna', resource: 'users', actions: [
      _PermAction(value: 'manage', label: 'Kelola'),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        PermissionService.getRoles(),
        PermissionService.getAllPermissions(),
      ]);
      final roles = results[0] as List<RoleCount>;
      final perms = results[1] as List<Permission>;
      final grouped = <String, List<String>>{};
      for (final p in perms) {
        grouped.putIfAbsent(p.role, () => []).add(p.key);
      }
      if (mounted) {
        setState(() {
          _roles = roles;
          _allPermissions = grouped;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _savePermissions(String role) async {
    setState(() { _saving = true; _error = null; _success = null; });
    try {
      await PermissionService.update(role, _editedPerms);
      _allPermissions[role] = List.from(_editedPerms);
      context.read<PermissionProvider>().load();
      setState(() {
        _success = 'Izin untuk $role berhasil disimpan';
        _selectedRole = null;
        _saving = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  Future<void> _resetDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Izin'),
        content: const Text('Reset semua izin ke default?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await PermissionService.reset();
      context.read<PermissionProvider>().load();
      final perms = await PermissionService.getAllPermissions();
      final grouped = <String, List<String>>{};
      for (final p in perms) {
        grouped.putIfAbsent(p.role, () => []).add(p.key);
      }
      setState(() {
        _allPermissions = grouped;
        _success = 'Izin dikembalikan ke default';
        _selectedRole = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSuperAdmin = auth.user?.role == 'Super Admin';
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
                      Text('Atur Akses', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      if (isSuperAdmin)
                        TextButton(
                          onPressed: _resetDefaults,
                          child: const Text('Reset', style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Kelola izin akses per halaman untuk setiap role', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                        ),
                      if (_success != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(_success!, style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
                        ),
                      const SizedBox(height: 16),
                      ..._roles.map((role) => _buildRoleCard(role, isSuperAdmin)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(RoleCount role, bool isSuperAdmin) {
    final isExpanded = _selectedRole == role.role;
    final rolePerms = _allPermissions[role.role] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(role.role, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${role.count} user', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 16),
              ..._permissionGroups.map((group) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.label,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: group.actions.map((act) {
                        final key = '${group.resource}.${act.value}';
                        final checked = _editedPerms.contains(key);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: Checkbox(
                                value: checked,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _editedPerms.add(key);
                                    } else {
                                      _editedPerms.remove(key);
                                    }
                                  });
                                },
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(act.label, style: const TextStyle(fontSize: 13)),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              )),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _saving ? null : () => _savePermissions(role.role),
                    child: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan'),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isSuperAdmin
                      ? () {
                          setState(() {
                            _selectedRole = role.role;
                            _editedPerms = List.from(rolePerms);
                          });
                        }
                      : null,
                  child: const Text('Atur Akses'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermGroup {
  final String label;
  final String resource;
  final List<_PermAction> actions;
  const _PermGroup({required this.label, required this.resource, required this.actions});
}

class _PermAction {
  final String value;
  final String label;
  const _PermAction({required this.value, required this.label});
}
