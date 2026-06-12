import '../models/vendor.dart';
import 'api_service.dart';

class VendorService {
  static Future<List<Vendor>> getAll() async {
    final data = await ApiService.get('/vendors');
    final list = data['vendors'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((j) => Vendor.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<Vendor> create(Map<String, dynamic> body) async {
    final data = await ApiService.post('/vendors', body);
    return Vendor.fromJson(data['vendor'] as Map<String, dynamic>);
  }

  static Future<Vendor> update(int id, Map<String, dynamic> body) async {
    final data = await ApiService.put('/vendors/$id', body);
    return Vendor.fromJson(data['vendor'] as Map<String, dynamic>);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('/vendors/$id');
  }

  static Future<List<PaymentTerm>> getPaymentTerms(int vendorId) async {
    final data = await ApiService.get('/vendors/$vendorId/payment-terms');
    final list = data['payment_terms'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((j) => PaymentTerm.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<PaymentTerm> createPaymentTerm(int vendorId, Map<String, dynamic> body) async {
    final data = await ApiService.post('/vendors/$vendorId/payment-terms', body);
    return PaymentTerm.fromJson(data['payment_term'] as Map<String, dynamic>);
  }

  static Future<PaymentTerm> updatePaymentTerm(int vendorId, int termId, Map<String, dynamic> body) async {
    final data = await ApiService.put('/vendors/$vendorId/payment-terms/$termId', body);
    return PaymentTerm.fromJson(data['payment_term'] as Map<String, dynamic>);
  }

  static Future<void> deletePaymentTerm(int vendorId, int termId) async {
    await ApiService.delete('/vendors/$vendorId/payment-terms/$termId');
  }
}
