class ExercicioRealizadoDTO {
  final String id;
  final String treinoRealizadoId;
  final String exercicioId;
  final String exercicioNome;
  final int seriesRealizadas;
  final int repeticoesRealizadas;
  final double pesoUtilizado;
  final String? observacoes;
  final String dataSessao;
  final String criadoEm;

  ExercicioRealizadoDTO({
    required this.id,
    required this.treinoRealizadoId,
    required this.exercicioId,
    required this.exercicioNome,
    required this.seriesRealizadas,
    required this.repeticoesRealizadas,
    required this.pesoUtilizado,
    this.observacoes,
    required this.dataSessao,
    required this.criadoEm,
  });

  factory ExercicioRealizadoDTO.fromJson(Map<String, dynamic> json) {
    return ExercicioRealizadoDTO(
      id: json['id']?.toString() ?? '',
      treinoRealizadoId: json['treinoRealizadoId']?.toString() ?? '',
      exercicioId: json['exercicioId']?.toString() ?? '',
      exercicioNome: json['exercicioNome'] ?? '',
      seriesRealizadas: json['seriesRealizadas'] ?? 0,
      repeticoesRealizadas: json['repeticoesRealizadas'] ?? 0,
      pesoUtilizado: (json['pesoUtilizado'] != null)
          ? double.tryParse(json['pesoUtilizado'].toString()) ?? 0.0
          : 0.0,
      observacoes: json['observacoes'],
      dataSessao: json['dataSessao'] ?? '',
      criadoEm: json['criadoEm'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'treinoRealizadoId': treinoRealizadoId,
      'exercicioId': exercicioId,
      'exercicioNome': exercicioNome,
      'seriesRealizadas': seriesRealizadas,
      'repeticoesRealizadas': repeticoesRealizadas,
      'pesoUtilizado': pesoUtilizado,
      'observacoes': observacoes,
      'dataSessao': dataSessao,
      'criadoEm': criadoEm,
    };
  }
}

class TreinoRealizadoDTO {
  final String id;
  final String grupoId;
  final String dataSessao;
  final List<ExercicioRealizadoDTO> exercicios;

  TreinoRealizadoDTO({
    required this.id,
    required this.grupoId,
    required this.dataSessao,
    required this.exercicios,
  });

  factory TreinoRealizadoDTO.fromJson(Map<String, dynamic> json) {
    return TreinoRealizadoDTO(
      id: json['id']?.toString() ?? '',
      grupoId: json['grupoId']?.toString() ?? '',
      dataSessao: json['dataSessao'] ?? '',
      exercicios:
          (json['exercicios'] as List?)
              ?.map((e) => ExercicioRealizadoDTO.fromJson(e))
              .toList() ??
          [],
    );
  }
}
