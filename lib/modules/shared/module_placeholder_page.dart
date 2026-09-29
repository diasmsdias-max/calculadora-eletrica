import 'package:flutter/material.dart';

class ModulePlaceholderPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const ModulePlaceholderPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text('Módulo preparado para implementação.'),
            ],
          ),
        ),
      ),
    );
  }
}
