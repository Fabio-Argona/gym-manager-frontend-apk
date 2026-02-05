class AlunoDTO {
  final String id;
  final String nome;
  final String cpf;
  final String email;
  final String telefone;
  final String login;
  final String sexo;
  final double pesoAtual;
  final double altura;
  final double percentualGordura;
  final double percentualMusculo;
  final double imc;
  final String objetivo;
  final String nivelTreinamento;
  final String dataNascimento;

  AlunoDTO({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.email,
    required this.telefone,
    required this.login,
    required this.sexo,
    required this.pesoAtual,
    required this.altura,
    required this.percentualGordura,
    required this.percentualMusculo,
    required this.imc,
    required this.objetivo,
    required this.nivelTreinamento,
    required this.dataNascimento,
  });

  factory AlunoDTO.fromJson(Map<String, dynamic> json) {
    return AlunoDTO(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] ?? '',
      cpf: json['cpf'] ?? '',
      email: json['email'] ?? '',
      telefone: json['telefone'] ?? '',
      login: json['login'] ?? '',
      sexo: json['sexo'] ?? '',
      pesoAtual: (json['pesoAtual'] != null)
          ? double.tryParse(json['pesoAtual'].toString()) ?? 0
          : 0,
      altura: (json['altura'] != null)
          ? double.tryParse(json['altura'].toString()) ?? 0
          : 0,
      percentualGordura: (json['percentualGordura'] != null)
          ? double.tryParse(json['percentualGordura'].toString()) ?? 0
          : 0,
      percentualMusculo: (json['percentualMusculo'] != null)
          ? double.tryParse(json['percentualMusculo'].toString()) ?? 0
          : 0,
      imc: (json['imc'] != null)
          ? double.tryParse(json['imc'].toString()) ?? 0
          : 0,
      objetivo: json['objetivo'] ?? '',
      nivelTreinamento: json['nivelTreinamento'] ?? '',
      dataNascimento: json['data_nascimento'] ?? '',
    );
  }
}
