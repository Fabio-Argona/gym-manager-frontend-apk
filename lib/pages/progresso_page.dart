import 'dart:convert';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constants.dart';
import '../constants/app_theme.dart';

class ProgressoPage extends StatefulWidget {
  const ProgressoPage({super.key});

  @override
  State<ProgressoPage> createState() => _ProgressoPageState();
}

class _ProgressoPageState extends State<ProgressoPage> {
  bool _loading = true;
  String? _erro;

  // Aluno
  String _nome = '';
  String _objetivo = '';
  String _nivel = '';

  // ID do aluno logado
  String _alunoId = '';

  // Evoluções (lista, ordenada por data asc)
  List<Map<String, dynamic>> _evolucoes = [];

  // Sessões de treino
  List<Map<String, dynamic>> _sessoes = [];

  // Exercícios realizados (progressão)
  List<Map<String, dynamic>> _progressao = [];

  // Carga máxima
  double _cargaMax = 0;

  // Calendário
  DateTime _mesCalendario = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final alunoId = prefs.getString('alunoId') ?? '';
      _alunoId = alunoId;
      final token = prefs.getString('token') ?? '';
      if (alunoId.isEmpty || token.isEmpty) {
        setState(() {
          _erro = 'Sessão inválida';
          _loading = false;
        });
        return;
      }
      final headers = {'Authorization': 'Bearer $token'};

      final results = await Future.wait([
        http.get(Uri.parse('$endpointAlunos/$alunoId'), headers: headers),
        http.get(
          Uri.parse('${baseUrl}/evolucoes/aluno/$alunoId'),
          headers: headers,
        ),
        http.get(
          Uri.parse('$endpointTreinosRealizado/aluno/$alunoId'),
          headers: headers,
        ),
        http.get(
          Uri.parse(
            '$endpointExerciciosRealizados/progressao?alunoId=$alunoId',
          ),
          headers: headers,
        ),
      ]);

      // Aluno
      if (results[0].statusCode == 200) {
        final a = jsonDecode(results[0].body);
        _nome = a['nome'] ?? '';
        _objetivo = a['objetivo'] ?? '';
        _nivel = a['nivelTreinamento'] ?? '';
      }

