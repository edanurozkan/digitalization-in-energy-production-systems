import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/forecast_solar_service.dart';
import '../theme/theme.dart';
import '../widgets/custom_input_decoration.dart';
import '../database/db_helper.dart';

class PortablePanelPage extends StatefulWidget {
  const PortablePanelPage({Key? key}) : super(key: key);

  @override
  _PortablePanelPageState createState() => _PortablePanelPageState();
}

class _PortablePanelPageState extends State<PortablePanelPage> {
  final _formKey = GlobalKey<FormState>();
  LatLng? selectedLocation;
  double? capacity;
  double? tilt;
  double? azimuth;
  Map<String, dynamic>? forecastResult;
  bool isLoading = false;
  int? userId;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    loadUserId();
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId');
    if (id != null) {
      setState(() => userId = id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanıcı ID bulunamadı.")),
      );
    }
  }

  Future<void> _requestLocationPermission() async {
    PermissionStatus status = await Permission.location.status;
    if (status.isDenied) status = await Permission.location.request();
    if (status.isPermanentlyDenied) _showPermissionDialog();
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konum İzni Gerekli'),
        content: const Text('Lütfen uygulama ayarlarından konum izni verin.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Ayarlar')),
        ],
      ),
    );
  }

  void _selectLocation(LatLng location) {
    setState(() => selectedLocation = location);
  }

  Future<void> _getForecast() async {
    if (!_formKey.currentState!.validate() || selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen konum ve tüm bilgileri giriniz.")),
      );
      return;
    }
    _formKey.currentState!.save();
    setState(() => isLoading = true);
    try {
      final service = ForecastSolarService();
      final result = await service.getEstimatedProduction(
        lat: selectedLocation!.latitude,
        lon: selectedLocation!.longitude,
        tilt: tilt!,
        azimuth: azimuth!,
        capacityKW: capacity!,
      );
      setState(() => forecastResult = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Beklenmeyen Hata: ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveSystemToDatabase(BuildContext context) async {
    if (selectedLocation == null || capacity == null || userId == null) return;

    final TextEditingController nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sistem Adı"),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.black),
          decoration: const InputDecoration(hintText: "Örn: Portatif Panel"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal")),
          ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, nameController.text.trim()),
              child: const Text("Kaydet")),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await DBHelper.addEnergySystem(
        userId: userId!,
        systemName: result,
        latitude: selectedLocation!.latitude,
        longitude: selectedLocation!.longitude,
        capacityKW: capacity!,
        tilt: tilt!,
        azimuth: azimuth!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Sistem başarıyla kaydedildi.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Portatif Panel Tahmini")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 250,
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(37.7749, -122.4194),
                    zoom: 5,
                  ),
                  onTap: _selectLocation,
                  markers: selectedLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: selectedLocation!,
                            infoWindow: InfoWindow(
                              title: "Seçilen Konum",
                              snippet:
                                  "${selectedLocation!.latitude}, ${selectedLocation!.longitude}",
                            ),
                          ),
                        }
                      : {},
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField("Capacity (kWp)", Icons.bolt, 'capacity',
                          (v) => capacity = double.parse(v!)),
                      const SizedBox(height: 12),
                      _buildTextField("Tilt (°)", Icons.stacked_line_chart,
                          'tilt', (v) => tilt = double.parse(v!)),
                      const SizedBox(height: 12),
                      _buildTextField("Azimuth (°)", Icons.explore, 'azimuth',
                          (v) => azimuth = double.parse(v!)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _getForecast,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Get Forecast",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading) const CircularProgressIndicator(),
            if (forecastResult != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, String fieldName,
      void Function(String?) onSaved) {
    return TextFormField(
      style: const TextStyle(color: Colors.black),
      decoration: CustomInputDecoration.input(label: label, icon: icon),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Bu alan boş bırakılamaz';
        final numValue = double.tryParse(value);
        if (numValue == null) return 'Geçerli bir sayı girin';
        if (fieldName == 'tilt' && (numValue < 0 || numValue > 90))
          return 'Tilt 0-90° arasında olmalı';
        if (fieldName == 'azimuth' && (numValue < 0 || numValue > 360))
          return 'Azimuth 0-360° arasında olmalı';
        if (fieldName == 'capacity' && numValue <= 0)
          return 'Capacity pozitif olmalı';
        return null;
      },
      onSaved: onSaved,
    );
  }

  Widget _buildResultCard() {
    final daily = forecastResult!['daily'] as double;
    final Map<int, double> hourlyMap =
        Map<int, double>.from(forecastResult!['hourly']);
    final List<FlSpot> spots = hourlyMap.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Tahmin Sonucu",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Text("Günlük Üretim: ${daily.toStringAsFixed(2)} kWh",
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 20),
            if (spots.isNotEmpty)
              SizedBox(height: 200, child: _buildChart(spots)),
            if (spots.isEmpty)
              const Text("Saatlik veri bulunamadı",
                  style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _saveSystemToDatabase(context),
              icon: const Icon(Icons.save),
              label: const Text("Kaydet"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<FlSpot> spots) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            spots: spots,
            color: Colors.white,
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
