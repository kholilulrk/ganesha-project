import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import '../services/user_service.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});
  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Todo> _todos = [];
  List<User> _allUsers = [];
  bool _loading = true;
  String _filter = 'all';
  final _taskC = TextEditingController();
  int? _assignTo;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _taskC.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        TodoService.getAll(),
        UserService.getAll(),
      ]);
      if (mounted) {
        setState(() {
          _todos = results[0] as List<Todo>;
          _allUsers = results[1] as List<User>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Todo> get _filtered {
    if (_filter == 'pending') return _todos.where((t) => !t.isDone).toList();
    if (_filter == 'done') return _todos.where((t) => t.isDone).toList();
    return _todos;
  }

  int get _pendingCount => _todos.where((t) => !t.isDone).length;
  int get _doneCount => _todos.where((t) => t.isDone).length;

  String _userName(int id) {
    final u = _allUsers.cast<User?>().firstWhere(
      (u) => u!.id == id,
      orElse: () => null,
    );
    return u?.name ?? 'User #$id';
  }

  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return '';
    try {
      final dt = DateTime.parse(d);
      return '${dt.day} ${_months[dt.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  Future<void> _addTodo() async {
    final text = _taskC.text.trim();
    if (text.isEmpty) return;
    setState(() => _error = null);
    try {
      await TodoService.create(text, assignedTo: _assignTo);
      _taskC.clear();
      setState(() => _assignTo = null);
      await _loadAll();
    } catch (e) {
      setState(() => _error = 'Gagal menambah tugas');
    }
  }

  Future<void> _toggleTodo(int id) async {
    try {
      await TodoService.toggle(id);
      await _loadAll();
    } catch (e) {
      setState(() => _error = 'Gagal mengubah status');
    }
  }

  Future<void> _deleteTodo(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: const Text('Hapus tugas ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await TodoService.delete(id);
      await _loadAll();
    } catch (e) {
      setState(() => _error = 'Gagal menghapus tugas');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.user?.id ?? 0;
    final currentRole = auth.user?.role ?? '';
    final assignableUsers = _allUsers.where((u) => u.role != 'Super Admin').toList();
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
                  Text('To-do List', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Kelola tugas dan pekerjaan', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _taskC,
                          decoration: const InputDecoration(
                            hintText: 'Tambah tugas baru...',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onSubmitted: (_) => _addTodo(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: DropdownButtonFormField<int?>(
                          value: _assignTo,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Untuk saya', style: TextStyle(fontSize: 13))),
                            ...assignableUsers.map((u) => DropdownMenuItem(
                              value: u.id,
                              child: Text(u.name, style: const TextStyle(fontSize: 13)),
                            )),
                          ],
                          onChanged: (v) => setState(() => _assignTo = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _taskC.text.trim().isEmpty ? null : _addTodo,
                        icon: const Icon(Icons.add, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(label: 'Semua (${_todos.length})', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Pending ($_pendingCount)', selected: _filter == 'pending', onTap: () => setState(() => _filter = 'pending')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Selesai ($_doneCount)', selected: _filter == 'done', onTap: () => setState(() => _filter = 'done')),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          _filter == 'all' ? 'Belum ada tugas' : _filter == 'pending' ? 'Semua tugas selesai' : 'Belum ada tugas selesai',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAll,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final todo = _filtered[i];
                            final isCurrentUser = todo.assignedTo == currentUserId || todo.assignedTo == 0;
                            final creatorName = todo.createdBy == currentUserId ? 'Saya' : _userName(todo.createdBy);
                            final assigneeName = isCurrentUser ? 'saya' : _userName(todo.assignedTo);

                            final c = todo.isDone ? const Color(0xFF22C55E) : const Color(0xFF4F46E5);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [c.withOpacity(0.10), c.withOpacity(0.03)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(color: c.withOpacity(0.15)),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _toggleTodo(todo.id),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: todo.isDone ? const Color(0xFF22C55E) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: todo.isDone ? const Color(0xFF22C55E) : Colors.grey.shade400,
                                              width: 2,
                                            ),
                                          ),
                                          child: todo.isDone
                                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              todo.task,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                decoration: todo.isDone ? TextDecoration.lineThrough : null,
                                                color: todo.isDone ? Colors.grey.shade500 : Colors.grey.shade800,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text('dari $creatorName', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                                const Text(' · ', style: TextStyle(fontSize: 11, color: Color(0xFFBDBDBD))),
                                                Text('untuk $assigneeName', style: TextStyle(fontSize: 11, color: const Color(0xFF4F46E5))),
                                                const Text(' · ', style: TextStyle(fontSize: 11, color: Color(0xFFBDBDBD))),
                                                Text(_formatDate(todo.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
                                        onPressed: () => _deleteTodo(todo.id),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        splashRadius: 16,
                                      ),
                                    ],
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
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4F46E5) : const Color(0xFF4F46E5).withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF4F46E5) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
