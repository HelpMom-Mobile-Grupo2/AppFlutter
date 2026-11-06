import 'package:intl/intl.dart';

/// "hace 5 min", "hace 2 h" o la fecha y hora si pasó más de un día.
/// Compara instantes con difference, nunca el texto (D.11).
String timeAgo(DateTime date, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(date);
  if (diff.inMinutes < 1) return 'hace un momento';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  return formatDateTime(date);
}

/// Fecha y hora en la zona del teléfono, por ejemplo "3 nov, 20:10".
/// Necesita initializeDateFormatting('es') (se llama en main.dart).
String formatDateTime(DateTime date) =>
    DateFormat('d MMM, HH:mm', 'es').format(date.toLocal());
