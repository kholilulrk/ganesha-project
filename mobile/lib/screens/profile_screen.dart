import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameC = TextEditingController();
  final _usernameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _passwordC = TextEditingController();
  bool _loading = false;
  bool _photoLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncUserData());
  }

  void _syncUserData() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    if (_nameC.text != user.name) _nameC.text = user.name;
    if (_usernameC.text != user.username) _usernameC.text = user.username;
    final phone = user.phone ?? '';
    if (_phoneC.text != phone) _phoneC.text = phone;
  }

  @override
  void dispose() {
    _nameC.dispose();
    _usernameC.dispose();
    _phoneC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _photoLoading = true);
      try {
        await context.read<AuthProvider>().uploadPhoto(File(picked.path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto berhasil diupload'), backgroundColor: Color(0xFF22C55E)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal upload: $e'), backgroundColor: Colors.red),
          );
        }
      }
      if (mounted) setState(() => _photoLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    final name = _nameC.text.trim();
    final username = _usernameC.text.trim();
    final phone = _phoneC.text.trim();
    final password = _passwordC.text.trim();
    if (name.isEmpty && username.isEmpty && phone.isEmpty && password.isEmpty) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().updateProfile(
        name: name.isNotEmpty ? name : null,
        username: username.isNotEmpty ? username : null,
        phone: phone.isNotEmpty ? phone : null,
        password: password.isNotEmpty ? password : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diupdate'), backgroundColor: Color(0xFF22C55E)),
        );
        _nameC.clear();
        _syncUserData();
        _passwordC.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Silakan login')),
      );
    }

    final photoUrl = user.photo != null
        ? '${ApiService.baseUploadUrl}${user.photo}'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Pengaturan',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () {
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Photo section
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          user.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _photoLoading ? null : _pickPhoto,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _photoLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _InfoTile(icon: Icons.shield_outlined, label: 'Role', value: user.role, valueColor: const Color(0xFF4F46E5)),
          const SizedBox(height: 20),
          // Edit form
          Text('Edit Profil', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameC,
            decoration: const InputDecoration(
              labelText: 'Nama',
              hintText: 'Masukkan nama baru',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _usernameC,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'Masukkan username baru',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneC,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor Telepon',
              hintText: 'Masukkan nomor telepon',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordC,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password Baru',
              hintText: 'Kosongkan jika tidak diubah',
              prefixIcon: Icon(Icons.lock_outlined),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: valueColor ?? Colors.grey.shade800)),
            ],
          ),
        ],
      ),
    );
  }
}
