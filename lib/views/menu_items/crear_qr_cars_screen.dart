import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
// ignore: unused_import
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'dart:html' as html; // 🔹 Importación necesaria para Web
import 'package:intl/intl.dart'; // 📌 Importar intl para formatear la fecha

class CrearQRCarsScreen extends StatefulWidget {
  const CrearQRCarsScreen({super.key});

  @override
  _CrearQRCarsScreenState createState() => _CrearQRCarsScreenState();
}

class _CrearQRCarsScreenState extends State<CrearQRCarsScreen> {
  final GlobalKey _qrKey = GlobalKey();
  String? _selectedUnidad;
  String? _responsable;
  String? _tipoRuta;
  String? _lugar;
  bool _isLoading = false;
  String? _qrData;
  List<String> _unidades = [];

  @override
  void initState() {
    super.initState();
    _cargarUnidades();
  }

  Future<void> _cargarUnidades() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('inventario_cars').get();

      setState(() {
        _unidades = snapshot.docs
            .map((doc) => doc['numero_unidad'].toString())
            .toList();
      });
    } catch (e) {
      print("Error al cargar unidades: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar unidades")),
      );
    }
  }

  Future<void> _guardarDatosYGenerarQR() async {
    if ((_selectedUnidad?.isEmpty ?? true) ||
        (_responsable?.isEmpty ?? true) ||
        (_tipoRuta?.isEmpty ?? true) ||
        (_lugar?.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Todos los campos son obligatorios")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      DateTime now = DateTime.now();
      Timestamp timestamp =
          Timestamp.fromDate(now); // 📌 Se guarda como Timestamp
      String fechaFormateada =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(now); // 📌 Formato legible

      await FirebaseFirestore.instance.collection('cars_qr').add({
        'numero_unidad': _selectedUnidad,
        'responsable': _responsable,
        'tipoRuta': _tipoRuta,
        'lugar': _lugar,
        'timestamp': timestamp, // 📌 Se guarda como Timestamp
      'fecha_formateada': fechaFormateada, // 📌 Se guarda como String
      });

      setState(() {
        _qrData =
            "Unidad: $_selectedUnidad\nResponsable: $_responsable\nRuta: $_tipoRuta\nLugar: $_lugar: $_lugar\nFecha: $fechaFormateada";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Datos guardados. QR generado.")),
      );
    } catch (e) {
      print("Error al guardar QR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al generar QR")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _descargarQR() async {
    try {
      await Future.delayed(Duration(milliseconds: 500));

      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        // 🔹 Código especial para descargar en Web
        final blob = html.Blob([pngBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        // ignore: unused_local_variable
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "QR_Code.png")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // 🔹 Código para Android, iOS y escritorio
        final directory = await getTemporaryDirectory();
        final file =
            await File('${directory.path}/QR_Code.png').writeAsBytes(pngBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("QR descargado en ${file.path}")),
        );
      }
    } catch (e) {
      print("Error al descargar QR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al descargar QR")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Crear QR para Vehículos")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🟢 **Selector de Unidad**
              Text("Selecciona una unidad",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedUnidad,
                decoration: _inputDecoration("Selecciona una unidad"),
                items: _unidades.map((unidad) {
                  return DropdownMenuItem(value: unidad, child: Text(unidad));
                }).toList(),
                onChanged: (value) => setState(() => _selectedUnidad = value),
              ),
              SizedBox(height: 15),

              /// 🟢 **Campo Responsable**
              _buildTextField(
                  "Responsable", Icons.person, (value) => _responsable = value),

              /// 🟢 **Selector de Tipo de Ruta**
              SizedBox(height: 15),
              Text("Selecciona el tipo de ruta",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tipoRuta,
                decoration: _inputDecoration("Tipo de ruta"),
                items: ["Ruta A", "Ruta B", "Ruta C"]
                    .map((ruta) =>
                        DropdownMenuItem(value: ruta, child: Text(ruta)))
                    .toList(),
                onChanged: (value) => setState(() => _tipoRuta = value),
              ),
              SizedBox(height: 15),

              /// 🟢 **Campo Lugar**
              _buildTextField(
                  "Lugar", Icons.location_on, (value) => _lugar = value),

              SizedBox(height: 20),

              /// 🟢 **Indicador de carga**
              if (_isLoading) Center(child: CircularProgressIndicator()),

              /// 🟢 **Botón para generar QR**
              if (!_isLoading)
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.qr_code, size: 24),
                    label: Text("Generar QR"),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      textStyle: TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _guardarDatosYGenerarQR,
                  ),
                ),

              SizedBox(height: 20),

              /// 🟢 **Muestra el QR generado**
              if (_qrData != null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text("Código QR generado",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        RepaintBoundary(
                          key: _qrKey,
                          child: QrImageView(
                            data: _qrData!,
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: Icon(Icons.download),
                          label: Text("Descargar QR"),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _descargarQR,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// **Método auxiliar para construir los `TextField` con icono y mejor estilo**
  Widget _buildTextField(
      String label, IconData icon, Function(String) onChanged) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (value) => setState(() => onChanged(value)),
    );
  }

  /// **Estilo general para los `DropdownButtonFormField`**
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[200],
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
