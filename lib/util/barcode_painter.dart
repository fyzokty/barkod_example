import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:touchable/touchable.dart';

import 'package:barcode_example/util/barcode_paint.dart';

typedef BarcodeCallback = void Function(Barcode barcode);

class BarcodeDetectorPainter extends CustomPainter {
  BarcodeDetectorPainter({
    required this.barcodes,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
    required this.context,
    required this.onBarcodeTap,
  });

  final List<Barcode> barcodes;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final BuildContext context;
  final BarcodeCallback onBarcodeTap;

  Rect? rect;

  @override
  void paint(Canvas canvas, Size size) {
    var myCanvas = TouchyCanvas(context, canvas);
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.red;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0);

    for (final Barcode barcode in barcodes) {
      final barcodePaint = BarcodePaint(
        barcode: barcode,
        canvasSize: size,
        imageSize: imageSize,
        rotation: rotation,
        cameraLensDirection: cameraLensDirection,
      );

      rect = barcodePaint.rect;

      if (rect != null) {
        myCanvas.drawRect(rect!, borderPaint);
        myCanvas.drawRect(
          rect!,
          fillPaint,
          onTapDown: (details) {
            onBarcodeTap.call(barcode);
          },
        );
      }
    }
  }

  @override
  bool shouldRepaint(BarcodeDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.barcodes != barcodes;
  }
}
