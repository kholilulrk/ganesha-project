String formatRupiah(num value) {
  final parts = value.toStringAsFixed(0).split('');
  final result = StringBuffer();
  for (var i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) result.write('.');
    result.write(parts[i]);
  }
  return 'Rp ${result.toString()}';
}
