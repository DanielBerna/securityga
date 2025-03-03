import 'package:flutter/material.dart';

class AgregarEquipoScreen extends StatelessWidget {
  const AgregarEquipoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Agregar Equipo")),
      body: Center(child: Text("Formulario para agregar equipo")),
    );
  }
}
