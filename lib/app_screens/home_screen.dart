import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:crimebook/components/export.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:crimebook/components/colors_file.dart';
import 'package:http/http.dart' as http; // Added import
import 'dart:convert'; // Added import for JSON encoding/decoding

const String SERVER_URL = 'https://your_server_url/api/analyze';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// Data model for Syncfusion Chart
class _CrimeData {
  _CrimeData(this.month, this.cases);
  final String month;
  final int cases;
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  late Timer _timer;

  // Variables for filters
  final TextEditingController _locationController = TextEditingController();
  String _selectedCrimeType = 'Theft and Burglary';
  DateTime? _startDate;
  DateTime? _endDate;

  // Flag to indicate whether to show the analysis charts
  bool _showAnalysis = false;
  String _selectedAnalysisType = 'Bar Chart';

  // Variables to hold the data
  Map<String, dynamic>? _analysisData;

  // Chart's GlobalKey for capturing as image
  final GlobalKey<SfCartesianChartState> _chartKey = GlobalKey();

  // Method to start the auto-scrolling carousel
  void startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage == 4) { // Updated to 4 images in the carousel
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeIn,
        );
      }
    });
  }

  // Updated fetchCrimeData method to contact the live Python server
  Future<Map<String, dynamic>> fetchCrimeData({
    required String crimeTypeCategory,
    required DateTime dateFrom,
    required DateTime dateTill,
    required String locationValue,
  }) async {
    try {
      // Prepare the request payload
      final Map<String, dynamic> payload = {
        'crime_type': crimeTypeCategory,
        'location': locationValue,
        'start_date': dateFrom.toIso8601String(),
        'end_date': dateTill.toIso8601String(),
      };

      // Send POST request to the server
      final response = await http.post(
        Uri.parse(SERVER_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        // Handle server errors
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network or parsing errors
      throw Exception('Error fetching data: $e');
    }
  }

  // Create chart based on selected analysis type
  Widget _buildChart(List<_CrimeData> chartData) {
    switch (_selectedAnalysisType) {
      case 'Bar Chart':
        return SfCartesianChart(
          key: _chartKey,
          primaryXAxis: CategoryAxis(),
          title: ChartTitle(text: 'Crime Cases Over Months'),
          legend: Legend(isVisible: true),
          series: <CartesianSeries>[
            ColumnSeries<_CrimeData, String>(
              dataSource: chartData,
              xValueMapper: (data, _) => data.month,
              yValueMapper: (data, _) => data.cases,
              name: 'Cases',
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
          ],
        );
      case 'Pie Chart':
        return SfCircularChart(
          key: _chartKey,
          title: ChartTitle(text: 'Crime Cases Distribution'),
          legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
          series: <CircularSeries>[
            PieSeries<_CrimeData, String>(
              dataSource: chartData,
              xValueMapper: (data, _) => data.month,
              yValueMapper: (data, _) => data.cases,
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
          ],
        );
      case 'Line Chart':
        return SfCartesianChart(
          key: _chartKey,
          primaryXAxis: CategoryAxis(),
          title: ChartTitle(text: 'Crime Cases Over Months'),
          legend: Legend(isVisible: true),
          series: <CartesianSeries>[
            LineSeries<_CrimeData, String>(
              dataSource: chartData,
              xValueMapper: (data, _) => data.month,
              yValueMapper: (data, _) => data.cases,
              name: 'Cases',
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
          ],
        );
      case 'Area Chart':
        return SfCartesianChart(
          key: _chartKey,
          primaryXAxis: CategoryAxis(),
          title: ChartTitle(text: 'Crime Cases Over Months'),
          legend: Legend(isVisible: true),
          series: <CartesianSeries>[
            AreaSeries<_CrimeData, String>(
              dataSource: chartData,
              xValueMapper: (data, _) => data.month,
              yValueMapper: (data, _) => data.cases,
              name: 'Cases',
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
          ],
        );
      case 'Radar Chart':
        return Container();
      default:
        return Text('Invalid analysis type selected');
    }
  }

  @override
  void initState() {
    super.initState();
    startAutoScroll();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Method to select a date from the calendar
  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime initialDate = isStartDate
        ? (_startDate ?? DateTime.now().subtract(Duration(days: 30)))
        : (_endDate ?? DateTime.now());
    final DateTime firstDate = isStartDate ? DateTime(2020) : (_startDate ?? DateTime(2020));
    final DateTime lastDate = isStartDate ? DateTime.now() : DateTime(2025);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          // Optionally reset end date if it's before the new start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  // UI method to build the home content
  Widget buildHomeContent(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Carousel inside the scrollable area
          Padding(
            padding: EdgeInsets.all(10),
            child: Container(
              height: screenHeight * 0.15,
              child: PageView(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                children: [
                  Image.asset('assets/images/image2.webp', fit: BoxFit.cover),
                  Image.asset('assets/images/image1.webp', fit: BoxFit.cover),
                  Image.asset('assets/images/image2.webp', fit: BoxFit.cover),
                  Image.asset('assets/images/image1.webp', fit: BoxFit.cover),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Rest of your code remains the same...
          // Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCrimeType,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCrimeType = newValue!;
                    });
                  },
                  items: ['Theft and Burglary', 'Sexual Crimes', 'Cyber Crimes']
                      .map((crimeType) {
                    return DropdownMenuItem(
                      value: crimeType,
                      child: Text(crimeType),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Select Crime Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, isStartDate: true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _startDate == null ? 'Select Start Date' : DateFormat.yMMMd().format(_startDate!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, isStartDate: false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _endDate == null ? 'Select End Date' : DateFormat.yMMMd().format(_endDate!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDarkMode ? [Colors.black, Colors.black54] : [Colors.blue[900]!, Colors.blue[700]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.transparent, // Makes the button's background transparent
                      shadowColor: Colors.transparent, // Removes shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      List<String> missingFields = [];

                      if (_locationController.text.isEmpty) {
                        missingFields.add('Location');
                      }
                      if (_startDate == null) {
                        missingFields.add('Start Date');
                      }
                      if (_endDate == null) {
                        missingFields.add('End Date');
                      }

                      if (missingFields.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please fill in: ${missingFields.join(', ')}')),
                        );
                        return; // Exit early if fields are missing
                      }

                      // Additional Validations
                      List<String> validationErrors = [];

                      DateTime today = DateTime.now();

                      if (_startDate!.isAfter(today)) {
                        validationErrors.add('Start Date cannot be in the future.');
                      }

                      if (_endDate!.isBefore(_startDate!)) {
                        validationErrors.add('End Date must be after Start Date.');
                      }

                      if (validationErrors.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(validationErrors.join(' '))),
                        );
                        return; // Exit early if validations fail
                      }

                      try {
                        // Show a loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(child: CircularProgressIndicator()),
                        );

                        // Fetch data from the server
                        Map<String, dynamic> data = await fetchCrimeData(
                          crimeTypeCategory: _selectedCrimeType,
                          dateFrom: _startDate!,
                          dateTill: _endDate!,
                          locationValue: _locationController.text,
                        );

                        // Dismiss the loading indicator
                        Navigator.pop(context);

                        setState(() {
                          _analysisData = data;
                          _showAnalysis = true;
                        });
                      } catch (error) {
                        // Dismiss the loading indicator
                        Navigator.pop(context);

                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${error.toString()}')),
                        );
                      }
                    },
                    child: const Text('Analyze'),
                  ),
                ),

              ],
            ),
          ),
          // Analysis Charts
          if (_showAnalysis && _analysisData != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Dropdown to select analysis type
                  DropdownButtonFormField<String>(
                    value: _selectedAnalysisType,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedAnalysisType = newValue!;
                      });
                    },
                    items: ['Bar Chart', 'Pie Chart', 'Line Chart', 'Area Chart', 'Radar Chart']
                        .map((analysisType) {
                      return DropdownMenuItem(
                        value: analysisType,
                        child: Text(analysisType),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: 'Select Analysis Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Build the chart
                  _buildAnalysisCharts(),
                  const SizedBox(height: 20),
                  // Export Button
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[900]!, Colors.blue[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _showExportOptions();
                      },
                      child: const Text(
                        'Export',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Method to show export options
  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.image),
              title: Text('Save as JPG'),
              onTap: () async {
                Navigator.pop(context);
                await _saveAsImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('Save as PDF'),
              onTap: () async {
                Navigator.pop(context);
                await _saveAsPDF();
              },
            ),
            ListTile(
              leading: Icon(Icons.share),
              title: Text('Share as Link'),
              onTap: () {
                Navigator.pop(context);
                // Implement sharing as link later
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Share as Link feature coming soon!')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel),
              title: Text('Cancel'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Method to save chart as image
  Future<void> _saveAsImage() async {
    await ExportHelper.saveChartAsImage(_chartKey, context);
  }

  // Method to save chart as PDF
  Future<void> _saveAsPDF() async {
    await ExportHelper.saveChartAsPDF(_chartKey, context);
  }

  Widget _buildAnalysisCharts() {
    List<_CrimeData> chartData = [];

    for (var stat in _analysisData!['statistics']) {
      chartData.add(_CrimeData(stat['month'], stat['cases']));
    }

    return Container(
      height: 400, // Adjust as needed
      child: _buildChart(chartData),
    );
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    return buildHomeContent(context);
  }
}
