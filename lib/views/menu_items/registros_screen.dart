import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrosScreen extends StatefulWidget {
  const RegistrosScreen({super.key});

  @override
  _RegistrosScreenState createState() => _RegistrosScreenState();
}

class _RegistrosScreenState extends State<RegistrosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final List<DocumentSnapshot> _registros = [];
  bool _loading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _loadRegistros();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMore) {
        _loadRegistros();
      }
    });
  }

  /// 📌 Carga registros de ambas colecciones
  Future<void> _loadRegistros() async {
    if (_loading) return;
    setState(() => _loading = true);

    Query qrcodesQuery = _firestore.collection("qrcodes").orderBy("fecha_formateada", descending: true).limit(10);
    Query carsQuery = _firestore.collection("cars_qr").orderBy("fecha_formateada", descending: true).limit(10);

    if (_lastDocument != null) {
      qrcodesQuery = qrcodesQuery.startAfterDocument(_lastDocument!);
      carsQuery = carsQuery.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot qrcodesSnapshot = await qrcodesQuery.get();
    QuerySnapshot carsSnapshot = await carsQuery.get();

    List<DocumentSnapshot> newData = [...qrcodesSnapshot.docs, ...carsSnapshot.docs];

    newData.sort((a, b) {
      DateTime dateA = DateTime.tryParse(a["fecha_formateada"] ?? "") ?? DateTime(2000);
      DateTime dateB = DateTime.tryParse(b["fecha_formateada"] ?? "") ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    setState(() {
      _registros.addAll(newData);
      _lastDocument = newData.isNotEmpty ? newData.last : null;
      _hasMore = newData.length == 20;
      _loading = false;
    });
  }

  void _search(String value) {
    setState(() => _searchText = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registros")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _search,
              decoration: InputDecoration(
                labelText: "Buscar",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _registros.length + 1,
              itemBuilder: (context, index) {
                if (index == _registros.length) {
                  return _loading ? Center(child: CircularProgressIndicator()) : SizedBox.shrink();
                }

                var data = _registros[index].data() as Map<String, dynamic>;

                bool matchesSearch = _searchText.isEmpty ||
                    (data["nombre"]?.toString().toLowerCase().contains(_searchText.toLowerCase()) ?? false) ||
                    (data["numero_unidad"]?.toString().toLowerCase().contains(_searchText.toLowerCase()) ?? false) ||
                    (data["responsable"]?.toString().toLowerCase().contains(_searchText.toLowerCase()) ?? false);

                if (!matchesSearch) return SizedBox.shrink();

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(data["Vehiculo"] ?? data["numero_unidad"] ?? "Sin información"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.containsKey("categoria"))
                          Text("Categoría: ${data["categoria"] ?? "Desconocida"}"),
                        if (data.containsKey("tipo_permiso"))
                          Text("Tipo: ${data["tipo_permiso"] ?? "No especificado"}"),
                        if (data.containsKey("tiempo_permiso"))
                          Text("Tiempo: ${data["tiempo_permiso"] ?? "No especificado"}"),
                        if (data.containsKey("numero_empleado"))
                          Text("Empleado: ${data["numero_empleado"] ?? "No registrado"}"),
                        if (data.containsKey("responsable"))
                          Text("Responsable: ${data["responsable"] ?? "No registrado"}"),
                      ],
                    ),
                    trailing: Text(data["fecha_formateada"] ?? "Fecha desconocida"),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
