class Job {
  final int id;
  final String name;
  final String? description;
  final double value;
  final String? contractDate;
  final String? share;
  final String? status;
  final String? dateline;
  final String? assignedTo;
  final String? spektek;
  final String? shareToken;
  final String? createdAt;
  final String? lokasi;
  final String? nomorSurat;
  final int uncompletedLogistic;
  final int uncompletedTeknisi;

  Job({
    required this.id,
    required this.name,
    this.description,
    this.value = 0,
    this.contractDate,
    this.share,
    this.status,
    this.dateline,
    this.assignedTo,
    this.spektek,
    this.shareToken,
    this.createdAt,
    this.lokasi,
    this.nomorSurat,
    this.uncompletedLogistic = 0,
    this.uncompletedTeknisi = 0,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['ID'] ?? json['id'] ?? 0,
      name: json['Name'] ?? json['name'] ?? '',
      description: json['Description'] ?? json['description'],
      value: (json['Value'] ?? json['value'] ?? 0).toDouble(),
      contractDate: json['ContractDate'] ?? json['contract_date'],
      share: json['Share'] ?? json['share'],
      status: json['Status'] ?? json['status'],
      dateline: json['Dateline'] ?? json['dateline'],
      assignedTo: json['AssignedTo'] ?? json['assigned_to'],
      spektek: json['Spektek'] ?? json['spektek'],
      shareToken: json['ShareToken'] ?? json['share_token'],
      createdAt: json['CreatedAt'] ?? json['created_at'],
      lokasi: json['Lokasi'] ?? json['lokasi'],
      nomorSurat: json['NomorSurat'] ?? json['nomor_surat'],
      uncompletedLogistic: json['uncompleted_logistic'] ?? 0,
      uncompletedTeknisi: json['uncompleted_teknisi'] ?? 0,
    );
  }

  List<String> get sharedRoles =>
      (share ?? '').split(',').where((s) => s.trim().isNotEmpty).toList();

  List<int> get assignedUserIds {
    if (assignedTo == null || assignedTo!.isEmpty) return [];
    return assignedTo!.split(',').map((s) => int.tryParse(s.trim()) ?? 0).where((id) => id > 0).toList();
  }
}
