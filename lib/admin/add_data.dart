// add_data.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddDataPage extends StatefulWidget {
  @override
  _AddDataPageState createState() => _AddDataPageState();
}

class _AddDataPageState extends State<AddDataPage> {
  bool _isUploading = false;
  String _statusMessage = '';
  File? _selectedFile;

  // Method to explain the CSV format to the user
  Widget _buildCsvFormatExplanation() {
    return Card(
      color: Colors.grey[850],
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Please upload a CSV file with the following columns:\n\n'
              '- crime_type (String)\n'
              '- location (String)\n'
              '- year (Integer)\n'
              '- month (String)\n'
              '- cases (Integer)\n\n'
              'Example:\n'
              'crime_type,location,year,month,cases\n'
              'Theft and Burglary,Delhi,2023,January,50',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  // Method to pick a CSV file
  Future<void> _pickCsvFile() async {
    // Pick the CSV file without requesting storage permissions
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _statusMessage = 'File selected: ${result.files.single.name}';
      });
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file selected.')),
      );
    }
  }

  // Method to process and upload the CSV file
  Future<void> _processAndUploadFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a CSV file first.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Read the file as a string
      final input = await _selectedFile!.openRead();

      // Decode and parse CSV
      final fields = await input
          .transform(utf8.decoder)
          .transform(CsvToListConverter())
          .toList();

      // Validate CSV format
      if (fields.isEmpty) {
        throw Exception('CSV file is empty.');
      }

      // Assuming the first row is the header
      List<String> header = fields[0].map((e) => e.toString()).toList();

      // Required headers
      List<String> requiredHeaders = ['crime_type', 'location', 'year', 'month', 'cases'];

      // Check if required headers are present
      for (String requiredHeader in requiredHeaders) {
        if (!header.contains(requiredHeader)) {
          throw Exception('Missing required column: $requiredHeader');
        }
      }

      List<Map<String, dynamic>> records = [];

      for (int i = 1; i < fields.length; i++) {
        List<dynamic> row = fields[i];
        Map<String, dynamic> record = {};

        for (int j = 0; j < header.length; j++) {
          String key = header[j];
          dynamic value = row[j];

          // Convert value to appropriate type
          if (key == 'year' || key == 'cases') {
            value = int.tryParse(value.toString());
            if (value == null) {
              throw Exception('Invalid integer value in column $key at row ${i + 1}.');
            }
          } else {
            value = value.toString();
          }

          record[key] = value;
        }

        records.add(record);
      }

      // Upload data to Firestore
      await _uploadDataToFirestore(records);

      // Optionally, upload the file to Firebase Storage
      await _uploadFileToStorage(_selectedFile!);

      setState(() {
        _isUploading = false;
        _statusMessage = 'Data upload complete.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data uploaded successfully.')),
      );
    } catch (e) {
      print('Error processing CSV file: $e');
      setState(() {
        _isUploading = false;
        _statusMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Method to upload data to Firestore
  Future<void> _uploadDataToFirestore(List<Map<String, dynamic>> records) async {
    final batchSize = 500;
    WriteBatch batch = FirebaseFirestore.instance.batch();
    int count = 0;

    for (Map<String, dynamic> record in records) {
      // Create a custom document ID (optional)
      String docId = '${record['location']}_${record['crime_type']}_${record['year']}_${record['month']}';
      docId = docId.replaceAll(' ', '_');

      DocumentReference docRef = FirebaseFirestore.instance.collection('data').doc(docId);

      // Add to batch
      batch.set(docRef, record, SetOptions(merge: true));
      count++;

      // Commit batch every 500 writes
      if (count % batchSize == 0) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
      }
    }

    // Commit any remaining writes
    if (count % batchSize != 0) {
      await batch.commit();
    }
  }

  // Method to upload the file to Firebase Storage (optional)
  Future<void> _uploadFileToStorage(File file) async {
    try {
      String fileName = 'uploaded_files/${DateTime.now().millisecondsSinceEpoch}.csv';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      await storageRef.putFile(file);
      print('File uploaded to Firebase Storage at $fileName');
    } catch (e) {
      print('Error uploading file to Firebase Storage: $e');
    }
  }

  // Method to view data in Firestore
  Future<void> _viewData() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('data').get();

      List<Map<String, dynamic>> records = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      String jsonData = JsonEncoder.withIndent('  ').convert(records);

      // Show data in a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text('data collection', style: TextStyle(color: Colors.purple[100])),
          content: SingleChildScrollView(
            child: Text(jsonData, style: TextStyle(color: Colors.white)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background color to dark
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('Add Data',
          style: TextStyle(
          color: Colors.white,
          letterSpacing: 4,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        ),
        backgroundColor: Colors.grey[900], // Dark app bar
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: _isUploading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpinKitSpinningLines(
                color: Theme.of(context).primaryColor,
                size: 100.0,
              ),
              SizedBox(height: 20),
              Text('Processing...', style: TextStyle(color: Colors.white)),
            ],
          ),
        )
            : SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCsvFormatExplanation(),
                  SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                    ),
                    onPressed: _pickCsvFile,
                    child: Text('Select CSV File', style: TextStyle(color: Colors.black),),
                  ),
                  SizedBox(height: 5),
                  Text(
                    _statusMessage,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 5),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                    ),
                    onPressed: _processAndUploadFile,
                    child: Text('Add Data', style: TextStyle(color: Colors.black),),
                  ),
                ],
              ),
              SizedBox(height: 180),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[400],
                ),
                onPressed: _viewData,
                child: Text('View Current Crime Data', style: TextStyle(fontSize: 15),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
