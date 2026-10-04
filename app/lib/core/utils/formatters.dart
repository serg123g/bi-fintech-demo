/// Formateo de dinero y tiempo relativo sin dependencias (es-EC, USD).
abstract final class Formatters {
  /// 123456 -> "$1,234.56"; -4530 -> "-$45.30".
  static String money(int cents, {String currency = 'USD'}) {
    final negative = cents < 0;
    final abs = cents.abs();
    final units = (abs ~/ 100).toString();
    final decimals = (abs % 100).toString().padLeft(2, '0');
    final grouped = units.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final symbol = currency == 'USD' ? r'$' : '$currency ';
    return '${negative ? '-' : ''}$symbol$grouped.$decimals';
  }

  static String timeAgo(DateTime then, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(then);
    if (diff.inSeconds < 60) return 'hace un momento';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    final days = diff.inDays;
    return days == 1 ? 'hace 1 día' : 'hace $days días';
  }

  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// "4 oct, 14:05"
  static String shortDateTime(DateTime d) {
    final l = d.toLocal();
    final hh = l.hour.toString().padLeft(2, '0');
    final mm = l.minute.toString().padLeft(2, '0');
    return '${l.day} ${_months[l.month - 1]}, $hh:$mm';
  }
}
