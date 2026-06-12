class Vendor {
  final int id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? description;
  final int? jobId;
  final Map<String, dynamic>? job;

  Vendor({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.description,
    this.jobId,
    this.job,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['ID'] ?? json['id'] ?? 0,
      name: json['Name'] ?? json['name'] ?? '',
      contactPerson: json['ContactPerson'] ?? json['contact_person'],
      phone: json['Phone'] ?? json['phone'],
      email: json['Email'] ?? json['email'],
      address: json['Address'] ?? json['address'],
      description: json['Description'] ?? json['description'],
      jobId: json['JobID'] ?? json['job_id'],
      job: json['Job'] ?? json['job'],
    );
  }
}

class PaymentTerm {
  final int id;
  final int vendorId;
  final int termNumber;
  final double? percentage;
  final double? amount;
  final String? dueDate;
  final String? description;

  PaymentTerm({
    required this.id,
    required this.vendorId,
    required this.termNumber,
    this.percentage,
    this.amount,
    this.dueDate,
    this.description,
  });

  factory PaymentTerm.fromJson(Map<String, dynamic> json) {
    return PaymentTerm(
      id: json['ID'] ?? json['id'] ?? 0,
      vendorId: json['VendorID'] ?? json['vendor_id'] ?? 0,
      termNumber: json['TermNumber'] ?? json['term_number'] ?? 0,
      percentage: (json['Percentage'] ?? json['percentage'])?.toDouble(),
      amount: (json['Amount'] ?? json['amount'])?.toDouble(),
      dueDate: json['DueDate'] ?? json['due_date'],
      description: json['Description'] ?? json['description'],
    );
  }
}
