import 'package:flutter/material.dart';

Future<String?> showActivationKeyDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const ActivationKeyDialog(),
    );

class ActivationKeyDialog extends StatefulWidget {
  const ActivationKeyDialog({super.key});

  @override
  State<ActivationKeyDialog> createState() => _ActivationKeyDialogState();
}

class _ActivationKeyDialogState extends State<ActivationKeyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Ativar VIS ELECTRICA Profissional'),
        content: TextField(
          controller: _controller,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Chave de ativação',
            hintText: 'VIS-PRO-XXXX-XXXX-XXXX-XXXX-XXXX',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
            child: const Text('ATIVAR'),
          ),
        ],
      );
}
