import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/date_utils.dart' as meu_date_utils;

import 'package:local_auth/local_auth.dart';

class AuthService extends ChangeNotifier {
  final String baseUrl = 'http://localhost:8080';
  final LocalAuthentication _localAuth = LocalAuthentication();

  // LOGIN
  Future<bool> login(String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
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
        Uri.parse('$baseUrl/auth/register'),
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

  // ATUALIZAR NOME
  Future<bool> atualizarNome(String novoNome, String alunoId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/alunos/$alunoId/nome'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'nome': novoNome}),
    );

    if (response.statusCode == 200) {
      await prefs.setString('nome', novoNome);
      return true;
    }

    return false;
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
      Uri.parse('$baseUrl/alunos/$alunoId'),
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

  // ATUALIZAR DADOS FÍSICOS
  Future<bool> atualizarFisico({
    required String alunoId,
    required String sexo,
    required String peso,
    required String altura,
    required String gordura,
    required String musculo,
    required String imc,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/alunos/$alunoId/fisico'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'sexo': sexo,
        'pesoAtual': double.tryParse(peso),
        'altura': double.tryParse(altura),
        'percentualGordura': double.tryParse(gordura),
        'percentualMusculo': double.tryParse(musculo),
        'imc': double.tryParse(imc),
      }),
    );

    return response.statusCode == 200;
  }

  // ATUALIZAR MEDIDAS CORPORAIS
  Future<bool> atualizarMedidas({
    required String alunoId,
    required String cintura,
    required String quadril,
    required String peito,
    required String ombro,
    required String bracoDireito,
    required String bracoEsquerdo,
    required String coxaDireita,
    required String coxaEsquerda,
    required String panturrilhaDireita,
    required String panturrilhaEsquerda,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/alunos/$alunoId/medidas'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'cintura': double.tryParse(cintura),
        'quadril': double.tryParse(quadril),
        'peito': double.tryParse(peito),
        'ombro': double.tryParse(ombro),
        'bracoDireito': double.tryParse(bracoDireito),
        'bracoEsquerdo': double.tryParse(bracoEsquerdo),
        'coxaDireita': double.tryParse(coxaDireita),
        'coxaEsquerda': double.tryParse(coxaEsquerda),
        'panturrilhaDireita': double.tryParse(panturrilhaDireita),
        'panturrilhaEsquerda': double.tryParse(panturrilhaEsquerda),
      }),
    );

    return response.statusCode == 200;
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
      Uri.parse('$baseUrl/alunos/$alunoId/objetivo'),
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

  // RECUPERAÇÃO DE SENHA
  Future<bool> requestPasswordReset(String email, {String? cpf}) async {
    try {
      print('Enviando solicitação de recuperação para email: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/recuperar-senha'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final erro = _extrairMensagemErro(response);
        throw Exception(erro);
      }
    } catch (e) {
      throw Exception(
        'Erro ao solicitar redefinição: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  // REDEFINIR SENHA COM TOKEN
  Future<bool> resetPassword(String token, String novaSenha) async {
    try {
      print('Redefinindo senha com token: $token');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/resetar-senha'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'novaSenha': novaSenha}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
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

  // AUTENTICAÇÃO BIOMÉTRICA
  Future<bool> authenticateWithBiometrics() async {
    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Por favor, autentique-se para continuar.',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      return authenticated;
    } catch (e) {
      print('Erro na autenticação biométrica: $e');
      return false;
    }
  }
}
