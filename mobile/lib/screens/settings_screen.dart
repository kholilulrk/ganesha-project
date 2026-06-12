import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../services/app_update_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppUpdateInfo? _updateInfo;
  String _currentVersion = '';
  bool _checkingUpdate = true;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final user = context.read<AuthProvider>().user;
        if (user != null) {
          context.read<SettingsProvider>().loadBiometricForUser(user.username);
        }
      }
    });
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;
    } catch (_) {}
    try {
      _updateInfo = await AppUpdateService.checkUpdate();
    } catch (_) {}
    if (mounted) setState(() => _checkingUpdate = false);
  }

  bool get _hasUpdate {
    if (_updateInfo == null) return false;
    if (!_updateInfo!.hasDownloadUrl) return false;
    final latest = _updateInfo!.latestVersion;
    return latest.compareTo(_currentVersion) > 0;
  }

  Future<void> _openDownloadUrl() async {
    if (_updateInfo == null || !_updateInfo!.hasDownloadUrl) return;
    final uri = Uri.tryParse(_updateInfo!.downloadUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka link download: $e')),
        );
      }
    }
  }

  void _showEnrollmentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EnrollmentDialog(
        username: context.read<AuthProvider>().user?.username ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = theme.mode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Keamanan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(settings.biometricEnabled ? Icons.fingerprint : Icons.lock_outline),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Login Sidik Jari', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(settings.biometricEnabled ? 'Aktif' : 'Nonaktif', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(settings.biometricEnabled ? Icons.close : Icons.fingerprint, size: 20),
                      label: Text(settings.biometricEnabled ? 'Nonaktifkan' : 'Aktifkan'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: settings.biometricEnabled ? Colors.red.shade300 : Colors.grey.shade300),
                        foregroundColor: settings.biometricEnabled ? Colors.red : null,
                      ),
                      onPressed: () {
                if (settings.biometricEnabled) {
                  context.read<SettingsProvider>().setBiometricEnabled(false);
                } else {
                  _showEnrollmentDialog();
                }
              },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Tampilan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Mode Gelap'),
              subtitle: const Text('Tampilan antarmuka gelap'),
              leading: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
              trailing: Switch(
                value: isDark,
                onChanged: (_) => theme.toggle(),
              ),
              onTap: () => theme.toggle(),
            ),
          ),
          const SizedBox(height: 24),
          Text('Aplikasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.info_outline, color: Color(0xFF4F46E5), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Versi Aplikasi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(_checkingUpdate ? 'Memeriksa...' : _currentVersion, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                        ],
                      ),
                      const Spacer(),
                      if (!_checkingUpdate && _updateInfo != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _hasUpdate ? const Color(0xFF22C55E).withOpacity(0.1) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _hasUpdate ? 'Update Tersedia' : 'Terbaru',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              color: _hasUpdate ? const Color(0xFF22C55E) : Colors.grey.shade600),
                          ),
                        ),
                    ],
                  ),
                  if (_hasUpdate) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text('Perbarui Aplikasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _openDownloadUrl,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrollmentDialog extends StatefulWidget {
  final String username;
  const _EnrollmentDialog({required this.username});

  @override
  State<_EnrollmentDialog> createState() => _EnrollmentDialogState();
}

class _EnrollmentDialogState extends State<_EnrollmentDialog> {
  bool _loading = true;
  bool _scanned = false;
  String? _error;
  final _passwordC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scanFingerprint();
  }

  @override
  void dispose() {
    _passwordC.dispose();
    super.dispose();
  }

  Future<void> _scanFingerprint() async {
    final auth = LocalAuthentication();
    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Pindai sidik jari untuk mengaktifkan',
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _scanned = authenticated;
        });
      }
    } catch (e) {
      debugPrint('Biometric error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _confirm() async {
    final password = _passwordC.text.trim();
    if (password.isEmpty) return;

    setState(() => _loading = true);
    try {
      await ApiService.post('/auth/login', {
        'username': widget.username,
        'password': password,
      });
      await SettingsProvider.savePasswordForUser(widget.username, password);
      if (mounted) {
        await context.read<SettingsProvider>().setBiometricEnabled(true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password salah: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_loading ? 'Memindai...' : _scanned ? 'Konfirmasi Password' : 'Gagal'),
      content: _loading
          ? const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            )
          : !_scanned
              ? Text(_error ?? 'Pemindaian gagal. Pastikan Anda sudah mendaftarkan sidik jari di Pengaturan HP.')
              : TextField(
                  controller: _passwordC,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Masukkan password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        if (_scanned)
          FilledButton(
            onPressed: _loading ? null : _confirm,
            child: const Text('Konfirmasi'),
          ),
      ],
    );
  }
}
