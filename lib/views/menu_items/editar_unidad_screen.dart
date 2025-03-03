import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarUnidadScreen extends StatefulWidget {
  final String? unidadId;
  final Map<String, dynamic> data;

  const EditarUnidadScreen(this.unidadId, this.data, {super.key});

  @override
  _EditarUnidadScreenState createState() => _EditarUnidadScreenState();
}

class _EditarUnidadScreenState extends State<EditarUnidadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _unidadController = TextEditingController();
  final _responsableController = TextEditingController();
  final _modeloController = TextEditingController();
  final _marcaController = TextEditingController();
  final _anioController = TextEditingController();
  final _tipoUnidadController = TextEditingController();
  final _placaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.unidadId != null) {
      _unidadController.text = widget.data['numero_unidad'] ?? '';
      _responsableController.text = widget.data['responsable'] ?? '';
      _modeloController.text = widget.data['modelo'] ?? '';
      _marcaController.text = widget.data['marca'] ?? '';
      _anioController.text = widget.data['anio'] ?? '';
      _tipoUnidadController.text = widget.data['tipo_unidad'] ?? '';
      _placaController.text = widget.data['placa'] ?? '';
    }
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

      if (widget.unidadId == null) {
        await FirebaseFirestore.instance.collection('inventario_cars').add(unidadData);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unidad registrada correctamente")));
      } else {
        await FirebaseFirestore.instance.collection('inventario_cars').doc(widget.unidadId).update(unidadData);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unidad actualizada correctamente")));
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.unidadId == null ? "Nueva Unidad" : "Editar Unidad")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Número de Unidad", _unidadController),
              _buildTextField("Responsable", _responsableController),
              _buildTextField("Modelo", _modeloController),
              _buildTextField("Marca", _marcaController),
              _buildTextField("Año", _anioController, keyboardType: TextInputType.number),
              _buildTextField("Tipo de Unidad", _tipoUnidadController),
              _buildTextField("Placa", _placaController),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarUnidad,
                child: Text("Guardar Unidad"),
              ),
            ],
          ),
        ),
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
}
