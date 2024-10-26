import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScannerScreen extends StatelessWidget {
  final Function(String) onScanned;

  QRScannerScreen({required this.onScanned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan QR Code')),
      body: QRView(
        key: GlobalKey(debugLabel: 'QR'),
        onQRViewCreated: (QRViewController controller) {
          controller.scannedDataStream.listen((scanData) {
            // Check if scanned code is not null and not empty
            if (scanData.code != null && scanData.code!.isNotEmpty) {
              _showConfirmationDialog(context, scanData.code!);
              // Stop scanning after getting a valid scan
              controller.pauseCamera();
            } else {
              // Show a dialog or a snackbar if the scanned data is invalid
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Scanned data is empty or invalid. Please scan a valid QR code.'),
                ),
              );
            }
          });
        },
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, String scannedData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Scanned Data'),
          content: Text('Scanned Data: $scannedData'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                onScanned(scannedData); // Call the onScanned callback with valid data
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Close the scanner screen
              },
            ),
          ],
        );
      },
    );
  }
}
