import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class DraggableSheet extends StatelessWidget {
  const DraggableSheet({super.key, required this.scrollController, required this.barcode});

  final ScrollController scrollController;
  final Barcode? barcode;

  @override
  Widget build(BuildContext context) {
    bool isBarcodeNull = barcode == null;
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Barkod'),
          isBarcodeNull ? const SizedBox() : Text('Barkod: ${barcode!.rawValue}'),
        ],
      ),
    );
  }
}
