import 'user.dart';

class Attendance {
  final int id;
  final int userId;
  final String date;
  final String type;
  final String location;
  final String? reason;
  final String? clockIn;
  final String? clockOut;
  final String? typeDisplay;
  final String? durasiLembur;
  final int? lemburJam;
  final int? lemburMenit;
  final User? user;

  Attendance({
    required this.id,
    required this.userId,
    required this.date,
    this.type = 'hadir',
    this.location = 'kantor',
    this.reason,
    this.clockIn,
    this.clockOut,
    this.typeDisplay,
    this.durasiLembur,
    this.lemburJam,
    this.lemburMenit,
    this.user,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    User? user;
    if (json['User'] != null) {
      user = User.fromJson(json['User'] as Map<String, dynamic>);
    } else if (json['user'] != null) {
      user = User.fromJson(json['user'] as Map<String, dynamic>);
    }

    return Attendance(
      id: json['ID'] ?? json['id'] ?? 0,
      userId: json['UserID'] ?? json['user_id'] ?? 0,
      date: json['Date'] ?? json['date'] ?? '',
      type: json['Type'] ?? json['type'] ?? 'hadir',
      location: json['Location'] ?? json['location'] ?? 'kantor',
      reason: json['Reason'] ?? json['reason'],
      clockIn: json['ClockIn'] ?? json['clock_in'],
      clockOut: json['ClockOut'] ?? json['clock_out'],
      typeDisplay: json['type_display'] ?? json['TypeDisplay'],
      durasiLembur: json['durasi_lembur'],
      lemburJam: json['lembur_jam'],
      lemburMenit: json['lembur_menit'],
      user: user,
    );
  }

  bool get isHadir => type == 'hadir';
  bool get isTidakHadir => type == 'tidak_hadir';
  bool get isLembur => type == 'lembur';
  bool get isLuarKota => location == 'luar_kota';
  bool get isLemburSelesai => clockOut != null && clockOut!.isNotEmpty;

  String get displayType {
    if (typeDisplay != null) return typeDisplay!;
    if (type == 'hadir') {
      return location == 'luar_kota' ? 'Hadir (Luar Kota)' : 'Hadir';
    }
    if (type == 'lembur') return 'Hadir + Lembur';
    if (type == 'tidak_hadir') return 'Tidak Hadir';
    return type;
  }
}
