import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_treinoabc/dto/AlunoDTO.dart';
import 'package:flutter_application_treinoabc/services/auth_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../constants/app_theme.dart';

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
  late TextEditingController objetivoController;
  late TextEditingController nivelController;

  // Controllers de medidas
  final cinturaController = TextEditingController();
  final abdomenController = TextEditingController();
  final quadrilController = TextEditingController();
  final peitoController = TextEditingController();
  final bracoDirController = TextEditingController();
  final bracoEsqController = TextEditingController();
  final coxaDirController = TextEditingController();
  final coxaEsqController = TextEditingController();

  String? _evolucaoId; // ID da evoção existente (para PUT)

  String sexoSelecionado = 'Masculino';

  final telefoneMask = MaskTextInputFormatter(
    mask: '(##)#####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final dataMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    final headers = {'Authorization': 'Bearer $token'};

    final responses = await Future.wait([
      http.get(Uri.parse('$endpointAlunos/$alunoId'), headers: headers),
      http.get(
        Uri.parse('${baseUrl}/evolucoes/aluno/$alunoId'),
        headers: headers,
      ),
    ]);

    if (responses[0].statusCode == 200) {
      try {
        final json = jsonDecode(responses[0].body);
        setState(() {
          aluno = AlunoDTO.fromJson(json);
          _inicializarControllers();
          carregando = false;
        });
      } catch (_) {
        setState(() => carregando = false);
      }
    } else {
      setState(() => carregando = false);
    }

    // Carrega medidas se existir
    if (responses[1].statusCode == 200) {
      try {
        final lista = jsonDecode(responses[1].body) as List;
        if (lista.isNotEmpty) {
          final m = lista.last as Map<String, dynamic>;
          _evolucaoId = m['id']?.toString();
          // Só sobrescreve se o valor da evolução for não-nulo
          // (registros antigos podem não ter peso/gordura/músculo)
          if (m['peso'] != null) pesoController.text = m['peso'].toString();
          if (m['altura'] != null)
            alturaController.text = m['altura'].toString();
          if (m['percentualGordura'] != null)
            gorduraController.text = m['percentualGordura'].toString();
          if (m['percentualMusculo'] != null)
            musculoController.text = m['percentualMusculo'].toString();
          if (m['cintura'] != null)
            cinturaController.text = m['cintura'].toString();
          if (m['abdomen'] != null)
            abdomenController.text = m['abdomen'].toString();
          if (m['quadril'] != null)
            quadrilController.text = m['quadril'].toString();
          if (m['peito'] != null) peitoController.text = m['peito'].toString();
          if (m['bracoDireito'] != null)
            bracoDirController.text = m['bracoDireito'].toString();
          if (m['bracoEsquerdo'] != null)
            bracoEsqController.text = m['bracoEsquerdo'].toString();
          if (m['coxaDireita'] != null)
            coxaDirController.text = m['coxaDireita'].toString();
          if (m['coxaEsquerda'] != null)
            coxaEsqController.text = m['coxaEsquerda'].toString();
        }
      } catch (_) {
        // resposta inválida, ignora
      }
    }
  }

  void _inicializarControllers() {
    nomeController = TextEditingController(text: aluno?.nome ?? '');
    emailController = TextEditingController(text: aluno?.email ?? '');
    telefoneController = TextEditingController(text: aluno?.telefone ?? '');
    telefoneMask.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: aluno?.telefone ?? ''),
    );
    final rawData = aluno?.dataNascimento ?? '';
    // Converte yyyy-MM-dd → dd/MM/yyyy se necessário
    String dataFormatada = rawData;
    if (rawData.contains('-') && rawData.length == 10) {
      final parts = rawData.split('-');
      dataFormatada = '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    dataController = TextEditingController(text: dataFormatada);
    pesoController = TextEditingController(
      text: aluno?.pesoAtual != null ? aluno!.pesoAtual.toString() : '',
    );
    alturaController = TextEditingController(
      text: aluno?.altura != null ? aluno!.altura.toString() : '',
    );
    gorduraController = TextEditingController(
      text: aluno?.percentualGordura != null
          ? aluno!.percentualGordura.toString()
          : '',
    );
    musculoController = TextEditingController(
      text: aluno?.percentualMusculo != null
          ? aluno!.percentualMusculo.toString()
          : '',
    );
    objetivoController = TextEditingController(text: aluno?.objetivo ?? '');
    nivelController = TextEditingController(
      text: aluno?.nivelTreinamento ?? '',
    );
    sexoSelecionado = aluno?.sexo ?? 'Masculino';

    // Recalcula IMC dinamicamente ao alterar peso ou altura
    pesoController.addListener(() => setState(() {}));
    alturaController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (carregando) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.bg1, c.bg2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator(color: c.primary)),
        ),
      );
    }

    if (aluno == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.bg1, c.bg2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Text(
              'Aluno não encontrado',
              style: TextStyle(color: c.textSub),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.bg1, c.bg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.bg2, c.bg1.withOpacity(0.85)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
          title: const Text(
            'Meu Perfil',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border, width: 1)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: c.accent,
                indicatorWeight: 2.5,
                labelColor: c.accent,
                unselectedLabelColor: c.textHint,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Pessoais'),
                  Tab(text: 'Avaliação'),
                  Tab(text: 'Objetivo'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPessoaisForm(),
            _buildAvaliacaoForm(),
            _buildObjetivoForm(),
          ],
        ),
      ),
    );
  }

  // ===== FORMULÁRIOS =====

  Widget _buildPessoaisForm() {
    final c = AppColors.of(context);
    return _buildForm(
      [
        _buildEditableField(
          'Nome',
          nomeController,
          icon: Icons.person_outline_rounded,
        ),
        _buildReadOnlyField(
          'Email',
          emailController.text,
          icon: Icons.email_outlined,
        ),
        _buildEditableField(
          'Telefone',
          telefoneController,
          icon: Icons.phone_outlined,
          mask: telefoneMask,
        ),
        _buildEditableField(
          'Data Nascimento',
          dataController,
          icon: Icons.cake_outlined,
          mask: dataMask,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: DropdownButtonFormField<String>(
            value: sexoSelecionado.isEmpty ? 'Masculino' : sexoSelecionado,
            items: [
              DropdownMenuItem(
                value: 'Masculino',
                child: Text('Masculino', style: TextStyle(color: c.textSub)),
              ),
              DropdownMenuItem(
                value: 'Feminino',
                child: Text('Feminino', style: TextStyle(color: c.textSub)),
              ),
            ],
            onChanged: (v) =>
                setState(() => sexoSelecionado = v ?? 'Masculino'),
            dropdownColor: c.inputBg,
            style: TextStyle(color: c.textSub),
            decoration: _inputDecoration('Sexo', Icons.wc_rounded),
          ),
        ),
      ],
      onSave: () async {
        final dataRaw = dataController.text.trim();
        String dataBackend = dataRaw;
        if (dataRaw.contains('/') && dataRaw.length == 10) {
          final parts = dataRaw.split('/');
          dataBackend = '${parts[2]}-${parts[1]}-${parts[0]}';
        }
        final r1 = await AuthService().atualizarPerfil(
          alunoId: aluno?.id ?? '',
          nome: nomeController.text.trim(),
          telefone: telefoneController.text.trim(),
          data_nascimento: dataBackend,
        );
        final r2 = await AuthService().atualizarFisico(
          alunoId: aluno?.id ?? '',
          sexo: sexoSelecionado,
          altura: alturaController.text.trim().isEmpty
              ? '0'
              : alturaController.text.trim(),
        );
        _showResult(r1 && r2);
        if (r1 && r2) await _carregarAluno();
      },
    );
  }

  Widget _buildAvaliacaoForm() {
    final c = AppColors.of(context);
    return _buildForm(
      [
        _buildEditableField(
          'Peso Atual (kg)',
          pesoController,
          icon: Icons.monitor_weight_outlined,
          number: true,
        ),
        _buildEditableField(
          'Altura (cm)',
          alturaController,
          icon: Icons.height_rounded,
          number: true,
        ),
        _buildEditableField(
          'Percentual Gordura (%)',
          gorduraController,
          icon: Icons.water_drop_outlined,
          number: true,
        ),
        _buildEditableField(
          'Percentual Músculo (%)',
          musculoController,
          icon: Icons.fitness_center_rounded,
          number: true,
        ),
        Builder(
          builder: (context) {
            final c = AppColors.of(context);
            final peso =
                double.tryParse(pesoController.text.replaceAll(',', '.')) ?? 0;
            double alt =
                double.tryParse(alturaController.text.replaceAll(',', '.')) ??
                0;
            if (alt > 3) alt = alt / 100;
            final imcValor = (peso > 0 && alt > 0) ? peso / (alt * alt) : 0.0;
            final imcTexto = imcValor > 0 ? imcValor.toStringAsFixed(2) : '-';
            String classificacao = '';
            Color imcCor = c.textHint;
            if (imcValor > 0) {
              if (imcValor < 18.5) {
                classificacao = 'Abaixo do peso';
                imcCor = c.accent;
              } else if (imcValor < 25) {
                final c = AppColors.of(context);
                classificacao = 'Normal';
                imcCor = c.success;
              } else if (imcValor < 30) {
                final c = AppColors.of(context);
                classificacao = 'Sobrepeso';
                imcCor = c.warning;
              } else if (imcValor < 35) {
                final c = AppColors.of(context);
                classificacao = 'Obesidade grau I';
                imcCor = c.error;
              } else if (imcValor < 40) {
                final c = AppColors.of(context);
                classificacao = 'Obesidade grau II';
                imcCor = c.error;
              } else {
                classificacao = 'Obesidade mórbida';
                imcCor = c.error;
              }
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: InputDecorator(
                decoration: _inputDecoration(
                  'IMC (calculado)',
                  Icons.calculate_outlined,
                ),
                child: Row(
                  children: [
                    Text(
                      imcTexto,
                      style: TextStyle(
                        color: imcCor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (classificacao.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: imcCor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: imcCor.withOpacity(0.5)),
                        ),
                        child: Text(
                          classificacao,
                          style: TextStyle(color: imcCor, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        Divider(color: c.border.withOpacity(0.6), height: 32, thickness: 0.8),
        _buildEditableField(
          'Cintura (cm)',
          cinturaController,
          icon: Icons.straighten_rounded,
          number: true,
        ),
        _buildEditableField(
          'Abdômen (cm)',
          abdomenController,
          icon: Icons.straighten_rounded,
          number: true,
        ),
        _buildEditableField(
          'Quadril (cm)',
          quadrilController,
          icon: Icons.straighten_rounded,
          number: true,
        ),
        _buildEditableField(
          'Peito (cm)',
          peitoController,
          icon: Icons.straighten_rounded,
          number: true,
        ),
        _buildEditableField(
          'Braço Direito (cm)',
          bracoDirController,
          icon: Icons.straighten_rounded,
          number: true,
        ),
        _buildEditableField(
          'Braço Esquerdo (cm)',
          bracoEsqController,
          icon: Icons.straighten_rounded,
          number: true,
        ),
        _buildEditableField(
          'Coxa Direita (cm)',
          coxaDirController,
          icon: Icons.straighten_rounded,
          number: true,
        ),
        _buildEditableField(
          'Coxa Esquerda (cm)',
          coxaEsqController,
          icon: Icons.straighten_rounded,
          number: true,
        ),
      ],
      onSave: () async {
        final sucesso = await AuthService().salvarMedidas(
          alunoId: aluno?.id ?? '',
          evolucaoId: null,
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
          cintura: cinturaController.text.trim(),
          abdomen: abdomenController.text.trim(),
          quadril: quadrilController.text.trim(),
          peito: peitoController.text.trim(),
          bracoDireito: bracoDirController.text.trim(),
          bracoEsquerdo: bracoEsqController.text.trim(),
          coxaDireita: coxaDirController.text.trim(),
          coxaEsquerda: coxaEsqController.text.trim(),
        );
        _showResult(sucesso);
        if (sucesso) await _carregarAluno();
      },
    );
  }

  Widget _buildObjetivoForm() {
    return _buildForm(
      [
        _buildEditableField(
          'Objetivo',
          objetivoController,
          icon: Icons.flag_outlined,
        ),
        _buildEditableField(
          'Nível Treinamento',
          nivelController,
          icon: Icons.trending_up_rounded,
        ),
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
    final c = AppColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border.withOpacity(0.7), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(children: fields),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 20),
              label: const Text('Salvar alterações'),
              onPressed: onSave,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.accent,
                side: BorderSide(color: c.border, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final c = AppColors.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: c.textHint, fontSize: 13),
      floatingLabelStyle: TextStyle(color: c.textSub, fontSize: 13),
      prefixIcon: Icon(icon, color: c.textHint, size: 20),
      filled: true,
      fillColor: c.inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.primary, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildReadOnlyField(
    String label,
    String value, {
    required IconData icon,
  }) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InputDecorator(
        decoration: _inputDecoration(label, icon).copyWith(
          suffixIcon: Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: c.textHint,
          ),
          fillColor: c.inputBg.withOpacity(0.5),
        ),
        child: Text(value, style: TextStyle(color: c.textHint, fontSize: 15)),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    required IconData icon,
    bool number = false,
    MaskTextInputFormatter? mask,
  }) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: c.textSub, fontSize: 15),
        cursorColor: c.primary,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: mask != null ? [mask] : [],
        decoration: _inputDecoration(label, icon),
      ),
    );
  }

  void _showResult(bool sucesso) {
    final c = AppColors.of(context);
    final color = sucesso ? c.success : c.error;
    final icon = sucesso
        ? Icons.check_circle_outline_rounded
        : Icons.error_outline_rounded;
    final msg = sucesso
        ? 'Dados atualizados com sucesso!'
        : 'Erro ao atualizar';
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  msg,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
