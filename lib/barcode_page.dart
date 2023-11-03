import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodePage extends StatefulWidget {
  const BarcodePage({super.key});

  @override
  State<BarcodePage> createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  bool isBusy = false;
  bool canProcess = true;
  BarcodeScanner barcodeScanner = BarcodeScanner();

  bool isCameraInitialize = false;
  List<CameraDescription> cameras = [];
  List<CameraDescription> backCameras = [];
  List<CameraDescription> frontCameras = [];

  late CameraDescription camera;
  int cameraIndex = -1;
  late CameraController cameraController;

  @override
  void initState() {
    initCamera();
    super.initState();
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
      if (cameras[i].lensDirection == CameraLensDirection.front) {
        frontCameras.add(cameras[i]);
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

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Builder(
        builder: (context) {
          if (cameras.isEmpty && isCameraInitialize) return const Center(child: Text('Kamera Bulunamadı'));
          if (cameras.isEmpty && !isCameraInitialize) return const Center(child: Text('Kamera Başlatılıyor'));
          if (cameraController.value.isInitialized == false) return const Center(child: Text("Kamera Başlatılamadı"));
          return Stack(
            children: [
              Center(child: CameraPreview(cameraController)),
            ],
          );
        },
      ),
    );
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

    cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {});
      cameraController.startImageStream(processImage);
    });
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  void processImage(CameraImage cameraImage) async {
    final inputImage = cameraToInput(cameraImage);
    if (inputImage == null) return;
    await processUIImage(inputImage);
  }

  Future<void> processUIImage(InputImage inputImage) async {
    if (isBusy) return;
    isBusy = true;

    final barcodes = await barcodeScanner.processImage(inputImage);

    log(barcodes.toString());
    log("BARCODE LENGHT =======> ${barcodes.length}");

    isBusy = false;
    if (barcodes.isEmpty) return;
    log("BARKOD::: ${barcodes.first.rawValue}");
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
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      // print('rotationCompensation: $rotationCompensation');
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
