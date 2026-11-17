import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../shared/services/error_translator_service.dart';

class UserFriendlyErrorSnackbar {
  /// Shows a user-friendly error snackbar
  static void show({
    required BuildContext context,
    required dynamic error,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onRetry,
  }) {
    final translation = ErrorTranslatorService.translate(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${translation.title}: ${translation.message}'),
        backgroundColor: AppTheme.warningRed,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}
