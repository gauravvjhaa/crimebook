import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AssistantGemini extends StatefulWidget {
  @override
  _AssistantGeminiState createState() => _AssistantGeminiState();
}

class _AssistantGeminiState extends State<AssistantGemini> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add({"sender": "You", "message": message});
      _isLoading = true;
    });
    _controller.clear();

    final response = await talkToGemini(message);
    setState(() {
      if (response != null) {
        _messages.add({"sender": "Gemini", "message": response});
      } else {
        _messages.add({"sender": "Gemini", "message": "No response"});
      }
      _isLoading = false;
    });
  }

  Future<String?> talkToGemini(String message) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey',
    );

    final headers = {
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": message}
          ]
        }
      ]
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      // Log entire response body, status code, and reason phrase
      print('Response Status Code: ${response.statusCode}');
      print('Response Reason Phrase: ${response.reasonPhrase}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Print all keys in the response for inspection
        data.forEach((key, value) => print('Response Key: $key, Value: $value'));

        // Attempt to parse specific fields based on inspection of response structure
        // Replace 'generatedContent' with the correct key as per the actual response
        return data['generatedContent'] ?? "No response content available";
      } else {
        print('Bard Content Generation Error: ${response.statusCode} ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('Error during request: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Assistant Gemini")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(
                    message["message"] ?? '',
                    style: TextStyle(
                      color: message["sender"] == "You" ? Colors.blue : Colors.green,
                    ),
                  ),
                  subtitle: Text(message["sender"] ?? ''),
                );
              },
            ),
          ),
          if (_isLoading) CircularProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: "Type a message..."),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
