import 'dart:developer';

import 'package:barcode_example/barcode_page.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barkod Deneme'),
      ),
      body: Column(
        children: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).push<List<Barcode>?>(MaterialPageRoute(builder: (context) => const BarcodePage())).then((value) {
                if (value != null && value.isNotEmpty) {
                  for (var b in value) {
                    log("FORMAT: ${b.format}\nDISPLAY VALUE: ${b.displayValue}\nRAW VALUE: ${b.rawValue}\nBARCODE TYPE: ${b.type}\nBARCODE VALUE: ${b.value}");
                  }
                }
              });
            },
            child: const Text('Barkod'),
          ),
        ],
      ),
    );
  }
}
