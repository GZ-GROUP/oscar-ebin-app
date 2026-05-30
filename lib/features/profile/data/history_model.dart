class HistoryEntry {
  final int id;
  final String type;
  final String description;
  final String? oscarName;
  final double amount;
  final String currency;
  final String createdAt;

  HistoryEntry({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.currency,
    required this.createdAt,
    this.oscarName,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0;
    final amountRaw = json['amount'];
    final amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse('$amountRaw') ?? 0.0;

    return HistoryEntry(
      id: id,
      type: json['type'] as String? ?? 'unknown',
      description: json['description'] as String? ?? 'Transacción',
      amount: amount,
      currency: json['currency'] as String? ?? 'pts',
      createdAt: json['created_at'] as String? ?? '',
      oscarName: json['oscar_name'] as String?,
    );
  }
}
