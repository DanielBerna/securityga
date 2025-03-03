import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'menu_items/agregar_equipo.dart';
import 'menu_items/crear_qr.dart';
import 'menu_items/reportes.dart';
import 'menu_items/inventario_cars_screen.dart';
import 'menu_items/registro_cars_screen.dart';
import 'menu_items/crear_qr_cars_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _searchText = "";
  final TextEditingController _searchController = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context);
  }

  Future<void> _scanQRCode() async {
    try {
      String qrCode = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancelar", true, ScanMode.QR);

      if (qrCode == "-1") return;

      DocumentSnapshot equipo = await FirebaseFirestore.instance
          .collection('equipos')
          .doc(qrCode)
          .get();

      if (equipo.exists) {
        _showQRDetails(equipo);
      } else {
        DocumentSnapshot permiso = await FirebaseFirestore.instance
            .collection('permisos')
            .doc(qrCode)
            .get();

        if (permiso.exists) {
          _showQRDetails(permiso);
        } else {
          _showErrorDialog();
        }
      }
    } catch (e) {
      print("Error al escanear QR: $e");
    }
  }

  void _showQRDetails(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Detalles del QR"),
          content: data != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: data.entries
                      .map((entry) => Text("${entry.key}: ${entry.value}"))
                      .toList(),
                )
              : Text("No hay datos disponibles"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text("QR no encontrado en la base de datos."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("QR Control Security")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text("Menú"),
            ),
            ListTile(
              title: Text("Agregar Equipo"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AgregarEquipoScreen()),
              ),
            ),
            ListTile(
              title: Text("Crear QR"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CrearQRScreen()),
              ),
            ),
            ListTile(
              title: Text("Reportes"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReportesScreen()),
              ),
            ),
            Divider(),
            ListTile(
              title: Text("Cerrar Sesión"),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code), label: "Escanear QR"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Registros"),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_car),
              label: "CarsControl"), // Nueva opción
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildInicio();
      case 1:
        return Center(
          child: ElevatedButton.icon(
            icon: Icon(Icons.qr_code_scanner),
            label: Text("Escanear QR"),
            onPressed: _scanQRCode,
          ),
        );
      case 2:
        return _buildRegistros();
      case 3:
        return _buildCarsControl();
      default:
        return _buildInicio();
    }
  }

  /// **Muestra los últimos 5 registros en la pantalla de Inicio**
///
Widget _buildInicio() {
  return SingleChildScrollView(
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            "Últimos Persmisos Solicitados",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('qrcodes')
              .orderBy('fecha_formateada', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            var registros = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(10),
              itemCount: registros.length,
              itemBuilder: (context, index) {
                var registro = registros[index].data() as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text(registro['nombre'] ?? "Sin nombre"),
                    subtitle: Text("Fecha: ${registro['fecha_formateada']}\n"
                    "Tipo Permiso: ${registro['categoria'] ?? 'No asignado'}",),
                  ),
                );
              },
            );
          },
        ),

        Divider(thickness: 2, height: 20), // Separador entre secciones

        Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            "Ultimas Solicitudes Creadas para Vehiculos",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('cars_qr')
              .orderBy('fecha_formateada', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            var registros = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(10),
              itemCount: registros.length,
              itemBuilder: (context, index) {
                var registro = registros[index].data() as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text("Unidad: ${registro['numero_unidad'] ?? 'Sin número'}"),
                    subtitle: Text(
                      "Fecha: ${registro['fecha_formateada']}\n"
                      "Responsable: ${registro['responsable'] ?? 'No asignado'}",
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    ),
  );
}


  /// **Muestra el listado de registros con paginación y búsqueda**
  Widget _buildRegistros() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Buscar por nombre...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('qrcodes')
                .orderBy('fecha_formateada', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var registros = snapshot.data!.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .where((registro) => registro['nombre']
                      .toString()
                      .toLowerCase()
                      .contains(_searchText.toLowerCase()))
                  .toList();

              return ListView.builder(
                padding: EdgeInsets.all(10),
                itemCount: registros.length > 15 ? 15 : registros.length,
                itemBuilder: (context, index) {
                  var registro = registros[index];
                  return Card(
                    child: ListTile(
                      title: Text(registro['nombre'] ?? "Sin nombre"),
                      subtitle: Text(
                        "Fecha: ${registro['fecha_formateada']}\nCategoría: ${registro['categoria'] ?? 'Sin categoría'}",
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  /// **Nueva vista "CarsControl" con botones estilizados y funcionales**
Widget _buildCarsControl() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCarsControlButton(
          icon: Icons.directions_car,
          label: "Registro de carros",
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RegistroCarsScreen()),
          ),
        ),
        _buildCarsControlButton(
          icon: Icons.inventory,
          label: "Inventario",
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => InventarioCarsScreen()),
          ),
        ),
        _buildCarsControlButton(
          icon: Icons.bar_chart,
          label: "Reportes",
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReportesScreen()),
          ),
        ),
        _buildCarsControlButton(
          icon: Icons.qr_code_scanner,
          label: "Escanear QR",
          onPressed: _scanQRCode,
        ),
        _buildCarsControlButton(
          icon: Icons.qr_code,
          label: "Crear QR",
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CrearQRCarsScreen()),
          ),
        ),
      ],
    ),
  );
}

/// **Botón reutilizable con diseño uniforme**
Widget _buildCarsControlButton({
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20.0),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28),
        label: Text(label, style: TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
      ),
    ),
  );
}


    }
  

