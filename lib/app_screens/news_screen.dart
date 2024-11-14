import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:crimebook/components/colors_file.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/services.dart';

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  // bool isDarkMode = true;
  bool _isLoading = true;
  List<dynamic> _newsData = [];
  List<String> _userKeywords = [];
  List<String> _userSources = [];
  List<String> _userCategories = [];
  List<Map<String, dynamic>> _availableSources = [];
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  String apiKey = dotenv.env['NEWS_API_KEY'] ?? '';

  // New variables for pagination
  int _totalResults = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();

    fetchAvailableSources();
    fetchUserPreferences(); // Fetch user's preferences from Firestore
  }

  // Fetch available news sources from NewsAPI
  Future<void> fetchAvailableSources() async {
    final uri = Uri.parse(
        'https://newsapi.org/v2/top-headlines/sources?apiKey=$apiKey');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _availableSources = List<Map<String, dynamic>>.from(data['sources']);
        });
      } else {
        print('Failed to load sources: ${response.statusCode}');
        // Optionally, inform the user about the error

      }
    } catch (e) {
      print('Error fetching sources: $e');
      // Optionally, inform the user about the error

    }
  }

  // Fetch user preferences from Firestore
  Future<void> fetchUserPreferences() async {
    setState(() {
      _isLoading = true; // Show shimmer while fetching preferences
    });

    try {
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(user!.uid).get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        var preferences = data['preferences'] ?? {};

        List<String> userKeywords =
            List<String>.from(preferences['keywords'] ?? []);
        List<String> userSources =
            List<String>.from(preferences['sources'] ?? []);
        List<String> userCategories =
            List<String>.from(preferences['categories'] ?? []);

        setState(() {
          _userKeywords = userKeywords;
          _userSources = userSources;
          _userCategories = userCategories;
        });

        // Fetch news based on preferences
        await fetchNews(_userCategories, _userSources, _userKeywords);
      } else {
        // Handle case where user data doesn't exist
        await fetchNews(); // Fetch default news
      }
    } catch (e) {
      print("Error fetching preferences: $e");
      // Optionally, show an error message to the user

      await fetchNews(); // Fetch default news if an error occurs
    }
  }

  Future<void> fetchNews(
      [List<String>? categories,
        List<String>? sources,
        List<String>? keywords,
        int page = 1]) async {
    setState(() {
      _isLoading = true; // Show shimmer during news loading
    });

    String baseUrl = 'https://newsapi.org/v2/everything';

    Map<String, String> queryParameters = {
      'page': page.toString(),
      'pageSize': _pageSize.toString(),
      'apiKey': apiKey,
    };

    // Start with "crime" as a must-have keyword
    String mandatoryQuery = 'crime';

    // If there are categories, add them to the query
    if (categories != null && categories.isNotEmpty) {
      mandatoryQuery += ' AND (${categories.join(' OR ')})';
    }

    // If there are keywords, add them to the query
    if (keywords != null && keywords.isNotEmpty) {
      mandatoryQuery += ' AND (${keywords.join(' OR ')})';
    }

    // Add the combined mandatory query to the query parameters
    queryParameters['q'] = mandatoryQuery;

    // Add sources if provided
    if (sources != null && sources.isNotEmpty) {
      queryParameters['sources'] = sources.join(',');
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    print("Fetching news from URL: $uri");

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> articles = data['articles'];
        int total = data['totalResults'] ?? 0;

        // Shuffle the articles to add randomness
        articles.shuffle(Random());

        setState(() {
          _newsData = articles;
          _isLoading = false; // Stop showing shimmer after loading
          _totalResults = total;
        });
      } else {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load news');
      }
    } catch (e) {
      print('Error fetching news: $e');

      setState(() {
        _isLoading = false;
      });
    }
  }


  // Handle refresh with random page selection
  Future<void> _handleRefresh() async {
    if (_totalResults == 0) {
      await fetchUserPreferences(); // Initial fetch to get totalResults
      return;
    }

    int totalPages = (_totalResults / _pageSize).ceil();

    // Limit totalPages to a reasonable number to prevent excessive API calls
    totalPages = totalPages > 5 ? 5 : totalPages;

    // Generate a random page number between 1 and totalPages
    final random = Random();
    int randomPage = random.nextInt(totalPages) + 1;

    print('Refreshing with page number: $randomPage');

    await fetchNews(_userCategories, _userSources, _userKeywords, randomPage);
  }

  // Show Preferences Dialog
  void _showInterestsDialog(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    List<String> _tempKeywords = List.from(_userKeywords);
    List<String> _tempSources = List.from(_userSources);
    List<String> _tempCategories = List.from(_userCategories);
    TextEditingController _keywordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Rounded corners
              ),
              child: Container(
                // Set a fixed height or max height to ensure the dialog doesn't become too large
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dialog Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Manage Preferences',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Divider(height: 1),
                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Keywords Section
                            Text(
                              'Keywords',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: _tempKeywords.map((keyword) {
                                return Chip(
                                  label: Text(keyword),
                                  deleteIcon: Icon(Icons.close),
                                  onDeleted: () {
                                    setStateDialog(() {
                                      _tempKeywords.remove(keyword);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            TextField(
                              controller: _keywordController,
                              decoration: InputDecoration(
                                labelText: 'Add Keyword',
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    if (_keywordController.text
                                        .trim()
                                        .isNotEmpty) {
                                      setStateDialog(() {
                                        _tempKeywords.add(
                                            _keywordController.text.trim());
                                        _keywordController.clear();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            // Sources Section
                            Text(
                              'Sources',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            _availableSources.isEmpty
                                ? Center(child: CircularProgressIndicator())
                                : Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: _availableSources.map((source) {
                                      final isSelected =
                                          _tempSources.contains(source['id']);
                                      return FilterChip(
                                        label: Text(source['name']),
                                        selected: isSelected,
                                        onSelected: (bool selected) {
                                          setStateDialog(() {
                                            if (selected) {
                                              _tempSources.add(source['id']);
                                            } else {
                                              _tempSources.remove(source['id']);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                            SizedBox(height: 20),
                            // Categories Section
                            Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: _buildCategoryChips(
                                  _tempCategories, setStateDialog),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1),
                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Cancel Button
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the dialog
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.redAccent,
                              ),
                            ),
                          ),
                          // Save Button
                          ElevatedButton(
                            onPressed: () {
                              _savePreferences(
                                  _tempKeywords, _tempSources, _tempCategories);
                              Navigator.pop(context); // Close the dialog
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('Preferences Updated'),
                                duration: Duration(seconds: 2),
                              ));
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor:
                                  isDarkMode ? Color(0xFF0C0D10) : Colors.blue,
                            ),
                            child: Text('Save'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Modify the _buildCategoryChips to accept the dialog's setState
  List<Widget> _buildCategoryChips(List<String> selectedCategories,
      void Function(void Function()) setStateDialog) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    List<String> availableCategories = [
      'business',
      'entertainment',
      'general',
      'health',
      'science',
      'sports',
      'technology',
      'crime',
      'justice',
      'politics',
      'law',
    ]; // Categories related to news

    return availableCategories.map((category) {
      final isSelected = selectedCategories.contains(category);
      return FilterChip(
        label: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
        selected: isSelected,
        backgroundColor: Colors.grey[300],
        selectedColor: isDarkMode ? Color(0xFF0C0D10) : Colors.blue,
        onSelected: (bool selected) {
          setStateDialog(() {
            if (selected) {
              selectedCategories.add(category);
            } else {
              selectedCategories.remove(category);
            }
          });
        },
        showCheckmark: false,
      );
    }).toList();
  }

  // Save preferences to Firestore
  Future<void> _savePreferences(List<String> keywords, List<String> sources,
      List<String> categories) async {
    try {
      await firestore.collection('users').doc(user!.uid).update({
        'preferences': {
          'keywords': keywords,
          'sources': sources,
          'categories': categories,
        }
      });

      setState(() {
        _userKeywords = keywords;
        _userSources = sources;
        _userCategories = categories;
      });

      // Fetch news based on new preferences
      await fetchNews(categories, sources, keywords);
    } catch (e) {
      print("Error saving preferences: $e");
      // Optionally, show an error message to the user

    }
  }

  // Method to build news content
  Widget buildNewsContent(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                _showInterestsDialog(context);
              },
              icon: Icon(Icons.tune),
              label: Text('Preferences'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: isDarkMode ? Color(0xFF0C0D10) : Colors.blue,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '  Discover',
              style: GoogleFonts.poppins(
                color: isDarkMode ? darkModeHead : lightModeHead,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 10),
          // News Articles
          Expanded(
            child: _isLoading
                ? buildShimmer()
                : _newsData.isEmpty
                    ? Center(child: Text('No news available'))
                    : RefreshIndicator(
                        onRefresh:
                            _handleRefresh, // Use the new refresh handler
                        child: ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(), // Ensures the list is scrollable even if content is less
                          itemCount: _newsData.length,
                          itemBuilder: (context, index) {
                            final newsItem = _newsData[index];
                            return GestureDetector(
                              onTap: () {
                                Get.toNamed('/particularNews',
                                    arguments:
                                        newsItem); // Pass the entire newsItem
                              },
                              child: Card(
                                margin:
                                    const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    newsItem['urlToImage'] != null &&
                                            newsItem['urlToImage'].isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: newsItem['urlToImage'],
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                              height: 200,
                                              color: isDarkMode? darkModeBody : lightModeBody,
                                              child: Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                              height: 200,
                                              color: Colors.grey[300],
                                              child: Center(
                                                  child: Text('No Image')),
                                            ),
                                          )
                                        : Container(
                                            height: 200,
                                            color: Colors.grey[300],
                                            child:
                                                Center(child: Text('No Image')),
                                          ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            newsItem['title'] ??
                                                'No title available',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18),
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today,
                                                  size: 14,
                                                  color: Colors.grey[600]),
                                              SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  'Published at: ${newsItem['publishedAt'] != null ? DateFormat.yMMMd().add_jm().format(DateTime.parse(newsItem['publishedAt'])) : 'N/A'}',
                                                  style: TextStyle(
                                                      color: Colors.grey[600]),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Icon(Icons.source,
                                                  size: 14,
                                                  color: Colors.grey[600]),
                                              SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  '${newsItem['source']['name'] ?? 'Unknown'}',
                                                  style: TextStyle(
                                                      color: Colors.grey[600]),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            newsItem['description'] ??
                                                'No description available',
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: TextButton(
                                              onPressed: () {
                                                Get.toNamed('/particularNews',
                                                    arguments: newsItem);
                                              },
                                              child: const Text('Read more...'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Shimmer placeholder while loading
  Widget buildShimmer() {
    return ListView.builder(
      itemCount: 5, // Number of shimmer placeholders
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  color: Colors.grey,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: double.infinity,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 20,
                        width: 150,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 20,
                        width: 100,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: buildNewsContent(context),
    );
  }
}
