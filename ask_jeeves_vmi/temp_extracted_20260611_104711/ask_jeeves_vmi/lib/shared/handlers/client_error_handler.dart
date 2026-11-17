import 'package:flutter/material.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import '../services/error_translator_service.dart';

/// Client-side error messages (user-friendly, not backend errors)
/// Enhanced with enterprise error translation
class ClientErrorHandler {
  /// Show user-friendly error snackbar
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: AppTheme.warningRed,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Show warning snackbar
  static Future<void> showWarningDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: AppTheme.warningOrange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Show info snackbar
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: AppTheme.electricCyan,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Show snackbar error
  static void showErrorSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.warningRed,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// Show snackbar warning
  static void showWarningSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.warningOrange,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// Show snackbar success
  static void showSuccessSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// Show snackbar info
  static void showInfoSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.electricCyan,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// Get user-friendly error message from exception
  /// Uses the ErrorTranslatorService for comprehensive error translation
  static String getErrorMessage(dynamic error) {
    final translation = ErrorTranslatorService.translate(error);
    return translation.message;
  }

  /// Get error title from exception
  static String getErrorTitle(dynamic error) {
    final translation = ErrorTranslatorService.translate(error);
    return translation.title;
  }

  /// Show auto-translated error snackbar
  /// Automatically translates technical errors to user-friendly messages
  static Future<void> showAutoErrorDialog(
    BuildContext context, {
    required dynamic error,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) async {
    if (!context.mounted) return;

    final translation = ErrorTranslatorService.translate(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${translation.title}: ${translation.message}'),
        backgroundColor: AppTheme.warningRed,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Try Again',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show auto-translated error snackbar
  /// Automatically translates technical errors to user-friendly messages
  static void showAutoErrorSnackbar(
    BuildContext context, {
    required dynamic error,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onRetry,
  }) {
    if (!context.mounted) return;

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
