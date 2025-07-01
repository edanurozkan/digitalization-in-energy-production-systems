class EnergySystem {
  final int? id;
  final int userId;
  final String systemName;
  final double latitude;
  final double longitude;
  final double capacityKW;
  final String? panelId; 

  EnergySystem({
    this.id,
    required this.userId,
    required this.systemName,
    required this.latitude,
    required this.longitude,
    required this.capacityKW,
    this.panelId,
  });

  factory EnergySystem.fromJson(Map<String, dynamic> json) {
    return EnergySystem(
      id: json['id'],
      userId: json['userId'],
      systemName: json['systemName'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      capacityKW: json['capacityKW'],
      panelId: json['panelId'], // yeni alan
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'systemName': systemName,
      'latitude': latitude,
      'longitude': longitude,
      'capacityKW': capacityKW,
      if (panelId != null) 'panelId': panelId, // sadece varsa
    };
  }
}
