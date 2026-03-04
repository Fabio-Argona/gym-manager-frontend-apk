import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constants.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg1 = Color(0xFF0D0D1A);
const _bg2 = Color(0xFF1A1040);
const _card = Color(0xFF1C1B2E);
const _primary = Color(0xFF7C3AED);
const _accent = Color(0xFF06B6D4);
const _success = Color(0xFF10B981);
const _warning = Color(0xFFF59E0B);
const _error = Color(0xFFEF4444);
const _inputBg = Color(0xFF252438);
const _border = Color(0xFF3A3857);
const _textHint = Color(0xFF8884A8);
const _textSub = Color(0xFFB0ADCC);

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

  // Evoluções (lista, ordenada por data asc)
  List<Map<String, dynamic>> _evolucoes = [];

  // Sessões de treino
  List<Map<String, dynamic>> _sessoes = [];

  // Carga máxima
  double _cargaMax = 0;

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
        _evolucoes = lista.cast<Map<String, dynamic>>();
      }

      // Sessões
      if (results[2].statusCode == 200) {
        final lista = jsonDecode(results[2].body) as List;
        _sessoes = lista.cast<Map<String, dynamic>>();
      }

      // Carga máxima
      if (results[3].statusCode == 200) {
        final lista = jsonDecode(results[3].body) as List;
        double max = 0;
        for (final ex in lista) {
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
    if (imc <= 0) return _textHint;
    if (imc < 18.5) return _accent;
    if (imc < 25) return _success;
    if (imc < 30) return _warning;
    return _error;
  }

  int get _totalTreinos => _sessoes.length;

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

  List<Map<String, dynamic>> get _ultimasSessoes =>
      _sessoes.reversed.take(5).toList();

  Map<String, int> get _grupoCount {
    final map = <String, int>{};
    for (final s in _sessoes) {
      final nome = (s['grupoNome'] ?? s['grupo_nome'] ?? s['nome'] ?? '')
          .toString();
      if (nome.isEmpty) continue;
      map[nome] = (map[nome] ?? 0) + 1;
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
    return WillPopScope(
      onWillPop: () async => false,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _erro != null
          ? _buildErro()
          : RefreshIndicator(
              onRefresh: _carregar,
              color: _primary,
              backgroundColor: _card,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildStatsRow(),
                  const SizedBox(height: 16),
                  _buildImcCard(),
                  const SizedBox(height: 16),
                  _buildEvolucaoCard(),
                  const SizedBox(height: 16),
                  _buildHistoricoCard(),
                  const SizedBox(height: 16),
                  _buildGrupoMuscularChart(),
                  if (_objetivo.isNotEmpty || _nivel.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildObjetivoCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: _textHint, size: 48),
          const SizedBox(height: 12),
          Text(_erro!, style: const TextStyle(color: _textSub)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _carregar,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: const BorderSide(color: _border),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seu Progresso',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        if (_ultimaEvolucao != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const Icon(Icons.update_rounded, color: _textHint, size: 13),
                const SizedBox(width: 4),
                Text(
                  _formatarData(
                    _ultimaEvolucao!['data']?.toString() ??
                        _ultimaEvolucao!['createdAt']?.toString(),
                  ),
                  style: const TextStyle(color: _textHint, fontSize: 11),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Stats row ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final peso = _ultimaEvolucao?['peso'];
    final pesoLabel = peso != null ? '${peso.toString()} kg' : '-';
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.fitness_center_rounded,
            value: '$_totalTreinos',
            label: 'Treinos',
            color: _primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.calendar_today_rounded,
            value: '$_diasAtivos',
            label: 'Dias ativos',
            color: _accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: _cargaMax > 0
                ? Icons.whatshot_rounded
                : Icons.monitor_weight_outlined,
            value: _cargaMax > 0
                ? '${_cargaMax.toStringAsFixed(0)}kg'
                : pesoLabel,
            label: _cargaMax > 0 ? 'Carga máx' : 'Peso atual',
            color: _warning,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: _textHint, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── IMC Card ───────────────────────────────────────────────────────────────

  Widget _buildImcCard() {
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
          _sectionTitle('IMC', Icons.calculate_outlined, _accent),
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
                        backgroundColor: _inputBg,
                        valueColor: AlwaysStoppedAnimation(cor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '14',
                          style: TextStyle(color: _textHint, fontSize: 10),
                        ),
                        Text(
                          '40',
                          style: TextStyle(color: _textHint, fontSize: 10),
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
    final u = _ultimaEvolucao;
    if (u == null) return const SizedBox.shrink();

    final itens = [
      _EvolItem('Peso', 'kg', 'peso', Icons.monitor_weight_outlined, _accent),
      _EvolItem(
        'Gordura',
        '%',
        'percentualGordura',
        Icons.water_drop_outlined,
        _warning,
      ),
      _EvolItem(
        'Músculo',
        '%',
        'percentualMusculo',
        Icons.fitness_center_rounded,
        _success,
      ),
    ];

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Evolução Corporal',
            Icons.trending_up_rounded,
            _primary,
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
          if (_evolucoes.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Comparado ao início (${_formatarData(_primeiraEvolucao?['data']?.toString())})',
                style: const TextStyle(color: _textHint, fontSize: 11),
              ),
            ),
        ],
      ),
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
    final hasDelta = delta != null && delta != 0;
    final isPositive = (delta ?? 0) > 0;
    final deltaColor = isPositive ? _error : _success;
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
              Text(
                label,
                style: const TextStyle(color: _textSub, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '${value.toStringAsFixed(1)} $unidade',
                style: const TextStyle(
                  color: Colors.white,
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

  // ─── Histórico Card ─────────────────────────────────────────────────────────

  Widget _buildHistoricoCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Últimos Treinos', Icons.history_rounded, _primary),
          const SizedBox(height: 12),
          if (_ultimasSessoes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, color: _textHint, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Nenhum treino registrado ainda.',
                    style: TextStyle(color: _textHint, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_ultimasSessoes.length, (i) {
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
                      color: _border.withOpacity(0.5),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.fitness_center_rounded,
                              color: _primary,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            nome.toString(),
                            style: const TextStyle(
                              color: Colors.white,
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
                            color: _inputBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            data,
                            style: const TextStyle(
                              color: _textHint,
                              fontSize: 11,
                            ),
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
    final grupos = _grupoCount;
    if (grupos.isEmpty) return const SizedBox.shrink();
    final maxVal = grupos.values.first.toDouble();
    final entries = grupos.entries.toList();

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Grupos Musculares', Icons.bar_chart_rounded, _primary),
          const SizedBox(height: 6),
          Text(
            'Treinos por grupo — total: ${_sessoes.length}',
            style: const TextStyle(color: _textHint, fontSize: 11),
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
                          style: const TextStyle(
                            color: Colors.white,
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
                      return Stack(
                        children: [
                          Container(
                            height: 8,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              color: _inputBg,
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
        ],
      ),
    );
  }

  // ─── Objetivo Card ──────────────────────────────────────────────────────────

  Widget _buildObjetivoCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Meta & Nível', Icons.flag_outlined, _success),
          const SizedBox(height: 14),
          if (_objetivo.isNotEmpty)
            _infoRow(
              Icons.emoji_events_outlined,
              'Objetivo',
              _objetivo,
              _warning,
            ),
          if (_nivel.isNotEmpty) ...[
            if (_objetivo.isNotEmpty) const SizedBox(height: 10),
            _infoRow(Icons.trending_up_rounded, 'Nível', _nivel, _accent),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
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
              Text(
                label,
                style: const TextStyle(color: _textHint, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
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
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border.withOpacity(0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _sectionTitle(String label, IconData icon, Color color) {
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
          style: const TextStyle(
            color: Colors.white,
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
