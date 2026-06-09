import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/job.dart';
import '../services/job_service.dart';

class UploadDokumenScreen extends StatefulWidget {
  const UploadDokumenScreen({super.key});
  @override
  State<UploadDokumenScreen> createState() => _UploadDokumenScreenState();
}

class _UploadDokumenScreenState extends State<UploadDokumenScreen> {
  List<Job> _jobs = [];
  bool _loading = true;
  Job? _selectedJob;
  File? _selectedFile;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final jobs = await JobService.getJobs();
      if (mounted) setState(() {
        _jobs = jobs;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedJob == null || _selectedFile == null) return;
    try {
      await JobService.uploadDocument(_selectedJob!.id, _selectedFile!.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dokumen berhasil diupload'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        setState(() {
          _selectedFile = null;
          _fileName = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Dokumen')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Upload Dokumen Pekerjaan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pilih pekerjaan dan file yang akan diupload',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<Job>(
                  initialValue: _selectedJob,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Pekerjaan',
                    prefixIcon: Icon(Icons.work_history_outlined),
                  ),
                  isExpanded: true,
                  items: _jobs
                      .map((j) => DropdownMenuItem(
                          value: j,
                          child: Text(j.name,
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedJob = v),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _fileName ?? 'Klik untuk pilih file',
                          style: TextStyle(
                            color: _fileName != null
                                ? Colors.grey.shade800
                                : Colors.grey.shade500,
                            fontWeight:
                                _fileName != null ? FontWeight.w500 : null,
                          ),
                        ),
                        if (_fileName == null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'PDF, DOC, JPG, PNG',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        _selectedJob != null && _selectedFile != null
                            ? _upload
                            : null,
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Upload', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
