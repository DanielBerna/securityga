import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroCarsScreen extends StatefulWidget {
  const RegistroCarsScreen({super.key});

  @override
  _RegistroCarsScreenState createState() => _RegistroCarsScreenState();
}

class _RegistroCarsScreenState extends State<RegistroCarsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registros de Vehículos")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection("registroscars").orderBy("timestamp", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No hay registros de vehículos."));
          }

          var registros = snapshot.data!.docs;

          return ListView.builder(
            itemCount: registros.length,
            itemBuilder: (context, index) {
              var registro = registros[index];
              var data = registro.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text("Unidad: ${data['numero_unidad'] ?? 'Desconocido'}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Responsable: ${data['responsable'] ?? 'No especificado'}"),
                      Text("Tipo de Ruta: ${data['tipo_ruta'] ?? 'No especificado'}"),
                      Text("Hora: ${data['timestamp'] != null ? _formatearFecha(data['timestamp']) : 'No registrada'}"),
                      Text("Observaciones: ${data['observaciones'] ?? 'Sin comentarios'}"),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Función para formatear la fecha del timestamp
  String _formatearFecha(Timestamp? timestamp) {
    if (timestamp == null) return "Fecha no disponible";
    DateTime fecha = timestamp.toDate();
    return "${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute}";
  }
}
