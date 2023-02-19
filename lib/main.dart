import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Boston Fiesta',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const ScannerPage(),
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Barcode? barcode;
  String? result;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() async {
    super.reassemble();
    if (Platform.isAndroid) {
      await controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Theme.of(context).accentColor,
              borderWidth: 20,
              borderLength: 10,
              borderRadius: 10,
              cutOutSize: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
        ],
      ),
    );
  }

  void onQRViewCreated(QRViewController controller) {
    setState(() => this.controller = controller);
    controller.scannedDataStream.listen((barcode) async {
      setState(() {
        this.barcode = barcode;
      });
      controller.pauseCamera();
      try {
        print("working");
        // var response = await Dio()
        //     .get('http://192.168.137.1:8000/check-validation/${barcode.code}');
        var url = Uri.parse('https://30ab-103-155-20-163.ngrok.io/check-validation/${barcode.code}');
        var response = await http.get(url);
        print(response.statusCode);

        if (response.statusCode == 200) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text(
                  'Valid',
                  style: TextStyle(color: Colors.green),
                ),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: const <Widget>[
                      Text('Name: Subash Khatiwada'),
                      //Text(${jsonDe})
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Ok'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          ).then((value) {
            controller.resumeCamera();
            setState(() {
              result = null;
            });
          });
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text(
                  'In-valid',
                  style: TextStyle(color: Colors.red),
                ),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: const <Widget>[
                      Text('QR code is invalid.'),
                      //Text(${jsonDe})
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Ok'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          ).then((value) {
            controller.resumeCamera();
            setState(() {
              result = null;
            });
          });
        }
      } catch (e) {
        print("Error: "+e.toString());
      }
    });
  }
}
