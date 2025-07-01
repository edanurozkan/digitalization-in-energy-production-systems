import 'package:flutter/material.dart';
import '../services/forecast_solar_service.dart';
import '../services/location_service.dart';
import '../services/open_meteo_service.dart';
import '../widgets/production_chart_widget.dart';
import '../database/db_helper.dart';
import '../theme/theme.dart';

class EnergySystemDetailPage extends StatefulWidget {
  final Map<String, dynamic> system;

  const EnergySystemDetailPage({super.key, required this.system});

  @override
  State<EnergySystemDetailPage> createState() => _EnergySystemDetailPageState();
}

class _EnergySystemDetailPageState extends State<EnergySystemDetailPage> {
  bool isLoading = true;
  double? dailyEnergy;
  String? locationName;
  Map<String, dynamic> chartData = {
    'Days': <int, double>{},
    'Weeks': [],
    'Months': [],
    'Year': [],
  };

  @override
  void initState() {
    super.initState();
    fetchData();
    _loadLocationName();
  }

  Future<void> _loadLocationName() async {
    final lat = widget.system['latitude'];
    final lon = widget.system['longitude'];
    final name =
        await LocationService.getLocationName(latitude: lat, longitude: lon);
    setState(() {
      locationName = name ?? 'Unknown Location';
    });
  }

  Future<void> fetchData() async {
    final forecastApi = ForecastSolarService();

    final double lat = (widget.system['latitude'] as num).toDouble();
    final double lon = (widget.system['longitude'] as num).toDouble();
    final double capacity = (widget.system['capacity_kW'] as num).toDouble();
    final tilt = (widget.system['tilt'] as num).toDouble();
    final azimuth = (widget.system['azimuth'] as num).toDouble();

    final forecast = await forecastApi.getEstimatedProduction(
      lat: lat,
      lon: lon,
      capacityKW: capacity,
      tilt: tilt,
      azimuth: azimuth,
    );

    final daily = forecast?['daily'];
    final hourly = forecast?['hourly'] ?? [];
    final dailyList = forecast?['dailyList'] ?? [];

    if (daily == null || hourly.isEmpty) {
      setState(() {
        isLoading = false;
        dailyEnergy = null;
      });
      return;
    }

    // 🔁 Open-Meteo ile haftalık üretimi tahmin et
    final weeksRaw = await OpenMeteoService.getWeeklySolarEstimate(
      lat: lat,
      lon: lon,
      capacityKW: capacity,
      tilt: tilt,
      azimuth: azimuth,
    );

    final openMeteoToday = weeksRaw.isNotEmpty ? weeksRaw[0] : 1.0;
    final scaleFactor = daily / openMeteoToday;
    final weeksAdjusted = weeksRaw
        .map((v) => double.parse((v * scaleFactor).toStringAsFixed(2)))
        .toList();

    // 📆 Aylık ortalamalar
    List<double> months = [];
    for (int i = 0; i < dailyList.length; i += 7) {
      final chunk = dailyList.skip(i).take(7).cast<double>().toList();
      final average = chunk.reduce((a, b) => a + b) / chunk.length;
      months.add(average);
    }

    // 📆 Yıllık ortalamalar
    List<double> years = [];
    for (int i = 0; i < dailyList.length; i += 30) {
      final chunk = dailyList.skip(i).take(30).cast<double>().toList();
      final average = chunk.reduce((a, b) => a + b) / chunk.length;
      years.add(average);
    }

    setState(() {
      dailyEnergy = daily;
      isLoading = false;
      chartData = {
        'Days': hourly,
        'Weeks': weeksAdjusted,
        'Months': months,
        'Year': years,
      };
    });
  }

  Future<void> _confirmAndDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this system?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.deleteEnergySystem(widget.system['id']);
      if (mounted) Navigator.pop(context, 'deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.system['system_name'] ?? 'System Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _confirmAndDelete,
            tooltip: "Delete System",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(Icons.place, "Location",
                      locationName ?? "Loading location..."),
                  const SizedBox(height: 16),
                  _buildInfoCard(Icons.battery_charging_full, "Capacity",
                      "${widget.system['capacity_kW']} kW"),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                      Icons.bolt,
                      "Daily Production",
                      dailyEnergy != null
                          ? "${dailyEnergy!.toStringAsFixed(2)} kWh"
                          : "Data not available"),
                  const SizedBox(height: 24),
                  const Text(
                    "Production Chart",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ProductionChartWidget(dataByPeriod: chartData),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.textSecondary)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
