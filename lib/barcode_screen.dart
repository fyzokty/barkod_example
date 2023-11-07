import 'package:barcode_example/barcode_view.dart';
import 'package:barcode_example/widget/draggable_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  DraggableScrollableController controller = DraggableScrollableController();

  bool isExpanded = false;

  Barcode? selectedBarcode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomSheet: DraggableScrollableSheet(
        controller: controller,
        maxChildSize: 1,
        minChildSize: 0.2,
        expand: false,
        snap: true,
        snapSizes: const [0.2, 1],
        initialChildSize: 0.2,
        snapAnimationDuration: const Duration(milliseconds: 300),
        shouldCloseOnMinExtent: false,
        builder: (context, scrollController) {
          return DraggableSheet(
            scrollController: scrollController,
            barcode: selectedBarcode,
          );
        },
      ),
      appBar: AppBar(),
      body: BarcodeView(
        onBarcodeTap: (barcode) {
          controller.animateTo(1, duration: const Duration(milliseconds: 300), curve: Curves.fastOutSlowIn);
          selectedBarcode = barcode;
          setState(() {});
        },
      ),
    );
  }

  void draggableListener() {
    if (controller.size == 1) {
      isExpanded = true;
    } else {
      isExpanded = false;
    }
  }
}
