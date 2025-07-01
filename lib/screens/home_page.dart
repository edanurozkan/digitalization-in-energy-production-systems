import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../services/forecast_solar_service.dart';
import '../services/open_meteo_service.dart';
import 'energy_systems_list_page.dart';
import '../theme/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int totalSystems = 0;
  double totalCapacity = 0.0;
  double estimatedProduction = 0.0;
  bool isLoading = true;
  String username = '';
  String? weather;
  List<Map<String, dynamic>> systems = [];
  int? selectedSystemId;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    username = prefs.getString('username') ?? 'User';

    if (userId == null) return;

    systems = await DBHelper.getSystemsByUserId(userId);

    totalSystems = systems.length;
    totalCapacity =
        systems.fold(0.0, (sum, s) => sum + (s['capacity_kW'] as double));

    double totalDaily = 0.0;
    final forecastApi = ForecastSolarService();

    for (var system in systems) {
      final forecast = await forecastApi.getEstimatedProduction(
          lat: system['latitude'],
          lon: system['longitude'],
          capacityKW: system['capacity_kW'],
          tilt: system['tilt'],
          azimuth: system['azimuth']);

      if (forecast != null) {
        totalDaily += forecast['daily'] ?? 0;
      }
    }

    if (systems.isNotEmpty) {
      selectedSystemId ??= systems[0]['id'];
      await _updateWeatherBySelectedSystem();
    }

    setState(() {
      estimatedProduction = totalDaily;
      isLoading = false;
    });
  }

  Future<void> _updateWeatherBySelectedSystem() async {
    if (systems.isEmpty || selectedSystemId == null) return;

    final selected = systems.firstWhere(
      (s) => s['id'] == selectedSystemId,
      orElse: () => systems[0],
    );

    final lat = (selected['latitude'] as num).toDouble();
    final lon = (selected['longitude'] as num).toDouble();

    weather = await OpenMeteoService.getCurrentWeather(
      latitude: lat,
      longitude: lon,
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Welcome back, $username 👋",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cardBackground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard("Systems", totalSystems.toString(),
                            Icons.solar_power),
                        _buildStatCard("Capacity", "$totalCapacity kW",
                            Icons.battery_charging_full),
                        _buildStatCard(
                            "Today",
                            "${estimatedProduction.toStringAsFixed(1)} kWh",
                            Icons.bolt),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Hava Durumu Kartı
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.cloud, color: Colors.white, size: 32),
                              SizedBox(width: 12),
                              Text(
                                "Current Weather Info",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: DropdownButton<int>(
                              value: selectedSystemId,
                              isExpanded: true,
                              underline: const SizedBox(),
                              dropdownColor: AppColors.card,
                              iconEnabledColor: Colors.white,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                              items: systems.map((system) {
                                return DropdownMenuItem<int>(
                                  value: system['id'],
                                  child: Text(system['system_name'] ??
                                      'Unnamed System'),
                                );
                              }).toList(),
                              onChanged: (value) async {
                                selectedSystemId = value;
                                await _updateWeatherBySelectedSystem();
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (selectedSystemId != null)
                            Text(
                              "Currently showing weather for: ${systems.firstWhere((s) => s['id'] == selectedSystemId)['system_name']}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            weather != null
                                ? "→ $weather"
                                : "Weather data not available ❓",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb,
                              color: AppColors.primary, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Tip: Check your solar panel tilt angles monthly to maximize production efficiency.",
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.cardBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const EnergySystemsListPage()),
                          );
                        },
                        child: const Text(
                          "Enter My Systems",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.cardBackground),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
