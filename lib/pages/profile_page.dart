import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_treinoabc/dto/AlunoDTO.dart';
import 'package:flutter_application_treinoabc/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  AlunoDTO? aluno;
  bool carregando = true;

  // Controllers
  late TextEditingController nomeController;
  late TextEditingController emailController;
  late TextEditingController telefoneController;
  late TextEditingController dataController;
  late TextEditingController pesoController;
  late TextEditingController alturaController;
  late TextEditingController gorduraController;
  late TextEditingController musculoController;
  late TextEditingController imcController;
  late TextEditingController objetivoController;
  late TextEditingController nivelController;

  String sexoSelecionado = 'Masculino';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _carregarAluno();
  }

  Future<void> _carregarAluno() async {
    final prefs = await SharedPreferences.getInstance();
    final alunoId = prefs.getString('alunoId') ?? '';
    final token = prefs.getString('token') ?? '';

    if (alunoId.isEmpty || token.isEmpty) {
      setState(() => carregando = false);
      return;
    }

    final response = await http.get(
      Uri.parse('$endpointAlunos/$alunoId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        aluno = AlunoDTO.fromJson(json);
        _inicializarControllers();
        carregando = false;
      });
    } else {
      setState(() => carregando = false);
      print('Erro ao carregar aluno: ${response.body}');
    }
  }

  void _inicializarControllers() {
    nomeController = TextEditingController(text: aluno?.nome ?? '');
    emailController = TextEditingController(text: aluno?.email ?? '');
    telefoneController = TextEditingController(text: aluno?.telefone ?? '');
    dataController = TextEditingController(text: aluno?.dataNascimento ?? '');
    pesoController = TextEditingController(
      text: aluno?.pesoAtual.toString() ?? '',
    );
    alturaController = TextEditingController(
      text: aluno?.altura.toString() ?? '',
    );
    gorduraController = TextEditingController(
      text: aluno?.percentualGordura.toString() ?? '',
    );
    musculoController = TextEditingController(
      text: aluno?.percentualMusculo.toString() ?? '',
    );
    imcController = TextEditingController(text: aluno?.imc.toString() ?? '');
    objetivoController = TextEditingController(text: aluno?.objetivo ?? '');
    nivelController = TextEditingController(
      text: aluno?.nivelTreinamento ?? '',
    );
    sexoSelecionado = aluno?.sexo ?? 'Masculino';
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (aluno == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Aluno não encontrado')),
      );
    }

    return Stack(
      children: [
        // Imagem de fundo
        SizedBox.expand(
          child: Image.asset(
            'assets/images/Copilot_20251029_183912.png',
            fit: BoxFit.cover,
          ),
        ),
        // Conteúdo
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.black54,
            elevation: 0,
            title: const Text(
              'Meu Perfil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.amber,
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              tabs: const [
                Tab(text: 'Pessoais'),
                Tab(text: 'Físico'),
                Tab(text: 'Medidas'),
                Tab(text: 'Objetivo'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPessoaisForm(),
              _buildFisicoForm(),
              _buildMedidasForm(),
              _buildObjetivoForm(),
            ],
          ),
        ),
      ],
    );
  }

  // ===== FORMULÁRIOS =====

  Widget _buildPessoaisForm() {
    return _buildForm(
      [
        _buildEditableField('Nome', nomeController),
        _buildEditableField('Email', emailController),
        _buildEditableField('Telefone', telefoneController),
        _buildEditableField('Data Nascimento', dataController),
      ],
      onSave: () async {
        final sucesso = await AuthService().atualizarPerfil(
          alunoId: aluno?.id ?? '',
          nome: nomeController.text.trim(),
          telefone: telefoneController.text.trim(),
          data_nascimento: dataController.text.trim(),
        );
        _showResult(sucesso);
      },
    );
  }

  Widget _buildFisicoForm() {
    return _buildForm(
      [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: DropdownButtonFormField<String>(
            initialValue: (sexoSelecionado.isEmpty)
                ? 'Masculino'
                : sexoSelecionado,
            items: const [
              DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
              DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
            ],
            onChanged: (v) =>
                setState(() => sexoSelecionado = v ?? 'Masculino'),
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            decoration: _inputDecoration('Sexo'),
          ),
        ),
        _buildEditableField('Peso Atual (kg)', pesoController, number: true),
        _buildEditableField('Altura (m)', alturaController, number: true),
        _buildEditableField(
          'Percentual Gordura (%)',
          gorduraController,
          number: true,
        ),
        _buildEditableField(
          'Percentual Músculo (%)',
          musculoController,
          number: true,
        ),
        _buildEditableField('IMC', imcController, number: true),
      ],
      onSave: () async {
        final sucesso = await AuthService().atualizarFisico(
          alunoId: aluno?.id ?? '',
          sexo: sexoSelecionado,
          peso: pesoController.text.trim().isEmpty
              ? '0'
              : pesoController.text.trim(),
          altura: alturaController.text.trim().isEmpty
              ? '0'
              : alturaController.text.trim(),
          gordura: gorduraController.text.trim().isEmpty
              ? '0'
              : gorduraController.text.trim(),
          musculo: musculoController.text.trim().isEmpty
              ? '0'
              : musculoController.text.trim(),
          imc: imcController.text.trim().isEmpty
              ? '0'
              : imcController.text.trim(),
        );
        _showResult(sucesso);
      },
    );
  }

  Widget _buildMedidasForm() {
    return _buildForm(
      [
        _buildEditableField('Cintura', TextEditingController(), number: true),
        _buildEditableField('Quadril', TextEditingController(), number: true),
        _buildEditableField('Peito', TextEditingController(), number: true),
        _buildEditableField('Ombro', TextEditingController(), number: true),
        _buildEditableField(
          'Braço Direito',
          TextEditingController(),
          number: true,
        ),
        _buildEditableField(
          'Braço Esquerdo',
          TextEditingController(),
          number: true,
        ),
        _buildEditableField(
          'Coxa Direita',
          TextEditingController(),
          number: true,
        ),
        _buildEditableField(
          'Coxa Esquerda',
          TextEditingController(),
          number: true,
        ),
        _buildEditableField(
          'Panturrilha Direita',
          TextEditingController(),
          number: true,
        ),
        _buildEditableField(
          'Panturrilha Esquerda',
          TextEditingController(),
          number: true,
        ),
      ],
      onSave: () async {
        final sucesso = await AuthService().atualizarMedidas(
          alunoId: aluno?.id ?? '',
          cintura: '...',
          quadril: '...',
          peito: '...',
          ombro: '...',
          bracoDireito: '...',
          bracoEsquerdo: '...',
          coxaDireita: '...',
          coxaEsquerda: '...',
          panturrilhaDireita: '...',
          panturrilhaEsquerda: '...',
        );
        _showResult(sucesso);
      },
    );
  }

  Widget _buildObjetivoForm() {
    return _buildForm(
      [
        _buildEditableField('Objetivo', objetivoController),
        _buildEditableField('Nível Treinamento', nivelController),
      ],
      onSave: () async {
        final sucesso = await AuthService().atualizarObjetivo(
          alunoId: aluno?.id ?? '',
          objetivo: objetivoController.text.trim(),
          nivel: nivelController.text.trim(),
        );
        _showResult(sucesso);
      },
    );
  }

  // ===== COMPONENTES REUTILIZÁVEIS =====

  Widget _buildForm(List<Widget> fields, {required VoidCallback onSave}) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // Card com os campos
            Card(
              elevation: 0,
              color: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: fields),
              ),
            ),
            const SizedBox(height: 24),
            // Botão Salvar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded, size: 20),
                label: const Text(
                  'Salvar alterações',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: onSave,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey[400],
        fontFamily: 'Poppins',
        fontSize: 13,
      ),
      filled: true,
      fillColor: Colors.grey[850],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.amber, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: _inputDecoration(label),
      ),
    );
  }

  void _showResult(bool sucesso) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso ? 'Dados atualizados com sucesso!' : 'Erro ao atualizar',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: sucesso ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }
}
