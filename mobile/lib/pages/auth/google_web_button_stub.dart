import 'package:flutter/widgets.dart';

/// Pengganti tombol Google web untuk platform non-web (Android/iOS), supaya
/// kode khusus web tidak ikut dikompilasi di sana.
Widget buildGoogleWebButton({double? minimumWidth}) {
  return const SizedBox.shrink();
}
