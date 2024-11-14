// export.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class ExportHelper {
  // Method to save chart as image
  static Future<void> saveChartAsImage(
      GlobalKey<SfCartesianChartState> chartKey, BuildContext context) async {
    // Request storage permission
    if (await _requestPermission(Permission.storage)) {
      try {
        // Capture chart as image
        final image = await chartKey.currentState!.toImage(pixelRatio: 3.0);
        final bytes = await image?.toByteData(format: ImageByteFormat.png);
        final buffer = bytes!.buffer.asUint8List();

        // Get save path from user
        final directory = await getExternalStorageDirectory();
        String path = directory!.path;
        String fileName = 'chart_${DateTime.now().millisecondsSinceEpoch}.png';
        File file = File('$path/$fileName');

        // Save the file
        await file.writeAsBytes(buffer);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chart saved as image at $path/$fileName')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e')),
        );
      }
    }
  }

  // Method to save chart as PDF
  static Future<void> saveChartAsPDF(
      GlobalKey<SfCartesianChartState> chartKey, BuildContext context) async {
    // Request storage permission
    if (await _requestPermission(Permission.storage)) {
      try {
        // Capture chart as image
        final image = await chartKey.currentState!.toImage(pixelRatio: 3.0);
        final bytes = await image?.toByteData(format: ImageByteFormat.png);
        final buffer = bytes!.buffer.asUint8List();

        // Create PDF document
        final pdf = pw.Document();
        final pdfImage = pw.MemoryImage(buffer);

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(pdfImage),
              );
            },
          ),
        );

        // Get save path from user
        final directory = await getExternalStorageDirectory();
        String path = directory!.path;
        String fileName = 'chart_${DateTime.now().millisecondsSinceEpoch}.pdf';
        File file = File('$path/$fileName');

        // Save the file
        await file.writeAsBytes(await pdf.save());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chart saved as PDF at $path/$fileName')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving PDF: $e')),
        );
      }
    }
  }

  // Helper method to request permissions
  static Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      return result == PermissionStatus.granted;
    }
  }
}
