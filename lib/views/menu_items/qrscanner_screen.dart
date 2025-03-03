import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  String scannedData = "";
  Map<String, dynamic>? qrDetails;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Función para escanear QR
  Future<void> _scanQR() async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", // Color del escáner
        "Cancelar", // Texto del botón de cancelar
        false, // No usar flash automático
        ScanMode.QR, // Modo QR
      );

      if (barcodeScanRes != "-1") {
        setState(() {
          scannedData = barcodeScanRes;
        });

        // Buscar en Firebase
        await _buscarEnFirebase(scannedData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al escanear QR: $e")),
      );
    }
  }

  // Buscar QR en Firebase Firestore
  Future<void> _buscarEnFirebase(String qrText) async {
    try {
      var querySnapshot = await _firestore
          .collection("qrcodes")
          .where("qr_data", isEqualTo: qrText)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          qrDetails = querySnapshot.docs.first.data();
        });

        // Mostrar detalles
        _mostrarDetalles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Código QR no encontrado en Firebase")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al buscar QR: $e")),
      );
    }
  }

  // Mostrar detalles en un diálogo
  void _mostrarDetalles() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Detalles del QR"),
          content: qrDetails != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Categoría: ${qrDetails!['categoria']}"),
                    Text("Datos: ${qrDetails!['qr_data']}"),
                  ],
                )
              : Text("No se encontraron detalles."),
          actions: [
            ElevatedButton(
              onPressed: () {
                _registrarMovimiento();
                Navigator.pop(context);
              },
              child: Text("Registrar Entrada/Salida"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  // Registrar movimiento en Firebase
  Future<void> _registrarMovimiento() async {
    try {
      String tipoRegistro = qrDetails!['categoria'] == 'carro' ? "registroscars" : "movimientos";

      await _firestore.collection(tipoRegistro).add({
        "qr_data": qrDetails!['qr_data'],
        "categoria": qrDetails!['categoria'],
        "timestamp": FieldValue.serverTimestamp(),
        "tipo_movimiento": "Entrada/Salida",
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Movimiento registrado en $tipoRegistro con éxito")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar movimiento: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Escanear QR")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _scanQR,
              child: Text("Escanear QR"),
            ),
            SizedBox(height: 20),
            scannedData.isNotEmpty
                ? Text("Código escaneado: $scannedData")
                : Text("Escanea un código QR"),
          ],
        ),
      ),
    );
  }
}
