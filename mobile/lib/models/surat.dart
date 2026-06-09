class Surat {
  final int id;
  final String namaSurat;
  final String jenisSurat;
  final DateTime startAktif;
  final DateTime masaBerlaku;

  Surat({
    required this.id,
    required this.namaSurat,
    required this.jenisSurat,
    required this.startAktif,
    required this.masaBerlaku,
  });

  bool get isExpired => DateTime.now().isAfter(masaBerlaku);

  bool get isExpiring {
    if (isExpired) return false;
    final diff = masaBerlaku.difference(DateTime.now());
    return diff.inDays <= 7;
  }

  String get sisaWaktu {
    final diff = masaBerlaku.difference(DateTime.now());
    if (diff.isNegative) return 'Kadaluarsa';
    if (diff.inDays > 30) {
      final months = diff.inDays ~/ 30;
      return '$months bulan';
    }
    return '${diff.inDays} hari';
  }

  factory Surat.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String? val) {
      if (val == null) return DateTime.now();
      try {
        return DateTime.parse(val);
      } catch (_) {
        return DateTime.now();
      }
    }

    return Surat(
      id: json['ID'] ?? json['id'] ?? 0,
      namaSurat: json['NamaSurat'] ?? json['nama_surat'] ?? '',
      jenisSurat: json['JenisSurat'] ?? json['jenis_surat'] ?? '',
      startAktif: parseDate(json['StartAktif']?.toString() ?? json['start_aktif']?.toString()),
      masaBerlaku: parseDate(json['MasaBerlaku']?.toString() ?? json['masa_berlaku']?.toString()),
    );
  }
}
