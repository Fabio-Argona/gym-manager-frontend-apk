import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nomeController = TextEditingController();
  final telefoneController = TextEditingController();
  final dataController = TextEditingController();

  final telefoneMask = MaskTextInputFormatter(
    mask: '(##)#####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final dataMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool isSaving = false;
  String alunoId = '';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      alunoId = prefs.getString('alunoId') ?? '';
      nomeController.text = prefs.getString('nome') ?? '';
    });
  }

  Future<void> _salvarPerfil() async {
    setState(() => isSaving = true);

    final sucesso = await AuthService().atualizarPerfil(
      alunoId: alunoId,
      nome: nomeController.text.trim(),
      telefone: telefoneController.text.trim(),
      data_nascimento: _formatarData(dataController.text.trim()),
    );

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sucesso ? 'Perfil atualizado com sucesso' : 'Erro ao atualizar perfil'),
      ),
    );
  }

  String _formatarData(String data) {
    final partes = data.split('/');
    if (partes.length != 3) return '';
    return '${partes[2]}-${partes[1]}-${partes[0]}'; // yyyy-MM-dd
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Nome', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: nomeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.grey,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Telefone', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: telefoneController,
              inputFormatters: [telefoneMask],
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.grey,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Data de Nascimento (dd/mm/aaaa)', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: dataController,
              inputFormatters: [dataMask],
              keyboardType: TextInputType.datetime,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.grey,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            isSaving
                ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _salvarPerfil,
                    child: const Text('Salvar alterações'),
                  ),
          ],
        ),
      ),
    );
  }
}
