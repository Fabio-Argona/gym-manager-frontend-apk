import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/date_utils.dart' as meu_date_utils;
import '../constants/constants.dart';

import 'package:local_auth/local_auth.dart';

class AuthService extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // LOGIN
  Future<bool> login(String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse(endpointLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': senha}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('Resposta completa do login: ${response.body}');

        final prefs = await SharedPreferences.getInstance();

        final token = data['token']?.toString();
        final aluno = data['aluno'];
        final nome = aluno?['nome']?.toString();
        final id = aluno?['id']?.toString();

        print('Nome salvo no login: $nome');

        if (token != null && nome != null && id != null) {
          await prefs.setString('token', token);
          await prefs.setString('nome', nome);
          await prefs.setString('alunoId', id);
          return true;
        }
      } else {
        final erro = _extrairMensagemErro(response);
        throw Exception(erro);
      }
    } catch (e) {
      throw Exception(
        'Erro ao autenticar: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }

    return false;
  }

  // REGISTRO
  Future<bool> register(Map<String, dynamic> dados) async {
    try {
      // 🔧 Formatar data de nascimento se estiver presente
      if (dados.containsKey('data_nascimento')) {
        final original = dados['data_nascimento']?.toString() ?? '';
        dados['data_nascimento'] = meu_date_utils.DateUtils.formatarParaEnvio(
          original,
        );
      }

      print('Dados enviados no register: ${jsonEncode(dados)}');

      final response = await http.post(
        Uri.parse(endpointRegister),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dados),
      );

      print('Resposta do backend: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', body['token']);
        await prefs.setString('nome', body['aluno']['nome']);
        await prefs.setString('alunoId', body['aluno']['id']);
        return true;
      } else {
        final erro = _extrairMensagemErro(response);
        throw Exception(erro);
      }
    } catch (e) {
      throw Exception(
        'Erro ao cadastrar: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  // ATUALIZAR PERFIL COMPLETO
  Future<bool> atualizarPerfil({
    required String alunoId,
    required String nome,
    required String telefone,
    required String data_nascimento,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final dataFormatada = meu_date_utils.DateUtils.formatarParaEnvio(
      data_nascimento,
    );
    print('Data formatada para envio: $dataFormatada');

    final response = await http.put(
      Uri.parse('$endpointAlunos/$alunoId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': nome,
        'telefone': telefone,
        'data_nascimento': dataFormatada,
      }),
    );

    if (response.statusCode == 200) {
      await prefs.setString('nome', nome);
      return true;
    }

    return false;
  }

  // ATUALIZAR DADOS FÍSICOS ESTÁTICOS (sexo e altura)
  Future<bool> atualizarFisico({
    required String alunoId,
    required String sexo,
    required String altura,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$endpointAlunos/$alunoId/fisico'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'sexo': sexo, 'altura': double.tryParse(altura)}),
    );

    return response.statusCode == 200;
  }

  // SALVAR / ATUALIZAR AVALIAÇÃO FÍSICA COMPLETA (evolucoes)
  Future<bool> salvarMedidas({
    required String alunoId,
    String? evolucaoId,
    required String peso,
    required String altura,
    required String gordura,
    required String musculo,
    required String cintura,
    required String abdomen,
    required String quadril,
    required String peito,
    required String bracoDireito,
    required String bracoEsquerdo,
    required String coxaDireita,
    required String coxaEsquerda,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final body = jsonEncode({
      'alunoId': alunoId,
      'peso': double.tryParse(peso),
      'altura': double.tryParse(altura),
      'percentualGordura': double.tryParse(gordura),
      'percentualMusculo': double.tryParse(musculo),
      'cintura': double.tryParse(cintura),
      'abdomen': double.tryParse(abdomen),
      'quadril': double.tryParse(quadril),
      'peito': double.tryParse(peito),
      'bracoDireito': double.tryParse(bracoDireito),
      'bracoEsquerdo': double.tryParse(bracoEsquerdo),
      'coxaDireita': double.tryParse(coxaDireita),
      'coxaEsquerda': double.tryParse(coxaEsquerda),
    });

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final http.Response response;
    if (evolucaoId != null && evolucaoId.isNotEmpty) {
      response = await http.put(
        Uri.parse('$baseUrl/evolucoes/$evolucaoId'),
        headers: headers,
        body: body,
      );
    } else {
      response = await http.post(
        Uri.parse('$baseUrl/evolucoes'),
        headers: headers,
        body: body,
      );
    }

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // ATUALIZAR OBJETIVO
  Future<bool> atualizarObjetivo({
    required String alunoId,
    required String objetivo,
    required String nivel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$endpointAlunos/$alunoId/objetivo'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'objetivo': objetivo, 'nivelTreinamento': nivel}),
    );

    return response.statusCode == 200;
  }

  // RECUPERAR NOME SALVO
  Future<String?> getNomeSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nome');
  }

  // LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // MÉTODO AUXILIAR PARA ERROS
  String _extrairMensagemErro(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is String) return body;
      if (body is Map && body.containsKey('message')) return body['message'];
      return response.body;
    } catch (_) {
      return response.body.isNotEmpty ? response.body : 'Erro desconhecido';
    }
  }

  // RECUPERAÇÃO DE SENHA — valida email + 6 primeiros dígitos do CPF + redefine
  Future<bool> resetPassword(
    String email,
    String cpf6,
    String novaSenha,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(endpointResetarSenha),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'cpf6': cpf6.replaceAll(RegExp(r'[^0-9]'), ''),
          'novaSenha': novaSenha,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final erro = _extrairMensagemErro(response);
        throw Exception(erro);
      }
    } catch (e) {
      throw Exception(
        'Erro ao redefinir senha: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  // VERIFICA SE BIOMETRIA ESTÁ DISPONÍVEL NA PLATAFORMA
  Future<bool> isBiometricsAvailable() async {
    try {
      if (const bool.fromEnvironment(
        'dart.library.js_util',
        defaultValue: false,
      )) {
        return false; // web
      }
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;
      final List<BiometricType> available = await _localAuth
          .getAvailableBiometrics();
      return available.isNotEmpty;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  // AUTENTICAÇÃO BIOMÉTRICA
  Future<bool> authenticateWithBiometrics() async {
    try {
      // Verifica se a plataforma suporta biometria
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isSupported = await _localAuth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        print('Biometria não suportada neste dispositivo/plataforma.');
        return false;
      }

      final List<BiometricType> available = await _localAuth
          .getAvailableBiometrics();
      if (available.isEmpty) {
        print('Nenhuma biometria cadastrada no dispositivo.');
        return false;
      }

      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Por favor, autentique-se para continuar.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      return authenticated;
    } on MissingPluginException {
      print('Biometria não disponível nesta plataforma (plugin ausente).');
      return false;
    } on PlatformException catch (e) {
      print('Erro de plataforma na biometria: ${e.message}');
      return false;
    } catch (e) {
      print('Erro na autenticação biométrica: $e');
      return false;
    }
  }
}
