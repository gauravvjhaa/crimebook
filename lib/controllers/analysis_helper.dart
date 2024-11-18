// analysis_helper.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/material.dart';

// Data model for Syncfusion Chart
class CrimeData {
  CrimeData(this.category, this.cases);
  final String category; // This can be month or any other category
  final int cases;
}

class AnalysisHelper {
  // Fetch crime data from Firestore
  static Future<Map<String, dynamic>> fetchCrimeData({
    required String crimeType,
    required String year,
    required String location,
  }) async {
    try {
      // Reference to 'data' collection
      CollectionReference crimeDataRef = FirebaseFirestore.instance.collection('data');

      Query query = crimeDataRef;

      // Apply filters
      if (crimeType != 'Any') {
        query = query.where('crime_type', isEqualTo: crimeType);
      }

      if (year != 'Any') {
        query = query.where('year', isEqualTo: int.parse(year));
      }

      if (location != 'India') {
        query = query.where('location', isEqualTo: location);
      }
      // If location is 'India', we include all locations

      // Execute the query
      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('No data found for the selected criteria.');
      }

      // Process data
      Map<String, int> categoryCases = {};

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Check for null values in data
        if (data['month'] == null || data['cases'] == null) {
          // Skip this document or handle it appropriately
          continue;
        }

        String category = data['month'].toString(); // Ensure it's a String
        int? cases = data['cases'] is int ? data['cases'] : int.tryParse(data['cases'].toString());

        // If cases is still null after parsing, skip this entry
        if (cases == null) {
          continue;
        }

        // Sum cases when location is 'India' by aggregating over all locations
        if (location == 'India') {
          // Use 'category' as month
          category = data['month'].toString();
        }

        // Aggregate cases
        if (categoryCases.containsKey(category)) {
          categoryCases[category] = categoryCases[category]! + cases;
        } else {
          categoryCases[category] = cases;
        }
      }

      // Check if categoryCases is empty after processing
      if (categoryCases.isEmpty) {
        throw Exception('No valid data found after processing.');
      }

      // Convert to list of CrimeData
      List<CrimeData> chartData = categoryCases.entries.map((entry) {
        return CrimeData(entry.key, entry.value);
      }).toList();

      // Sort chartData based on the category (e.g., months)
      chartData.sort((a, b) => _monthOrder.indexOf(a.category).compareTo(_monthOrder.indexOf(b.category)));

      // Return the data
      return {
        'chartData': chartData,
      };
    } catch (e) {
      // Handle specific exceptions if needed
      // throw Exception('Error fetching data: ${e.toString()}');
      throw Exception('Sorry, No data found for selected choices');
    }
  }

  // Build chart based on selected analysis type
  static Widget buildChart({
    required List<CrimeData> chartData,
    required String analysisType,
    required GlobalKey<SfCartesianChartState> chartKey,
  }) {
    // Handle empty chartData
    if (chartData.isEmpty) {
      return Center(
        child: Text('No data available to display the chart.'),
      );
    }

    switch (analysisType) {
      case 'Bar Chart':
        return SfCartesianChart(
          key: chartKey,
          primaryXAxis: CategoryAxis(),
          title: ChartTitle(text: 'Crime Cases Over Months'),
          legend: Legend(isVisible: false),
          series: <CartesianSeries>[
            ColumnSeries<CrimeData, String>(
              dataSource: chartData,
              xValueMapper: (data, _) => data.category,
              yValueMapper: (data, _) => data.cases,
              name: 'Cases',
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
          ],
        );
      case 'Pie Chart':
        return SfCircularChart(
          key: chartKey,
          title: ChartTitle(text: 'Crime Cases Distribution'),
          legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
          series: <CircularSeries>[
            PieSeries<CrimeData, String>(
              dataSource: chartData,
              xValueMapper: (data, _) => data.category,
              yValueMapper: (data, _) => data.cases,
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
          ],
        );
      case 'Line Chart':
        return SfCartesianChart(
          key: chartKey,
          primaryXAxis: CategoryAxis(),
          title: ChartTitle(text: 'Crime Cases Over Months'),
          legend: Legend(isVisible: false),
          series: <CartesianSeries>[
            LineSeries<CrimeData, String>(
              dataSource: chartData,
              xValueMapper: (data, _) => data.category,
              yValueMapper: (data, _) => data.cases,
              name: 'Cases',
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
          ],
        );
      case 'Area Chart':
        return SfCartesianChart(
          key: chartKey,
          primaryXAxis: CategoryAxis(),
          title: ChartTitle(text: 'Crime Cases Over Months'),
          legend: Legend(isVisible: false),
          series: <CartesianSeries>[
            AreaSeries<CrimeData, String>(
              dataSource: chartData,
              xValueMapper: (data, _) => data.category,
              yValueMapper: (data, _) => data.cases,
              name: 'Cases',
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
          ],
        );
      case 'Radar Chart':
      // Implement Radar Chart if needed
        return Container();
      default:
        return Text('Invalid analysis type selected');
    }
  }

  // Helper list to order months correctly
  static const List<String> _monthOrder = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
}
