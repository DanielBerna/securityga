import 'package:crmga_app/views/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QR Control Security',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Color principal
        scaffoldBackgroundColor: Colors.white, // Fondo general
        appBarTheme: AppBarTheme(
          backgroundColor: const Color.fromARGB(255, 186, 152, 71), // Color del AppBar
          foregroundColor: Colors.white, // Color del texto e íconos en AppBar
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.blue, // Fondo del menú inferior
          selectedItemColor: Color.fromARGB(255, 10, 20, 151), // Íconos seleccionados
          unselectedItemColor: Colors.black, // Íconos no seleccionados
          selectedLabelStyle: TextStyle(
            color: Color.fromARGB(255, 10, 20, 151), // Texto seleccionado
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: TextStyle(
            color: Colors.black, // Texto no seleccionado
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 181, 181, 181), // Color de los botones
            foregroundColor: const Color.fromARGB(255, 56, 45, 156), // Color del texto en los botones
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: LoginScreen(),
    );
  }
}
