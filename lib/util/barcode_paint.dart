// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodePaint {
  final Barcode barcode;
  final Size canvasSize;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  BarcodePaint({
    required this.barcode,
    required this.canvasSize,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
  });

  Rect get rect => Rect.fromLTRB(_left, _top, _right, _bottom);

  double get _left => _translateX(
        barcode.boundingBox.left,
        canvasSize,
        imageSize,
        rotation,
        cameraLensDirection,
      );

  double get _top => _translateY(
        barcode.boundingBox.top,
        canvasSize,
        imageSize,
        rotation,
        cameraLensDirection,
      );

  double get _right => _translateX(
        barcode.boundingBox.right,
        canvasSize,
        imageSize,
        rotation,
        cameraLensDirection,
      );

  double get _bottom => _translateY(
        barcode.boundingBox.bottom,
        canvasSize,
        imageSize,
        rotation,
        cameraLensDirection,
      );

  double _translateX(
    double x,
    Size canvasSize,
    Size imageSize,
    InputImageRotation rotation,
    CameraLensDirection cameraLensDirection,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x * canvasSize.width / (Platform.isIOS ? imageSize.width : imageSize.height);
      case InputImageRotation.rotation270deg:
        return canvasSize.width - x * canvasSize.width / (Platform.isIOS ? imageSize.width : imageSize.height);
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        switch (cameraLensDirection) {
          case CameraLensDirection.back:
            return x * canvasSize.width / imageSize.width;
          default:
            return canvasSize.width - x * canvasSize.width / imageSize.width;
        }
    }
  }

  double _translateY(
    double y,
    Size canvasSize,
    Size imageSize,
    InputImageRotation rotation,
    CameraLensDirection cameraLensDirection,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * canvasSize.height / (Platform.isIOS ? imageSize.height : imageSize.width);
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return y * canvasSize.height / imageSize.height;
    }
  }
}
