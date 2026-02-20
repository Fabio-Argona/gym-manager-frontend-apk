// lib/constants/constants.dart

// -------------------------------------------------------
// BASE URL — altere SOMENTE aqui para mudar o servidor
// -------------------------------------------------------
const String baseUrl = 'http://34.204.15.179:8080';

// AUTH
const String endpointLogin          = '$baseUrl/auth/login';
const String endpointRegister       = '$baseUrl/auth/register';
const String endpointRecuperarSenha = '$baseUrl/auth/recuperar-senha';
const String endpointResetarSenha   = '$baseUrl/auth/resetar-senha';

// ALUNOS
const String endpointAlunos = '$baseUrl/alunos';

// GRUPOS
const String endpointGrupos = '$baseUrl/grupos';

// EXERCÍCIOS
const String endpointExercicios           = '$baseUrl/exercicios';
const String endpointExerciciosRealizados = '$baseUrl/exercicios-realizados';

// TREINOS REALIZADOS
const String endpointTreinosRealizado = '$baseUrl/treinos/realizado';

// UPLOAD DE IMAGEM
const String endpointUpload  = '$baseUrl/api/upload';
const String endpointUploads = '$baseUrl/api/uploads';
