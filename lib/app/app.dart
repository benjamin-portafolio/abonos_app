import 'package:flutter/material.dart';

import 'package:abonos_app/features/abonos/presentation/pages/clients_page.dart';

class AbonosApp extends StatelessWidget {
  const AbonosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abonos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ClientsPage(),
    );
  }
}
