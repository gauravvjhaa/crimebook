// news_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crimebook/components/colors_file.dart';

class NewsDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    // bool isDarkMode = true;
    final Map<String, dynamic>? newsItem = Get.arguments;

    Future<void> _launchInWebView(Uri url) async {
      if (!await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
        throw Exception('Could not launch $url');
      }
    }

    Future<void> _launchUri(String link) async {
      Uri uri = Uri.parse(link);
      _launchInWebView(uri);
    }

    // Debug print to check if newsItem is received
    print("NewsDetailScreen: Received newsItem: $newsItem");

    // If newsItem is null, show an error message
    if (newsItem == null) {
      return Scaffold(
        backgroundColor: Colors.blue[100], // Apply background color
        body: Center(
          child: Text(
            'No news data available.',
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
        ),
      );
    }

    // Extract URL for sharing and reading full article
    final String? articleUrl = newsItem['url'];

    // Debug print to check articleUrl
    print("NewsDetailScreen: articleUrl: $articleUrl");

    return Scaffold(
      backgroundColor: Colors.blue[100], // Apply background color
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 80), // Space for share button
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Article Image
              newsItem['urlToImage'] != null &&
                      newsItem['urlToImage'].isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: newsItem['urlToImage'],
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: Center(child: Text('No Image Available')),
                      ),
                    )
                  : Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: Center(child: Text('No Image Available')),
                    ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Article Title
                    Text(
                      newsItem['title'] ?? 'No Title',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    // Publication Date and Source
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[600]),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Published at: ${newsItem['publishedAt'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 15),
                        Icon(Icons.source, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Source: ${newsItem['source']['name'] ?? 'Unknown'}',
                            style: TextStyle(color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Article Description
                    Text(
                      newsItem['description'] ?? 'No Description',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    SizedBox(height: 20),
                    // Article Content
                    Text(
                      newsItem['content'] ?? 'No Content Available',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    SizedBox(height: 20),
                    // "Read Full Article" Button (Standard ElevatedButton)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            if (articleUrl != null && articleUrl.isNotEmpty) {
                              Share.share(articleUrl);
                            } else {
                              Get.snackbar(
                                'Error',
                                'No URL available to share.',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.redAccent,
                                colorText: Colors.white,
                              );
                            }
                          },
                          icon: Icon(Icons.share, color: Colors.white),
                          label: Text(
                            '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDarkMode ? Color(0xFF0C0D10) : Colors.blue,
                            foregroundColor:
                                Colors.white, // Icon and text color
                            padding: EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12), // Enhanced padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  10), // Increased border radius for a pill shape
                            ),
                            elevation: 0, // Subtle shadow for depth
                            shadowColor: Colors.pinkAccent.withOpacity(
                                0.5), // Shadow color matching the button
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (articleUrl != null && articleUrl.isNotEmpty) {
                              await _launchUri(articleUrl);
                            } else {
                              Get.snackbar('Error', 'No URL available to open.',
                                  snackPosition: SnackPosition.BOTTOM);
                            }
                          },
                          icon:
                              Icon(Icons.open_in_browser, color: Colors.white),
                          label: Text(
                            'Read Full Article',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                isDarkMode ? Color(0xFF0C0D10) : Colors.blue,
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
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
}
