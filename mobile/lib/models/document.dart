class Document {
  final int id;
  final String namaDokumen;
  final String tipeDokumen;
  final String filePath;
  final String? deskripsi;
  final String shareMode;
  final String? sharedTo;
  final int uploadedBy;
  final String? createdAt;

  Document({
    required this.id,
    required this.namaDokumen,
    required this.tipeDokumen,
    required this.filePath,
    this.deskripsi,
    this.shareMode = 'all',
    this.sharedTo,
    this.uploadedBy = 0,
    this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['ID'] ?? json['id'] ?? 0,
      namaDokumen: json['NamaDokumen'] ?? json['nama_dokumen'] ?? '',
      tipeDokumen: json['TipeDokumen'] ?? json['tipe_dokumen'] ?? '',
      filePath: json['FilePath'] ?? json['file_path'] ?? '',
      deskripsi: json['Deskripsi'] ?? json['deskripsi'],
      shareMode: json['ShareMode'] ?? json['share_mode'] ?? 'all',
      sharedTo: json['SharedTo'] ?? json['shared_to'],
      uploadedBy: json['UploadedBy'] ?? json['uploaded_by'] ?? 0,
      createdAt: json['CreatedAt'] ?? json['created_at'],
    );
  }

  String get fileUrl => filePath.replaceAll('\\', '/');

  bool get isPdf => tipeDokumen == 'PDF';
  bool get isImage => ['JPG', 'PNG', 'JPEG'].contains(tipeDokumen);
}
