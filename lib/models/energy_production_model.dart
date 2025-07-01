class EnergyProduction {
  final int? id;
  final int systemId;
  final int month; 
  final int year;
  final double energyKWh;

  EnergyProduction({
    this.id,
    required this.systemId,
    required this.month,
    required this.year,
    required this.energyKWh,
  });

  Map<String, dynamic> toMap() {
    return {
      'system_id': systemId,
      'month': month,
      'year': year,
      'energy_kWh': energyKWh,
    };
  }
}
