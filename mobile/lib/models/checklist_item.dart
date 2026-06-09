class ChecklistItem {
  final int id;
  final int jobId;
  final String role;
  final String item;
  final bool completed;
  final String status;
  final String images;
  final int quantity;
  final String unit;
  final String notes;
  final double price;

  ChecklistItem({
    required this.id,
    required this.jobId,
    required this.role,
    required this.item,
    this.completed = false,
    this.status = 'pending',
    this.images = '',
    this.quantity = 0,
    this.unit = '',
    this.notes = '',
    this.price = 0,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['ID'] ?? json['id'] ?? 0,
      jobId: json['JobID'] ?? json['job_id'] ?? 0,
      role: json['Role'] ?? json['role'] ?? '',
      item: json['Item'] ?? json['item'] ?? '',
      completed: json['Completed'] ?? json['completed'] ?? false,
      status: json['Status'] ?? json['status'] ?? 'pending',
      images: json['Images'] ?? json['images'] ?? '',
      quantity: json['Quantity'] ?? json['quantity'] ?? 0,
      unit: json['Unit'] ?? json['unit'] ?? '',
      notes: json['Notes'] ?? json['notes'] ?? '',
      price: (json['Price'] ?? json['price'] ?? 0).toDouble(),
    );
  }

  List<String> get imageList =>
      images.isEmpty ? [] : images.split(',').where((s) => s.isNotEmpty).toList();

  bool get isDone => status == 'selesai' || completed;
}
