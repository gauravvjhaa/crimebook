// loader.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

void showLoader(BuildContext context, int seconds, VoidCallback onComplete) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/delhi-blast.jpeg'),
                  fit: BoxFit.cover,
                  opacity: 0.6,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.withOpacity(0.85),
                      Colors.blue.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SpinKitFadingCircle(
                    color: Colors.black,
                    size: 50.0,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Loading',
                    style: GoogleFonts.lato(
                      textStyle: const TextStyle(
                        fontSize: 24.0,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  // Close the loader after the specified number of seconds
  Future.delayed(Duration(seconds: seconds), () {
    Navigator.of(context).pop(); // Closes the dialog
    onComplete(); // Calls the callback to perform the next action
  });
}
