import 'package:energy_system_3/screens/portable_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import 'energy_systems_detail_page.dart';
import '../services/location_service.dart';
import '../theme/theme.dart';

class EnergySystemsListPage extends StatefulWidget {
  const EnergySystemsListPage({super.key});

  @override
  State<EnergySystemsListPage> createState() => _EnergySystemsListPageState();
}

class _EnergySystemsListPageState extends State<EnergySystemsListPage> {
  List<Map<String, dynamic>> systems = [];
  Map<int, String> locationNames = {}; // 💡 sistemId → konum cache
  int? userId;

  Future<void> _loadSystems() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');

    if (userId != null) {
      final updated = await DBHelper.getSystemsByUserId(userId!);
      systems = updated;
      setState(() {}); // önce listeyi hemen gösteriyoruz

      for (var system in systems) {
        final id = system['id'];
        final lat = (system['latitude'] as num).toDouble();
        final lon = (system['longitude'] as num).toDouble();

        final location = await LocationService.getLocationName(
            latitude: lat, longitude: lon);
        locationNames[id] = location ?? "Unknown Location";

        setState(() {}); // her biri geldikçe güncelliyoruz
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSystems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("☀️ Solar Energy Systems"),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.cardBackground,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add System",
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PortablePanelPage()),
          );
          if (result == true) {
            _loadSystems();
          }
        },
      ),
      body: systems.isEmpty
          ? const Center(
              child: Text(
                "You haven't added any system yet.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemCount: systems.length,
              itemBuilder: (context, index) {
                final system = systems[index];
                final id = system['id'];
                final location = locationNames[id] ?? "Loading location...";

                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EnergySystemDetailPage(system: system),
                      ),
                    );

                    if (result == 'deleted') {
                      await _loadSystems();
                    }
                  },
                  child: Container(
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
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.solar_power,
                                  size: 32, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  system['system_name'] ?? 'Unnamed System',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.place,
                                  size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.bolt,
                                  size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                "${system['capacity_kW']} kW Capacity",
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
