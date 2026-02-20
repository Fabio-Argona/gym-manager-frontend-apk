import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometriaTestPage extends StatefulWidget {
  const BiometriaTestPage({super.key});

  @override
  State<BiometriaTestPage> createState() => _BiometriaTestPageState();
}

class _BiometriaTestPageState extends State<BiometriaTestPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  String _status = "Clique no botão para testar";

  Future<void> _testarBiometria() async {
    try {
      // Verifica suporte
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final available = await _localAuth.getAvailableBiometrics();

      if (!canCheckBiometrics || !isDeviceSupported || available.isEmpty) {
        setState(() {
          _status = "Dispositivo não suporta biometria ou não há biometria cadastrada.";
        });
        return;
      }

      // Tenta autenticar
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Por favor, autentique-se para continuar.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      setState(() {
        _status = authenticated
            ? "✅ Autenticação biométrica realizada com sucesso!"
            : "❌ Falha na autenticação biométrica.";
      });
    } catch (e) {
      setState(() {
        _status = "Erro: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teste de Biometria")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _testarBiometria,
              icon: const Icon(Icons.fingerprint),
              label: const Text("Testar biometria"),
            ),
          ],
        ),
      ),
    );
  }
}