      // Evoluções
      if (results[1].statusCode == 200) {
        final lista = jsonDecode(results[1].body) as List;
        _evolucoes = lista.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          // Normaliza o campo 'data': pode vir como [ano,mes,dia] ou "yyyy-MM-dd"
          final raw = m['data'];
          if (raw is List && raw.length >= 3) {
            final y = raw[0].toString().padLeft(4, '0');
            final mo = raw[1].toString().padLeft(2, '0');
            final d = raw[2].toString().padLeft(2, '0');
            m['data'] = '$y-$mo-$d';
          }
          return m;
        }).toList();
        // Garante ordem ascendente por data
        _evolucoes.sort(
          (a, b) => (a['data']?.toString() ?? '').compareTo(
            b['data']?.toString() ?? '',
          ),
        );
      }

      // Sessões
      if (results[2].statusCode == 200) {
        final lista = jsonDecode(results[2].body) as List;
        _sessoes = lista.cast<Map<String, dynamic>>();
      }

      // Carga máxima
      if (results[3].statusCode == 200) {
        final lista = jsonDecode(results[3].body) as List;
        _progressao = lista.cast<Map<String, dynamic>>();
        double max = 0;
        for (final ex in _progressao) {
          final peso = (ex['peso_utilizado'] ?? ex['pesoUtilizado'] ?? 0)
              .toDouble();
          if (peso > max) max = peso;
        }
        _cargaMax = max;
      }
    } catch (e) {
      _erro = 'Erro ao carregar dados';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Helpers de dados ───────────────────────────────────────────────────────

  Map<String, dynamic>? get _ultimaEvolucao =>
      _evolucoes.isNotEmpty ? _evolucoes.last : null;

  Map<String, dynamic>? get _primeiraEvolucao =>
      _evolucoes.length > 1 ? _evolucoes.first : null;

  double? _delta(String campo) {
    final u = _ultimaEvolucao;
    final p = _primeiraEvolucao;
    if (u == null || p == null) return null;
    final vU = (u[campo] ?? 0).toDouble();
    final vP = (p[campo] ?? 0).toDouble();
    if (vP == 0) return null;
    return vU - vP;
  }

  double _imc() {
    final u = _ultimaEvolucao;
    if (u == null) return 0;
    double peso = (u['peso'] ?? 0).toDouble();
    double alt = (u['altura'] ?? 0).toDouble();
    if (alt > 3) alt = alt / 100;
    if (peso > 0 && alt > 0) return peso / (alt * alt);
    return 0;
  }

  String _imcClassificacao(double imc) {
    if (imc <= 0) return '';
    if (imc < 18.5) return 'Abaixo do peso';
    if (imc < 25) return 'Normal';
    if (imc < 30) return 'Sobrepeso';
    if (imc < 35) return 'Obesidade grau I';
    if (imc < 40) return 'Obesidade grau II';
    return 'Obesidade mórbida';
  }

  Color _imcCor(double imc) {
    final c = AppColors.of(context);
    if (imc <= 0) return c.textHint;
    if (imc < 18.5) return c.accent;
    if (imc < 25) return c.success;
    if (imc < 30) return c.warning;
    return c.error;
  }

  int get _totalTreinos => _sessoes.length;

  // ─── Nível / Recompensas ─────────────────────────────────────────────────────

  static const _limitesNivel = [0, 10, 30, 60, 100, 150, 200, 300, 500];
  static const _nomesNivel = [
    'Iniciante',
    'Aprendiz',
    'Dedicado',
    'Consistente',
    'Intermediário',
    'Avançado',
    'Elite',
    'Mestre',
    'Lendário',
  ];

  String _nivelAtual() {
    final d = _diasAtivos;
    for (int i = _limitesNivel.length - 1; i >= 0; i--) {
      if (d >= _limitesNivel[i]) return _nomesNivel[i];
    }
    return _nomesNivel[0];
  }

  Color _corNivel() {
    final c = AppColors.of(context);
    final d = _diasAtivos;
    if (d >= 500) return const Color(0xFFFFD700);
    if (d >= 300) return const Color(0xFFAB47BC);
    if (d >= 200) return const Color(0xFF26C6DA);
    if (d >= 150) return const Color(0xFF42A5F5);
    if (d >= 100) return c.success;
    if (d >= 60) return c.warning;
    if (d >= 30) return c.accent;
    if (d >= 10) return c.primary;
    return c.textHint;
  }

  IconData _iconNivel() {
    final d = _diasAtivos;
    if (d >= 500) return Icons.auto_awesome_rounded;
    if (d >= 300) return Icons.workspace_premium_rounded;
    if (d >= 200) return Icons.diamond_rounded;
    if (d >= 150) return Icons.star_rounded;
    if (d >= 100) return Icons.emoji_events_rounded;
    if (d >= 60) return Icons.local_fire_department_rounded;
    if (d >= 30) return Icons.fitness_center_rounded;
    if (d >= 10) return Icons.bolt_rounded;
    return Icons.eco_rounded;
  }

  int _proximoNivelDias() {
    final d = _diasAtivos;
    for (final lim in _limitesNivel) {
      if (d < lim) return lim;
    }
    return 500;
  }

  int get _diasAtivos {
    final datas = _sessoes
        .map(
          (s) => (s['data'] ?? s['dataSessao'] ?? s['data_sessao'] ?? '')
              .toString(),
        )
        .where((d) => d.isNotEmpty)
        .map((d) => d.substring(0, 10))
        .toSet();
    return datas.length;
  }

  Set<String> get _datasAtivas {
    return _sessoes
        .map(
          (s) => (s['data'] ?? s['dataSessao'] ?? s['data_sessao'] ?? '')
              .toString(),
        )
        .where((d) => d.length >= 10)
        .map((d) => d.substring(0, 10))
        .toSet();
  }

  List<Map<String, dynamic>> get _ultimasSessoes =>
      _sessoes.reversed.take(5).toList();

  Map<String, int> get _grupoCount {
    final map = <String, int>{};
    for (final ex in _progressao) {
      final raw = (ex['grupoMuscular'] ?? ex['grupo_muscular'] ?? '')
          .toString()
          .trim();
      final grupo = raw.isEmpty ? 'Outros' : raw;
      map[grupo] = (map[grupo] ?? 0) + 1;
    }
    // ordena por contagem decrescente
    final sorted = Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }

  String _formatarData(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final d = DateTime.parse(raw);
      return DateFormat('dd/MM/yy').format(d);
    } catch (_) {
      return raw.substring(0, 10);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return WillPopScope(
      onWillPop: () async => false,
      child: _loading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : _erro != null
          ? _buildErro()
          : RefreshIndicator(
              onRefresh: _carregar,
              color: c.primary,
              backgroundColor: c.card,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 10),
                  _buildHistoricoCard(),
                  const SizedBox(height: 10),
                  _buildRecompensasCard(),
                  const SizedBox(height: 10),
                  _buildCalendario(),
                  if (_imc() != 0) ...[
                    const SizedBox(height: 10),
                    _buildImcCard(),
                  ],
                  if (_ultimaEvolucao != null) ...[
                    const SizedBox(height: 10),
                    _buildEvolucaoCard(),
                  ],
                  if (_grupoCount.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildGrupoMuscularChart(),
                  ],
                  if (_objetivo.isNotEmpty || _diasAtivos >= 0) ...[
                    const SizedBox(height: 10),
                    _buildObjetivoCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildErro() {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, color: c.textHint, size: 48),
          const SizedBox(height: 12),
          Text(_erro!, style: TextStyle(color: c.textSub)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _carregar,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.accent,
              side: BorderSide(color: c.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final c = AppColors.of(context);
    final cor = _corNivel();
    final nivel = _nivelAtual();
    final icon = _iconNivel();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seu Progresso',
                style: TextStyle(
                  color: c.textSub,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    color: c.textHint,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_totalTreinos treinos',
                    style: TextStyle(color: c.textHint, fontSize: 11),
                  ),
                  Text(
                    '  ·  ',
                    style: TextStyle(color: c.textHint, fontSize: 11),
                  ),
                  Icon(
                    Icons.calendar_today_rounded,
                    color: c.textHint,
                    size: 11,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_diasAtivos dias ativos',
                    style: TextStyle(color: c.textHint, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: cor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cor.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(icon, color: cor, size: 14),
              const SizedBox(width: 6),
              Text(
                nivel,
                style: TextStyle(
                  color: cor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Calendário ────────────────────────────────────────────────────────────

  Widget _buildCalendario() {
    final c = AppColors.of(context);
    final datas = _datasAtivas;
    final ano = _mesCalendario.year;
    final mes = _mesCalendario.month;
    final primeiroDia = DateTime(ano, mes, 1);
    final ultimoDia = DateTime(ano, mes + 1, 0);
    final diasNoMes = ultimoDia.day;
    final inicioSemana = primeiroDia.weekday % 7; // 0=Dom
    final hoje = DateTime.now();
    final labels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    final meses = [
      '',
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: c.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Calendário de Treinos',
                style: TextStyle(
                  color: c.textSub,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Navegação de mês
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _mesCalendario = DateTime(ano, mes - 1);
                }),
                icon: Icon(Icons.chevron_left_rounded, color: c.textHint),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              Text(
                '${meses[mes]} $ano',
                style: TextStyle(
                  color: c.textSub,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _mesCalendario = DateTime(ano, mes + 1);
                }),
                icon: Icon(Icons.chevron_right_rounded, color: c.textHint),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Cabeçalho dias da semana
          Row(
            children: labels
                .map(
                  (l) => Expanded(
                    child: Center(
                      child: Text(
                        l,
                        style: TextStyle(
                          color: c.textHint,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          // Grade do mês
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: inicioSemana + diasNoMes,
            itemBuilder: (_, i) {
              if (i < inicioSemana) return const SizedBox.shrink();
              final dia = i - inicioSemana + 1;
              final dataStr =
                  '$ano-${mes.toString().padLeft(2, '0')}-${dia.toString().padLeft(2, '0')}';
              final treinou = datas.contains(dataStr);
              final ehHoje =
                  dia == hoje.day && mes == hoje.month && ano == hoje.year;
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: treinou
                      ? c.primary.withOpacity(0.85)
                      : ehHoje
                      ? c.accent.withOpacity(0.15)
                      : Colors.transparent,
                  border: ehHoje && !treinou
                      ? Border.all(color: c.accent.withOpacity(0.6), width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$dia',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: treinou || ehHoje
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: treinou
                          ? Colors.white
                          : ehHoje
                          ? c.accent
                          : c.textHint,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Legenda
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Dia treinado',
                style: TextStyle(color: c.textHint, fontSize: 11),
              ),
              const SizedBox(width: 16),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.accent, width: 1.5),
                ),
              ),
              const SizedBox(width: 6),
              Text('Hoje', style: TextStyle(color: c.textHint, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Recompensas Card ──────────────────────────────────────────────────────

  Widget _buildRecompensasCard() {
    final c = AppColors.of(context);
    final dias = _diasAtivos;
    final cor = _corNivel();
    final proximo = _proximoNivelDias();

    // Faixa do nível atual para barra de progresso
    int prevLim = 0;
    for (int i = _limitesNivel.length - 1; i >= 0; i--) {
      if (dias >= _limitesNivel[i]) {
        prevLim = _limitesNivel[i];
        break;
      }
    }
    final range = proximo - prevLim;
    final progress = dias >= 500
        ? 1.0
        : ((dias - prevLim) / range).clamp(0.0, 1.0);

    // Badges: marcos de 10 em 10 até 100, depois 150, 200, 300, 500
    const marcos = [
      10,
      20,
      30,
      40,
      50,
      60,
      70,
      80,
      90,
      100,
      150,
      200,
      250,
      300,
      350,
      400,
      450,
      500,
    ];
    final badgeIcons = {
      10: Icons.bolt_rounded,
      20: Icons.bolt_rounded,
      30: Icons.fitness_center_rounded,
      40: Icons.fitness_center_rounded,
      50: Icons.local_fire_department_rounded,
      60: Icons.local_fire_department_rounded,
      70: Icons.local_fire_department_rounded,
      80: Icons.star_half_rounded,
      90: Icons.star_half_rounded,
      100: Icons.emoji_events_rounded,
      150: Icons.star_rounded,
      200: Icons.diamond_rounded,
      250: Icons.diamond_rounded,
      300: Icons.workspace_premium_rounded,
      350: Icons.workspace_premium_rounded,
      400: Icons.military_tech_rounded,
      450: Icons.military_tech_rounded,
      500: Icons.auto_awesome_rounded,
    };
    final badgeLabels = {
      10: '10d',
      20: '20d',
      30: '30d',
      40: '40d',
      50: '50d',
      60: '60d',
      70: '70d',
      80: '80d',
      90: '90d',
      100: '100d',
      150: '150d',
      200: '200d',
      250: '250d',
      300: '300d',
      350: '350d',
      400: '400d',
      450: '450d',
      500: '500d',
    };

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Icon(Icons.military_tech_rounded, color: c.warning, size: 18),
              const SizedBox(width: 6),
              Text(
                'Conquistas',
                style: TextStyle(
                  color: c.textSub,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barra de XP
          Row(
            children: [
              Text(
                '$dias dias',
                style: TextStyle(
                  color: c.textSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                dias >= 500
                    ? 'Nível máximo!'
                    : '$proximo dias para ${_nomesNivel[_limitesNivel.indexOf(proximo)]}',
                style: TextStyle(color: c.textHint, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: c.border.withOpacity(0.4),
              valueColor: AlwaysStoppedAnimation<Color>(cor),
            ),
          ),
          const SizedBox(height: 16),

          // Badges
          Text(
            'Marcos desbloqueados',
            style: TextStyle(color: c.textHint, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: marcos.map((m) {
              final c = AppColors.of(context);
              final unlocked = dias >= m;
              final badgeCor = unlocked ? cor : c.border;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unlocked ? badgeCor.withOpacity(0.18) : c.inputBg,
                      border: Border.all(
                        color: unlocked
                            ? badgeCor.withOpacity(0.7)
                            : c.border.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      badgeIcons[m]!,
                      color: unlocked ? badgeCor : c.textHint.withOpacity(0.3),
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    badgeLabels[m]!,
                    style: TextStyle(
                      color: unlocked
                          ? cor.withOpacity(0.85)
                          : c.textHint.withOpacity(0.35),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── IMC Card ───────────────────────────────────────────────────────────────

  Widget _buildImcCard() {
    final c = AppColors.of(context);
    final imc = _imc();
    final cor = _imcCor(imc);
    final classe = _imcClassificacao(imc);
    if (imc == 0) return const SizedBox.shrink();

    // normalized 0..1 for range 14..40
    final norm = ((imc - 14) / (40 - 14)).clamp(0.0, 1.0);

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('IMC', Icons.calculate_outlined, c.accent),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                imc.toStringAsFixed(1),
                style: TextStyle(
                  color: cor,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cor.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cor.withOpacity(0.4)),
                      ),
                      child: Text(
                        classe,
                        style: TextStyle(
                          color: cor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: norm,
                        backgroundColor: c.inputBg,
                        valueColor: AlwaysStoppedAnimation(cor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '14',
                          style: TextStyle(color: c.textHint, fontSize: 10),
                        ),
                        Text(
                          '40',
                          style: TextStyle(color: c.textHint, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Evolução Card ──────────────────────────────────────────────────────────

  Widget _buildEvolucaoCard() {
    final c = AppColors.of(context);
    final u = _ultimaEvolucao;
    if (u == null) return const SizedBox.shrink();

    final itens = [
      _EvolItem('Peso', 'kg', 'peso', Icons.monitor_weight_outlined, c.accent),
      _EvolItem(
        'Gordura',
        '%',
        'percentualGordura',
        Icons.water_drop_outlined,
        c.warning,
      ),
      _EvolItem(
        'Músculo',
        '%',
        'percentualMusculo',
        Icons.fitness_center_rounded,
        c.success,
      ),
    ];

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Evolução Corporal',
            Icons.trending_up_rounded,
            c.primary,
          ),
          const SizedBox(height: 14),
          ...itens.map((it) {
            final val = (u[it.campo] ?? 0).toDouble();
            if (val == 0) return const SizedBox.shrink();
            final delta = _delta(it.campo);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _evolucaoRow(
                icon: it.icon,
                label: it.label,
                value: val,
                unidade: it.unidade,
                delta: delta,
                color: it.cor,
              ),
            );
          }),
          if (_evolucoes.length > 1) ...[
            _buildEvolucaoChart('peso', c.accent, 'kg'),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Comparado ao início (${_formatarData(_primeiraEvolucao?['data']?.toString())})',
                style: TextStyle(color: c.textHint, fontSize: 11),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: c.textHint),
                  const SizedBox(width: 6),
                  Text(
                    'Adicione mais medições para ver o gráfico',
                    style: TextStyle(color: c.textHint, fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showNovaMedicaoDialog() async {
    final c = AppColors.of(context);
    final u = _ultimaEvolucao;
    // Pré-preenche com os valores da última medição
    final pesoCtrl = TextEditingController(text: u?['peso']?.toString() ?? '');
    final alturaCtrl = TextEditingController(
      text: u?['altura']?.toString() ?? '',
    );
    final gorduraCtrl = TextEditingController(
      text: u?['percentualGordura']?.toString() ?? '',
    );
    final musculoCtrl = TextEditingController(
      text: u?['percentualMusculo']?.toString() ?? '',
    );
    final cinturaCtrl = TextEditingController(
      text: u?['cintura']?.toString() ?? '',
    );
    final abdomenCtrl = TextEditingController(
      text: u?['abdomen']?.toString() ?? '',
    );
    final quadrilCtrl = TextEditingController(
      text: u?['quadril']?.toString() ?? '',
    );
    final peitoCtrl = TextEditingController(
      text: u?['peito']?.toString() ?? '',
    );
    final bracoDirCtrl = TextEditingController(
      text: u?['bracoDireito']?.toString() ?? '',
    );
    final bracoEsqCtrl = TextEditingController(
      text: u?['bracoEsquerdo']?.toString() ?? '',
    );
    final coxaDirCtrl = TextEditingController(
      text: u?['coxaDireita']?.toString() ?? '',
    );
    final coxaEsqCtrl = TextEditingController(
      text: u?['coxaEsquerda']?.toString() ?? '',
    );
    bool salvando = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            InputDecoration dec(String label) => InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: c.textHint, fontSize: 13),
              filled: true,
              fillColor: c.inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: c.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            );

            Widget field(TextEditingController ctrl, String label) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(color: c.textSub, fontSize: 14),
                decoration: dec(label),
              ),
            );

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: c.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nova Medição',
                      style: TextStyle(
                        color: c.textSub,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    field(pesoCtrl, 'Peso (kg)'),
                    field(alturaCtrl, 'Altura (cm)'),
                    field(gorduraCtrl, '% Gordura'),
                    field(musculoCtrl, '% Músculo'),
                    field(cinturaCtrl, 'Cintura (cm)'),
                    field(abdomenCtrl, 'Abdômen (cm)'),
                    field(quadrilCtrl, 'Quadril (cm)'),
                    field(peitoCtrl, 'Peito (cm)'),
                    field(bracoDirCtrl, 'Braço Direito (cm)'),
                    field(bracoEsqCtrl, 'Braço Esquerdo (cm)'),
                    field(coxaDirCtrl, 'Coxa Direita (cm)'),
                    field(coxaEsqCtrl, 'Coxa Esquerda (cm)'),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: salvando
                            ? null
                            : () async {
                                setModalState(() => salvando = true);
                                try {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final token = prefs.getString('token') ?? '';
                                  final body = jsonEncode({
                                    'alunoId': _alunoId,
                                    'peso': double.tryParse(pesoCtrl.text),
                                    'altura': double.tryParse(alturaCtrl.text),
                                    'percentualGordura': double.tryParse(
                                      gorduraCtrl.text,
                                    ),
                                    'percentualMusculo': double.tryParse(
                                      musculoCtrl.text,
                                    ),
                                    'cintura': double.tryParse(
                                      cinturaCtrl.text,
                                    ),
                                    'abdomen': double.tryParse(
                                      abdomenCtrl.text,
                                    ),
                                    'quadril': double.tryParse(
                                      quadrilCtrl.text,
                                    ),
                                    'peito': double.tryParse(peitoCtrl.text),
                                    'bracoDireito': double.tryParse(
                                      bracoDirCtrl.text,
                                    ),
                                    'bracoEsquerdo': double.tryParse(
                                      bracoEsqCtrl.text,
                                    ),
                                    'coxaDireita': double.tryParse(
                                      coxaDirCtrl.text,
                                    ),
                                    'coxaEsquerda': double.tryParse(
                                      coxaEsqCtrl.text,
                                    ),
                                  });
                                  final res = await http.post(
                                    Uri.parse('$baseUrl/evolucoes'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization': 'Bearer $token',
                                    },
                                    body: body,
                                  );
                                  if (res.statusCode == 200 ||
                                      res.statusCode == 201) {
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    _carregar();
                                  } else {
                                    setModalState(() => salvando = false);
                                  }
                                } catch (_) {
                                  setModalState(() => salvando = false);
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: c.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: salvando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Salvar Medição'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _evolucaoRow({
    required IconData icon,
    required String label,
    required double value,
    required String unidade,
    double? delta,
    required Color color,
  }) {
    final c = AppColors.of(context);
    final hasDelta = delta != null && delta != 0;
    final isPositive = (delta ?? 0) > 0;
    final deltaColor = isPositive ? c.error : c.success;
    // For gordura, positive delta = bad; for other fields context varies
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: c.textSub, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                '${value.toStringAsFixed(1)} $unidade',
                style: TextStyle(
                  color: c.textSub,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (hasDelta)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: deltaColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: deltaColor,
                  size: 13,
                ),
                const SizedBox(width: 2),
                Text(
                  '${delta!.abs().toStringAsFixed(1)} $unidade',
                  style: TextStyle(
                    color: deltaColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Evolução Chart ──────────────────────────────────────────────────────────

  Widget _buildEvolucaoChart(String campo, Color color, String unidade) {
    if (_evolucoes.length < 2) return const SizedBox.shrink();
    final c = AppColors.of(context);
    final spots = <FlSpot>[];
    for (int i = 0; i < _evolucoes.length; i++) {
      final val = (_evolucoes[i][campo] as num?)?.toDouble() ?? 0;
      if (val > 0) spots.add(FlSpot(i.toDouble(), val));
    }
    if (spots.length < 2) return const SizedBox.shrink();
    final minY = spots.map((s) => s.y).reduce(math.min);
    final maxY = spots.map((s) => s.y).reduce(math.max);
    final pad = (maxY - minY) * 0.15 + 0.5;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: SizedBox(
        height: 130,
        child: LineChart(
          LineChartData(
            minY: minY - pad,
            maxY: maxY + pad,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: c.border.withOpacity(0.25), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 46,
                  getTitlesWidget: (v, meta) {
                    if (v == meta.min || v == meta.max) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        '${v.toStringAsFixed(1)}$unidade',
                        style: TextStyle(color: c.textHint, fontSize: 9),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: math.max(1, (_evolucoes.length / 4).ceilToDouble()),
                  getTitlesWidget: (x, _) {
                    final idx = x.toInt();
                    if (idx < 0 ||
                        idx >= _evolucoes.length ||
                        x != x.floorToDouble()) {
                      return const SizedBox.shrink();
                    }
                    final raw = _evolucoes[idx]['data']?.toString() ?? '';
                    final parts = raw.split('-');
                    final label = parts.length >= 3
                        ? '${parts[2].padLeft(2, "0")}/${parts[1]}'
                        : '';
                    return Text(
                      label,
                      style: TextStyle(color: c.textHint, fontSize: 9),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: color,
                barWidth: 2.5,
                dotData: FlDotData(show: spots.length <= 7),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withOpacity(0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Histórico Card ─────────────────────────────────────────────────────────

  Widget _buildHistoricoCard() {
    final c = AppColors.of(context);
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Últimos Treinos', Icons.history_rounded, c.primary),
          const SizedBox(height: 12),
          if (_ultimasSessoes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: c.textHint, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Nenhum treino registrado ainda.',
                    style: TextStyle(color: c.textHint, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_ultimasSessoes.length, (i) {
              final c = AppColors.of(context);
              final s = _ultimasSessoes[i];
              final nome =
                  s['grupoNome'] ?? s['grupo_nome'] ?? s['nome'] ?? 'Treino';
              final data = _formatarData(
                s['data'] ?? s['dataSessao'] ?? s['data_sessao'],
              );
              return Column(
                children: [
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: c.border.withOpacity(0.5),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.fitness_center_rounded,
                              color: c.primary,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            nome.toString(),
                            style: TextStyle(
                              color: c.textSub,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: c.inputBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            data,
                            style: TextStyle(color: c.textHint, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  // ─── Grupo Muscular Chart ────────────────────────────────────────────────────

  static const List<Color> _barColors = [
    Color(0xFF7C3AED),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF0EA5E9),
  ];

  Widget _buildGrupoMuscularChart() {
    final c = AppColors.of(context);
    final grupos = _grupoCount;
    if (grupos.isEmpty) return const SizedBox.shrink();
    final maxVal = grupos.values.first.toDouble();
    final entries = grupos.entries.toList();

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Grupos Musculares',
            Icons.bar_chart_rounded,
            c.primary,
          ),
          const SizedBox(height: 6),
          Text(
            'Exercícios por grupo muscular — total: ${_progressao.length}',
            style: TextStyle(color: c.textHint, fontSize: 11),
          ),
          const SizedBox(height: 18),
          ...List.generate(entries.length, (i) {
            final grupo = entries[i].key;
            final count = entries[i].value;
            final pct = count / maxVal;
            final cor = _barColors[i % _barColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          grupo,
                          style: TextStyle(
                            color: c.textSub,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count ${count == 1 ? 'treino' : 'treinos'}',
                        style: TextStyle(
                          color: cor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final c = AppColors.of(context);
                      return Stack(
                        children: [
                          Container(
                            height: 8,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              color: c.inputBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            height: 8,
                            width: constraints.maxWidth * pct,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [cor.withOpacity(0.7), cor],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          }),
          _buildGrupoMuscularBarChart(),
        ],
      ),
    );
  }

  Widget _buildGrupoMuscularBarChart() {
    final c = AppColors.of(context);
    final grupos = _grupoCount;
    if (grupos.isEmpty) return const SizedBox.shrink();
    final entries = grupos.entries.toList();
    final maxVal = entries.first.value.toDouble();

    final barGroups = List.generate(entries.length, (i) {
      final cor = _barColors[i % _barColors.length];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: entries[i].value.toDouble(),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [cor.withOpacity(0.7), cor],
            ),
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxVal * 1.25,
              color: c.inputBg,
            ),
          ),
        ],
      );
    });

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: SizedBox(
        height: 140,
        child: BarChart(
          BarChartData(
            maxY: maxVal * 1.25,
            barGroups: barGroups,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: c.border.withOpacity(0.25), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, meta) {
                    if (v == meta.min || v == meta.max) {
                      return const SizedBox.shrink();
                    }
                    if (v != v.floorToDouble()) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        v.toInt().toString(),
                        style: TextStyle(color: c.textHint, fontSize: 9),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (x, _) {
                    final idx = x.toInt();
                    if (idx < 0 || idx >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    final nome = entries[idx].key;
                    final abrev = nome.length > 7
                        ? '${nome.substring(0, 6)}.'
                        : nome;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        abrev,
                        style: TextStyle(color: c.textHint, fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(enabled: false),
          ),
        ),
      ),
    );
  }

  // ─── Objetivo Card ──────────────────────────────────────────────────────────

  Widget _buildObjetivoCard() {
    final c = AppColors.of(context);
    final nivelCalculado = _nivelAtual();
    final corNivel = _corNivel();
    final iconNivel = _iconNivel();
    final proximo = _proximoNivel();
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Meta & Nível', Icons.flag_outlined, c.success),
          const SizedBox(height: 14),
          if (_objetivo.isNotEmpty)
            _infoRow(
              Icons.emoji_events_outlined,
              'Objetivo',
              _objetivo,
              c.warning,
            ),
          if (_objetivo.isNotEmpty) const SizedBox(height: 10),
          _infoRow(iconNivel, 'Nível', nivelCalculado, corNivel),
          const SizedBox(height: 10),
          _infoRow(
            Icons.calendar_today_outlined,
            'Dias Treinados',
            '$_diasAtivos dias',
            c.primary,
          ),
          if (proximo != null) ...[
            const SizedBox(height: 10),
            _nivelProgressBar(proximo, corNivel, c),
          ],
        ],
      ),
    );
  }

  ({String nome, int atual, int meta})? _proximoNivel() {
    for (int i = 0; i < _limitesNivel.length - 1; i++) {
      if (_diasAtivos < _limitesNivel[i + 1]) {
        return (
          nome: _nomesNivel[i + 1],
          atual: _diasAtivos - _limitesNivel[i],
          meta: _limitesNivel[i + 1] - _limitesNivel[i],
        );
      }
    }
    return null;
  }

  Widget _nivelProgressBar(
    ({String nome, int atual, int meta}) proximo,
    Color cor,
    AppColors c,
  ) {
    final progresso = (proximo.atual / proximo.meta).clamp(0.0, 1.0);
    final faltam = proximo.meta - proximo.atual;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Próximo: ${proximo.nome}',
              style: TextStyle(color: c.textHint, fontSize: 11),
            ),
            Text(
              'Faltam $faltam dias',
              style: TextStyle(color: c.textHint, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progresso,
            backgroundColor: cor.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(cor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: c.textHint, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: c.textSub,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Shared helpers ─────────────────────────────────────────────────────────

  Widget _sectionCard({required Widget child}) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border.withOpacity(0.7), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _sectionTitle(String label, IconData icon, Color color) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: c.textSub,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EvolItem {
  final String label;
  final String unidade;
  final String campo;
  final IconData icon;
  final Color cor;
  const _EvolItem(this.label, this.unidade, this.campo, this.icon, this.cor);
}
