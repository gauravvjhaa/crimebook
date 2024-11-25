// alert_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../components/colors_file.dart';

enum Severity {
  high,
  medium,
  low,
}

class CrimeAlert {
  final String warningMessage;
  final String summary;
  final String location;
  final DateTime date;
  final String url;
  final Severity severity;
  final String safetyTip;

  CrimeAlert({
    required this.warningMessage,
    required this.summary,
    required this.location,
    required this.date,
    required this.url,
    required this.severity,
    required this.safetyTip,
  });
}

class AlertScreen extends StatefulWidget {
  @override
  _AlertScreenState createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final Gemini gemini = Gemini.instance;

  final TextEditingController _locationController = TextEditingController();
  String? userLocation;
  List<CrimeAlert> crimeAlerts = [];
  bool isLoading = false;

  final String newsApiKey = dotenv.env['NEWS_API_KEY'] ?? '';

  final List<String> severeCrimeKeywords = [
    "death",
    "rape",
    "assault",
    "theft",
    "murder",
    "homicide",
    "kidnapping",
    "violence"
  ];

  @override
  void initState() {
    super.initState();
    _loadUserState();
  }

  Future<void> _loadUserState() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userLocation = userData['state'];
          _locationController.text = userLocation ?? '';
        });
        if (userLocation != null && userLocation!.isNotEmpty) {
          fetchAndProcessCrimeNews(userLocation!);
        }
      }
    }
  }

  Future<void> fetchAndProcessCrimeNews(String location) async {
    setState(() {
      isLoading = true;
    });

    final oneMonthAgo = DateTime.now().subtract(Duration(days: 30)).toIso8601String();
    final apiUrl =
        'https://newsapi.org/v2/everything?q=$location crime&from=$oneMonthAgo&language=en&apiKey=$newsApiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        // Filter articles by conditions, and limit to 2 results
        List articles = (data['articles'] as List).where((article) {
          final title = article['title']?.toLowerCase() ?? '';
          return severeCrimeKeywords.any((keyword) => title.contains(keyword)) &&
              title.contains(location.toLowerCase());
        }).take(2).toList();

        List<CrimeAlert> alerts = [];
        for (var article in articles) {
          final title = article['title'] ?? '';
          final summary = article['description'] ?? '';
          final url = article['url'] ?? '';
          final publishedAt = article['publishedAt'] ?? '';

          // Generate Gemini warning message and safety tip
          String? warningMessage = await generateWarningMessageWithGemini(title, location);
          String? safetyTip = await generateSafetyTipWithGemini(title, location);

          alerts.add(CrimeAlert(
            warningMessage: warningMessage ?? "Please stay vigilant and follow the necessary precautions",
            summary: summary,
            location: location,
            date: DateTime.parse(publishedAt),
            url: url,
            severity: Severity.high,
            safetyTip: safetyTip ?? "Please stay vigilant and follow the necessary precautions",
          ));
        }

        setState(() {
          crimeAlerts = alerts;
          isLoading = false;
        });
      } else {
        _showErrorSnackBar('Error fetching news: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      _showErrorSnackBar('Error fetching crime news: $error');
      setState(() {
        isLoading = false;
      });
    }
  }




  /// Generate a custom warning message using Gemini based on the news title and location.
  Future<String?> generateWarningMessageWithGemini(String title, String location) async {
    try {
      final response = await gemini.text(
          "Create a personalized warning message based on the following title: '$title' for incidents in '$location'. Keep it direct, like: 'Look at this incident in your city.' and also make sure to keep it concise, and it should sound good too, don't use '*' unnecessarily, okay?  ");
      return response?.output?.trim();
    } catch (e) {
      return null;
    }
  }

  /// Generate a realistic safety tip using Gemini for the specific crime and location.
  Future<String?> generateSafetyTipWithGemini(String title, String location) async {
    try {
      final response = await gemini.text(
          "Given the crime titled '$title' in '$location', provide one realistic, actionable safety tip but just the tip and no header and nothing.");
      return response?.output?.trim();
    } catch (e) {
      return null;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
        color: isDarkMode ? Colors.grey[350] : Colors.white,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '   Safety Alerts!',
                style: GoogleFonts.poppins(
                  color: isDarkMode ? darkModeHead : lightModeHead,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildLocationInput(),
            Expanded(
              child: isLoading ? _buildLoadingIndicators() : _buildAlertsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInput() {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _locationController,
        decoration: InputDecoration(
          labelText: 'Enter your city/state',
          border: OutlineInputBorder(),
          suffixIcon: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.black87 : Colors.blue,
            ),
            onPressed: () {
              String location = _locationController.text.trim();
              if (location.isNotEmpty) {
                _saveUserState(location);
                fetchAndProcessCrimeNews(location);
              } else {
                _showErrorSnackBar('Please enter a valid location');
              }
            },
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicators() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SpinKitSpinningLines(color: Colors.blue, size: 50),
        SizedBox(height: 20),
        SingleChildScrollView(
          child: _buildShimmerEffect(),
        ),
      ],
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 5,
        itemBuilder: (context, index) => _buildShimmerItem(),
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 60.0, height: 60.0, color: Colors.white),
          SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: double.infinity, height: 15.0, color: Colors.white),
                const SizedBox(height: 5.0),
                Container(width: double.infinity, height: 15.0, color: Colors.white),
                const SizedBox(height: 5.0),
                Container(width: 150.0, height: 15.0, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    if (crimeAlerts.isEmpty) {
      return Center(child: Text('No safety alerts available for this location.'));
    }

    return ListView.builder(
      itemCount: crimeAlerts.length,
      itemBuilder: (context, index) {
        return _buildAlertCard(crimeAlerts[index]);
      },
    );
  }

  Widget _buildAlertCard(CrimeAlert alert) {
    Color cardColor;
    Color borderColor;
    IconData iconData;

    switch (alert.severity) {
      case Severity.high:
        cardColor = Colors.red[50]!;
        borderColor = Colors.red;
        iconData = Icons.error;
        break;
      case Severity.medium:
        cardColor = Colors.orange[50]!;
        borderColor = Colors.orange;
        iconData = Icons.warning;
        break;
      case Severity.low:
      default:
        cardColor = Colors.yellow[50]!;
        borderColor = Colors.yellow[700]!;
        iconData = Icons.info;
        break;
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: borderColor, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.warningMessage,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Text(alert.location),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          Text('${alert.date.toLocal().toIso8601String().split('T')[0]}'),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.open_in_new),
                      onPressed: () {
                        Uri uri = Uri.parse(alert.url);
                        _launchInWebView(uri);
                      },
                    ),
                    IconButton(
                        icon: Icon(Icons.share),
                        onPressed: () => _shareAlert(alert)),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(alert.safetyTip, style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUserState(String state) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'state': state});
    }
  }

  Future<void> _launchInWebView(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
      throw Exception('Could not launch $url');
    }
  }

  void _shareAlert(CrimeAlert alert) {
    Share.share(
      '''
Hey! Check out this Safety Alert: ${alert.url}
''',
      subject: 'Safety Alert for ${alert.location}',
    );
  }
}
