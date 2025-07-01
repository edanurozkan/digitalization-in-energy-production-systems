import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/db_helper.dart';

class EnergyChartPage extends StatefulWidget {
  const EnergyChartPage({super.key});

  @override
  State<EnergyChartPage> createState() => _EnergyChartPageState();
}

class _EnergyChartPageState extends State<EnergyChartPage> {
  List<Map<String, dynamic>> allData = [];
  List<int> availableSystemIds = [];
  int? selectedSystemId;

  Future<void> _loadData() async {
    final data = await DBHelper.getAllProductions();
    final ids = data.map((e) => e['system_id'] as int).toSet().toList()..sort();

    setState(() {
      allData = data;
      availableSystemIds = ids;
      selectedSystemId = ids.isNotEmpty ? ids.first : null;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = allData
        .where((item) => item['system_id'] == selectedSystemId)
        .toList()
      ..sort((a, b) => a['month'].compareTo(b['month']));

    return Scaffold(
      appBar: AppBar(title: const Text("Aylık Üretim Grafiği")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (availableSystemIds.isNotEmpty)
              DropdownButton<int>(
                value: selectedSystemId,
                onChanged: (value) {
                  setState(() {
                    selectedSystemId = value;
                  });
                },
                items: availableSystemIds.map((id) {
                  return DropdownMenuItem(
                    value: id,
                    child: Text('Sistem $id'),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: filteredData.isEmpty
                  ? const Center(child: Text("Veri bulunamadı."))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final month = value.toInt();
                                return Text(month.toString());
                              },
                              reservedSize: 24,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: filteredData.map((e) {
                          final month = e['month'];
                          final value = (e['energy_kWh'] as num).toDouble();
                          return BarChartGroupData(
                            x: month,
                            barRods: [
                              BarChartRodData(
                                  toY: value, width: 16, color: Colors.orange),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
