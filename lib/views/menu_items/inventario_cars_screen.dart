import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventarioCarsScreen extends StatefulWidget {
  @override
  _InventarioCarsScreenState createState() => _InventarioCarsScreenState();
}

class _InventarioCarsScreenState extends State<InventarioCarsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _unidadController = TextEditingController();
  final TextEditingController _responsableController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _anioController = TextEditingController();
  final TextEditingController _tipoUnidadController = TextEditingController();
  final TextEditingController _placaController = TextEditingController();

  String? _currentId; // Para editar registros existentes

  void _mostrarFormulario({String? id, Map<String, dynamic>? data}) {
    if (id != null && data != null) {
      // Modo edición
      _currentId = id;
      _unidadController.text = data['numero_unidad'] ?? '';
      _responsableController.text = data['responsable'] ?? '';
      _modeloController.text = data['modelo'] ?? '';
      _marcaController.text = data['marca'] ?? '';
      _anioController.text = data['anio'] ?? '';
      _tipoUnidadController.text = data['tipo_unidad'] ?? '';
      _placaController.text = data['placa'] ?? '';
    } else {
      // Modo nuevo
      _currentId = null;
      _unidadController.clear();
      _responsableController.clear();
      _modeloController.clear();
      _marcaController.clear();
      _anioController.clear();
      _tipoUnidadController.clear();
      _placaController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentId == null ? "Agregar Nueva Unidad" : "Editar Unidad",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  _buildTextField("Número de Unidad", _unidadController),
                  _buildTextField("Responsable", _responsableController),
                  _buildTextField("Modelo", _modeloController),
                  _buildTextField("Marca", _marcaController),
                  _buildTextField("Año", _anioController, keyboardType: TextInputType.number),
                  _buildTextField("Tipo de Unidad", _tipoUnidadController),
                  _buildTextField("Placa", _placaController),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _guardarUnidad,
                    child: Text(_currentId == null ? "Guardar" : "Actualizar"),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _guardarUnidad() async {
    if (_formKey.currentState!.validate()) {
      final unidadData = {
        'numero_unidad': _unidadController.text,
        'responsable': _responsableController.text,
        'modelo': _modeloController.text,
        'marca': _marcaController.text,
        'anio': _anioController.text,
        'tipo_unidad': _tipoUnidadController.text,
        'placa': _placaController.text,
        'fecha_registro': FieldValue.serverTimestamp(),
      };

      if (_currentId == null) {
        await FirebaseFirestore.instance.collection('inventario_cars').add(unidadData);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unidad registrada correctamente")));
      } else {
        await FirebaseFirestore.instance.collection('inventario_cars').doc(_currentId).update(unidadData);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unidad actualizada correctamente")));
      }

      Navigator.pop(context);
    }
  }

  void _eliminarUnidad(String id) async {
    bool confirmar = await _mostrarConfirmacion();
    if (confirmar) {
      await FirebaseFirestore.instance.collection('inventario_cars').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unidad eliminada")));
    }
  }

  Future<bool> _mostrarConfirmacion() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirmar eliminación"),
        content: Text("¿Seguro que deseas eliminar esta unidad?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Eliminar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Este campo es obligatorio";
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Inventario de Vehículos")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('inventario_cars').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No hay unidades registradas."));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text("${data['numero_unidad']} - ${data['marca']} ${data['modelo']}"),
                  subtitle: Text("Responsable: ${data['responsable']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _mostrarFormulario(id: doc.id, data: data),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarUnidad(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: Icon(Icons.add),
      ),
    );
  }
}
