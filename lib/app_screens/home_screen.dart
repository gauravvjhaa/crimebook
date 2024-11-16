// home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:crimebook/controllers/analysis_helper.dart';
import 'package:crimebook/controllers/data_lists.dart';
import 'package:crimebook/components/custom_dropdown.dart';
import 'dart:ui' as ui;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  late Timer _timer;

  // Variables for filters
  String? _selectedLocation;
  String? _selectedCrimeType;
  String? _selectedYear;

  // Flags for UI state
  bool _showAnalysis = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedAnalysisType = 'Bar Chart';

  // Variables to hold the data
  Map<String, dynamic>? _analysisData;

  // Chart's GlobalKey for capturing as image
  final GlobalKey _chartKey = GlobalKey();

  // Method to start the auto-scrolling carousel
  void startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage == 4) {
          // Updated to 4 images in the carousel
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

  @override
  void initState() {
    super.initState();
    startAutoScroll();

    _selectedLocation = indianStatesAndTerritories[0];
    _selectedCrimeType = crimeTypes[0];
    _selectedYear = years[0];
    _selectedAnalysisType = 'Bar Chart';
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // UI method to build the home content
  Widget buildHomeContent(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Carousel inside the scrollable area
              Container(
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
              const SizedBox(height: 20),
              // Filter Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Category', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    // Location Dropdown with search (keep it searchable)
                    CustomDropdown(
                      items: indianStatesAndTerritories,
                      selectedValue: _selectedLocation,
                      hint: 'Select Location',
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value;
                        });
                      },
                      isSearchable: true, // Keep this searchable
                    ),
                    const SizedBox(height: 10),
                    // Crime Type Dropdown without search (make it like Year dropdown)
                    CustomDropdown(
                      items: crimeTypes,
                      selectedValue: _selectedCrimeType,
                      hint: 'Select Crime Type',
                      onChanged: (value) {
                        setState(() {
                          _selectedCrimeType = value;
                        });
                      },
                      isSearchable: false, // Make this non-searchable
                    ),
                    const SizedBox(height: 10),
                    // Year Dropdown with search (make it searchable)
                    CustomDropdown(
                      items: years,
                      selectedValue: _selectedYear,
                      hint: 'Select Year',
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                        });
                      },
                      isSearchable: true, // Make this searchable
                    ),
                    SizedBox(height: 20),
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
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.transparent, // Makes the button's background transparent
                          shadowColor: Colors.transparent, // Removes shadow
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          List<String> missingFields = [];

                          if (_selectedLocation == null) {
                            missingFields.add('Location');
                          }
                          if (_selectedYear == null) {
                            missingFields.add('Year');
                          }
                          if (_selectedCrimeType == null) {
                            missingFields.add('Crime Type');
                          }

                          if (missingFields.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Please select: ${missingFields.join(', ')}')),
                            );
                            return; // Exit early if fields are missing
                          }

                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                            _analysisData = null;
                            _showAnalysis = false;
                          });

                          try {
                            // Fetch data from Firestore using AnalysisHelper
                            Map<String, dynamic> data = await AnalysisHelper.fetchCrimeData(
                              crimeType: _selectedCrimeType!,
                              year: _selectedYear!,
                              location: _selectedLocation!,
                            );

                            setState(() {
                              _analysisData = data;
                              _showAnalysis = true;
                              _isLoading = false;
                            });
                          } catch (error) {
                            setState(() {
                              _errorMessage = error.toString().replaceFirst('Exception: ', '');
                              _isLoading = false;
                              _showAnalysis = false;
                            });
                          }
                        },
                        child: const Text('Analyze'),
                      ),
                    ),
                  ],
                ),
              ),
              // Analysis Charts or Error Message
              if (_isLoading)
                Center(
                  child: SpinKitSpinningLines(color: Colors.black),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (_showAnalysis && _analysisData != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Dropdown to select analysis type
                        CustomDropdown(
                          items: ['Bar Chart', 'Pie Chart', 'Line Chart', 'Area Chart'],
                          selectedValue: _selectedAnalysisType,
                          hint: 'Select Analysis Type',
                          onChanged: (value) {
                            setState(() {
                              _selectedAnalysisType = value!;
                            });
                          },
                          isSearchable: false,
                        ),
                        const SizedBox(height: 20),
                        // Build the chart using AnalysisHelper
                        _buildAnalysisCharts(),
                        const SizedBox(height: 20),
                        // Export Button
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(vertical: 0),
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
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.transparent,
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
        ),
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
              title: Text('Save as Image'),
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
              title: Text('Share as Image'),
              onTap: () async {
                Navigator.pop(context);
                await _shareAsImage();
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
    try {

      // Render the chart as image
      final boundary = _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image originalImage = await boundary.toImage(pixelRatio: 3.0);

      // Create a new image with white background
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, originalImage.width.toDouble(), originalImage.height.toDouble()),
        paint,
      );
      canvas.drawImage(originalImage, Offset.zero, Paint());

      final picture = recorder.endRecording();
      final ui.Image finalImage = await picture.toImage(
        originalImage.width,
        originalImage.height,
      );

      final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Get the directory to save the image
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        // On Android 10 and above, getExternalStorageDirectory() returns a directory that's not accessible to the user.
        // Use getExternalStoragePublicDirectory() instead.
        directory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      // Ask user for a file name
      String fileName = 'chart_${DateTime.now().millisecondsSinceEpoch}.png';

      // Save the image
      final String imagePath = '${directory!.path}/$fileName';
      final File imgFile = File(imagePath);
      await imgFile.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chart saved as image at $imagePath'),),
      );
    } catch (e) {
      print('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image: $e')),
      );
    }
  }

  // Method to save chart as PDF
  Future<void> _saveAsPDF() async {
    try {
      // Render the chart as image
      final boundary = _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Create a PDF document
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();

      // Add the image to the PDF
      final PdfBitmap bitmap = PdfBitmap(pngBytes);
      page.graphics.drawImage(
        bitmap,
        Rect.fromLTWH(0, 0, page.getClientSize().width, page.getClientSize().height),
      );

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      // Ask user for a file name
      String fileName = 'chart_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Save the PDF
      final String pdfPath = '${directory!.path}/$fileName';
      final List<int> bytes = await document.save();
      document.dispose();

      final File file = File(pdfPath);
      await file.writeAsBytes(bytes, flush: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chart saved as PDF at $pdfPath')),
      );
    } catch (e) {
      print('Error saving PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF: $e')),
      );
    }
  }

  // Method to share chart as image
  Future<void> _shareAsImage() async {
    try {
      // Render the chart as image
      final boundary = _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image originalImage = await boundary.toImage(pixelRatio: 3.0);

      // Create a new image with white background
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, originalImage.width.toDouble(), originalImage.height.toDouble()),
        paint,
      );
      canvas.drawImage(originalImage, Offset.zero, Paint());

      final picture = recorder.endRecording();
      final ui.Image finalImage = await picture.toImage(
        originalImage.width,
        originalImage.height,
      );

      final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save image temporarily for sharing
      final directory = await getTemporaryDirectory();
      final String imagePath = '${directory.path}/chart_${DateTime.now().millisecondsSinceEpoch}.png';
      final File imgFile = File(imagePath);
      await imgFile.writeAsBytes(pngBytes);

      // Share the image using shareXFiles
      await Share.shareXFiles([XFile(imagePath)], text: 'Check out this chart!');
    } catch (e) {
      print('Error sharing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share image: $e')),
      );
    }
  }

  Widget _buildAnalysisCharts() {
    try {
      if (_analysisData == null || _analysisData!['chartData'] == null) {
        return Center(
          child: Text('No data available to display the chart.'),
        );
      }

      List<CrimeData> chartData = _analysisData!['chartData'];

      // Check if chartData is empty
      if (chartData.isEmpty) {
        return Center(
          child: Text('No data available to display the chart.'),
        );
      }

      return Container(
        height: 400, // Adjust as needed
        child: RepaintBoundary(
          key: _chartKey,
          child: AnalysisHelper.buildChart(
            chartData: chartData,
            analysisType: _selectedAnalysisType,
            chartKey: GlobalKey(),
          ),
        ),
      );
    } catch (e) {
      // Handle any exceptions during chart building
      print('Error building chart: $e');
      return Center(
        child: Text('An error occurred while displaying the chart.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildHomeContent(context);
  }
}
