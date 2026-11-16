import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi;

/// Tombol resmi "Continue with Google" (Google Identity Services).
/// Hanya dikompilasi untuk web — lihat conditional import di AuthPage.
Widget buildGoogleWebButton({double? minimumWidth}) {
  return gsi.renderButton(
    configuration: gsi.GSIButtonConfiguration(
      type: gsi.GSIButtonType.standard,
      theme: gsi.GSIButtonTheme.outline,
      size: gsi.GSIButtonSize.large,
      text: gsi.GSIButtonText.continueWith,
      shape: gsi.GSIButtonShape.pill,
      logoAlignment: gsi.GSIButtonLogoAlignment.center,
      minimumWidth: minimumWidth,
    ),
  );
}
