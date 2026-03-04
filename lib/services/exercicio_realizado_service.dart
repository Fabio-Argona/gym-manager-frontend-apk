import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../dto/ExercicioRealizadoDTO.dart';
import '../constants/constants.dart';

class ExercicioRealizadoService {
  // INICIAR TREINO (criar TreinoRealizado)
  Future<String?> iniciarTreino(
    String grupoId,
    String data, {
    String grupoNome = '',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alunoId = prefs.getString('alunoId') ?? '';
      final token = prefs.getString('token') ?? '';

      if (alunoId.isEmpty || token.isEmpty) return null;

      // POST /treinos/realizado/{treinoId}?data=yyyy-MM-dd
      final uri = Uri.parse(
        '$endpointTreinosRealizado/$grupoId',
      ).replace(queryParameters: {'data': data});

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'aluno-id': alunoId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        print('Resposta iniciarTreino: ${response.body}');
        // tenta os campos mais comuns de ID
        final id =
            json['id']?.toString() ??
            json['treinoId']?.toString() ??
            json['treinoRealizadoId']?.toString() ??
            json['treino_id']?.toString();
        return id;
      }

      print(
        'Erro ao iniciar treino: ${response.statusCode} - ${response.body}',
      );

      return null;
    } catch (e) {
      print('Erro ao iniciar treino: $e');
      return null;
    }
  }

  // REGISTRAR EXERCÍCIO REALIZADO
  Future<bool> registrarExercicio({
    required String treinoRealizadoId,
    required String exercicioId,
    required int seriesRealizadas,
    required int repeticoesRealizadas,
    required double pesoUtilizado,
    required String dataSessao,
    String? observacoes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alunoId = prefs.getString('alunoId') ?? '';
      final token = prefs.getString('token') ?? '';

      if (alunoId.isEmpty || token.isEmpty) return false;

      final body = {
        'treino_realizado_id': treinoRealizadoId,
        'exercicio_id': exercicioId,
        'aluno_id': alunoId,
        'series_realizadas': seriesRealizadas,
        'repeticoes_realizadas': repeticoesRealizadas,
        'peso_utilizado': pesoUtilizado,
        'data_sessao': dataSessao,
        'observacoes': observacoes ?? '',
      };
      print('POST exercicios-realizados body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(endpointExerciciosRealizados),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'aluno-id': alunoId,
        },
        body: jsonEncode(body),
      );

      print(
        'Resposta exercicios-realizados: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      print('Erro ao registrar exercício: ${response.body}');
      return false;
    } catch (e) {
      print('Erro ao registrar exercício: $e');
      return false;
    }
  }

  // BUSCAR HISTÓRICO PARA GRÁFICOS
  Future<List<ExercicioRealizadoDTO>> buscarProgressao({
    String? exercicioId,
    String? dataInicio,
    String? dataFim,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alunoId = prefs.getString('alunoId') ?? '';
      final token = prefs.getString('token') ?? '';

      if (alunoId.isEmpty || token.isEmpty) return [];

      String url = '$endpointExerciciosRealizados/progressao?alunoId=$alunoId';

      if (exercicioId != null) url += '&exercicioId=$exercicioId';
      if (dataInicio != null) url += '&dataInicio=$dataInicio';
      if (dataFim != null) url += '&dataFim=$dataFim';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((e) => ExercicioRealizadoDTO.fromJson(e)).toList();
      }
      print('Erro ao buscar progressão: ${response.body}');
      return [];
    } catch (e) {
      print('Erro ao buscar progressão: $e');
      return [];
    }
  }

  // BUSCAR ÚLTIMA SESSÃO DE UM GRUPO
  Future<TreinoRealizadoDTO?> buscarUltimaSessao(String grupoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) return null;

      final response = await http.get(
        Uri.parse('$endpointTreinosRealizado/grupo/$grupoId/ultima'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return TreinoRealizadoDTO.fromJson(json);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar última sessão: $e');
      return null;
    }
  }

  // BUSCAR TODAS AS SESSÕES DE UM ALUNO
  Future<List<TreinoRealizadoDTO>> buscarSessoes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alunoId = prefs.getString('alunoId') ?? '';
      final token = prefs.getString('token') ?? '';

      if (alunoId.isEmpty || token.isEmpty) return [];

      final response = await http.get(
        Uri.parse('$endpointTreinosRealizado/aluno/$alunoId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((e) => TreinoRealizadoDTO.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar sessões: $e');
      return [];
    }
  }
}
