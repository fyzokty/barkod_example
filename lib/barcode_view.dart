import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:touchable/touchable.dart';

import 'package:barcode_example/util/barcode_painter.dart';

class BarcodeView extends StatefulWidget {
  const BarcodeView({super.key, required this.onBarcodeTap});

  final BarcodeCallback onBarcodeTap;

  @override
  State<BarcodeView> createState() => _BarcodeViewState();
}

class _BarcodeViewState extends State<BarcodeView> {
  late Timer timer;

  bool isBusy = false;
  bool canProcess = true;
  BarcodeScanner barcodeScanner = BarcodeScanner();

  bool isPermissionDenied = false;
  bool isCameraInitialize = false;
  List<CameraDescription> cameras = [];
  List<CameraDescription> backCameras = [];

  late CameraDescription camera;
  late CameraController cameraController;
  int cameraIndex = -1;

  final _cameraLensDirection = CameraLensDirection.back;

  List<Barcode> _barcodes = [];
  InputImage? _inputImage;

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    timer = Timer(Duration.zero, () {});
    initCamera();
    super.initState();
  }

  @override
  void dispose() {
    stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (isPermissionDenied) return const Center(child: Text('Kamera kullanmak için izin gerekiyor'));
        if (cameras.isEmpty && isCameraInitialize) return const Center(child: Text('Kamera Bulunamadı'));
        if (cameras.isEmpty && !isCameraInitialize) return const Center(child: Text('Kamera Başlatılıyor'));
        if (cameraController.value.isInitialized == false) return const Center(child: Text("Kamera Başlatılamadı"));
        return Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: CameraPreview(
                cameraController,
                child: _inputImage != null
                    ? Positioned.fill(
                        child: CanvasTouchDetector(
                          gesturesToOverride: const [GestureType.onTapDown, GestureType.onTapUp],
                          builder: (context) {
                            return CustomPaint(
                              painter: BarcodeDetectorPainter(
                                context: context,
                                barcodes: _barcodes,
                                imageSize: _inputImage!.metadata!.size,
                                rotation: _inputImage!.metadata!.rotation,
                                cameraLensDirection: _cameraLensDirection,
                                onBarcodeTap: widget.onBarcodeTap,
                              ),
                            );
                          },
                        ),
                      )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> initCamera() async {
    log("CAMERA INIT");
    if (cameras.isEmpty) {
      cameras = await availableCameras();
      log("KAMERA SAYISI ======> ${cameras.length}");
      for (var c in cameras) {
        log("KAMERA ADI: ${c.name} |||| KAMERA YÖNÜ: ${c.lensDirection} |||| KAMERA AÇISI: ${c.sensorOrientation}");
      }
    }
    for (var i = 0; i < cameras.length; i++) {
      if (cameras[i].lensDirection == CameraLensDirection.back) {
        backCameras.add(cameras[i]);
        if (cameraIndex == -1) {
          cameraIndex = i;
          camera = cameras[i];
          log("KAMERA INDEX =====> $cameraIndex");
          log("SEÇİLEN KAMERA =====> $camera");
        }
      }
    }
    isCameraInitialize = true;
    if (cameraIndex == -1 || cameras.isEmpty) {
      log("KAMERA BULUNAMADI");
      Navigator.of(context).pop();
      return;
    }
    await startCamera();
  }

  Future<void> startCamera() async {
    if (cameraIndex == -1) {
      return;
    }
    final imageFormatGroup = Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888;
    cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      imageFormatGroup: imageFormatGroup,
      enableAudio: false,
    );

    cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      cameraController.lockCaptureOrientation(DeviceOrientation.portraitUp);
      cameraController.startImageStream(processImage);
    }).catchError((e) {
      // TODO(fyzokty): Permission Handler kullan
      if (e is CameraException) {
        e.code == 'CameraAccessDenied';
        isPermissionDenied = true;
      }
      log(e.toString());
    });
  }

  Future<void> stopCamera() async {
    await cameraController.stopImageStream().catchError((e) => log(e.toString()));
    await cameraController.dispose();
  }

  void processImage(CameraImage cameraImage) async {
    if (!canProcess) return;
    if (timer.isActive) return;
    timer = Timer(const Duration(milliseconds: 200), () {
      canProcess = true;
    });
    canProcess = false;
    final inputImage = cameraToInput(cameraImage);
    if (inputImage == null) return;
    await processUIImage(inputImage);
  }

  Future<void> processUIImage(InputImage inputImage) async {
    if (isBusy) return;
    isBusy = true;
    final barcodes = await barcodeScanner.processImage(inputImage);
    if (!mounted) return;
    if (inputImage.metadata?.size != null && inputImage.metadata?.rotation != null) {
      _inputImage = inputImage;
      _barcodes = barcodes;
    }
    isBusy = false;
    if (mounted) {
      setState(() {});
    }
    if (barcodes.isEmpty) return;
  }

  InputImage? cameraToInput(CameraImage cameraImage) {
    if (cameraImage.planes.length != 1) return null;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[cameraController.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);
    if (format == null || (Platform.isAndroid && format != InputImageFormat.nv21) || (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    final plane = cameraImage.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }
}
