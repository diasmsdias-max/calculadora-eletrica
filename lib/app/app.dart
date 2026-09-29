import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../modules/home/home_page.dart';

class CalculadoraEletricaApp extends StatelessWidget {
  const CalculadoraEletricaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora Elétrica',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomePage(),
    );
  }
}
