class Oscar {
  final int id;
  final String code;
  final String name;
  final double lat;
  final double lng;
  final String address;
  final String status;

  Oscar({
    required this.id,
    required this.code,
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
    required this.status,
  });

  factory Oscar.fromJson(Map<String, dynamic> json) {
    return Oscar(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: json['address'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'lat': lat,
        'lng': lng,
        'address': address,
        'status': status,
      };
}
