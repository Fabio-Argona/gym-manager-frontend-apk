import 'package:intl/intl.dart';

class DateUtils {
  // Para exibir datas ISO (ex: 1999-09-09T00:00:00)
  static String formatarParaExibicao(String isoDate) {
    final data = DateTime.parse(isoDate);
    return DateFormat('dd-MM-yyyy').format(data);
  }

  // Para enviar datas digitadas pelo usuário (ex: 09/09/1999)
  static String formatarParaEnvio(String dataDigitada) {
    final partes = dataDigitada.split('/');
    if (partes.length != 3) return '';
    return '${partes[0]}-${partes[1]}-${partes[2]}';
  }
}