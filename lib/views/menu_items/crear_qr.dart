import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';

// ✅ Solo importar `dart:html` si es Web
// 🛑 Esto previene errores en Android/iOS
import 'dart:html' as html; 

class CrearQRScreen extends StatefulWidget {
  const CrearQRScreen({super.key});

  @override
  _CrearQRScreenState createState() => _CrearQRScreenState();
}

class _CrearQRScreenState extends State<CrearQRScreen> {
  String selectedCategory = "Permiso";
  String qrData = "";
  final GlobalKey _qrKey = GlobalKey(); // ✅ Clave Global para capturar QR

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TextEditingController empleadoController = TextEditingController();
  TextEditingController nombreController = TextEditingController();
  TextEditingController permisoController = TextEditingController();
  TextEditingController tiempoController = TextEditingController();
  TextEditingController responsableController = TextEditingController();
  TextEditingController tipoController = TextEditingController();
  TextEditingController modeloController = TextEditingController();

  void generarQR() async {
    User? usuario = _auth.currentUser;

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Debes iniciar sesión para guardar datos")),
      );
      return;
    }

    DateTime now = DateTime.now();
    String formattedDate = DateFormat("dd/MM/yyyy HH:mm").format(now);

    Map<String, dynamic> qrInfo = {
      "categoria": selectedCategory,
      "usuario_id": usuario.uid,
      "fecha_formateada": formattedDate,
    };

    if (selectedCategory == "Permiso") {
      qrData =
          "Tipo: Permiso\nEmpleado: ${empleadoController.text}\nNombre: ${nombreController.text}\nTipo Permiso: ${permisoController.text}\nTiempo: ${tiempoController.text}";

      qrInfo.addAll({
        "numero_empleado": empleadoController.text,
        "nombre": nombreController.text,
        "tipo_permiso": permisoController.text,
        "tiempo_permiso": tiempoController.text,
      });
    } else {
      qrData =
          "Tipo: Equipo\nNombre: ${responsableController.text}\nTipo: ${tipoController.text}\nModelo/Marca: ${modeloController.text}";

      qrInfo.addAll({
        "nombre": responsableController.text,
        "tipo_equipo": tipoController.text,
        "modelo_marca": modeloController.text,
      });
    }

    try {
      await _firestore.collection("qrcodes").add(qrInfo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ QR guardado en Firebase con éxito")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al guardar: $e")),
      );
    }

    setState(() {});
  }

  Future<void> compartirQR() async {
  try {
    final RenderRepaintBoundary boundary =
        _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage();
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    if (kIsWeb) {
      // 🌐 Web: Descargar la imagen generada
      final blob = html.Blob([pngBytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Crear un enlace invisible y simular un clic para descargar
      // ignore: unused_local_variable
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "qr_code.png")
        ..click();

      html.Url.revokeObjectUrl(url); // Liberar la URL después de descargar
    } else {
      // 📱 Android/iOS: Guardar y compartir el archivo
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)], text: "Aquí tienes tu QR");
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Error al compartir QR: $e")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Generador de QR")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🟢 **Selector de Categoría**
              Text("Selecciona una categoría", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: ["Permiso", "Equipo"].map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue!;
                    qrData = "";
                  });
                },
              ),
              SizedBox(height: 20),

              /// 🟢 **Campos dinámicos según la categoría**
              if (selectedCategory == "Permiso") ...[
                _buildTextField(empleadoController, "Número de Empleado", Icons.badge),
                _buildTextField(nombreController, "Nombre", Icons.person),
                _buildTextField(permisoController, "Tipo de Permiso", Icons.assignment),
                _buildTextField(tiempoController, "Tiempo de Permiso", Icons.access_time),
              ] else ...[
                _buildTextField(responsableController, "Responsable", Icons.person_outline),
                _buildTextField(tipoController, "Tipo", Icons.category),
                _buildTextField(modeloController, "Modelo y Marca", Icons.logo_dev_outlined),
              ],
              SizedBox(height: 20),

              /// 🟢 **Botón para generar QR**
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.qr_code, size: 24),
                  label: Text("Generar y Guardar QR"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    textStyle: TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: generarQR,
                ),
              ),

              SizedBox(height: 20),
              Divider(),

              /// 🟢 **Muestra el QR generado**
              if (qrData.isNotEmpty)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text("Código QR generado", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        RepaintBoundary(
                          key: _qrKey,
                          child: QrImageView(
                            data: qrData,
                            size: 200,
                            version: QrVersions.auto,
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: Icon(Icons.share),
                          label: Text("Compartir QR"),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: compartirQR,
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
  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
