import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../shared/services/error_translator_service.dart';

class UserFriendlyErrorDialog extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const UserFriendlyErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required dynamic error,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
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

    // Return a completed future for compatibility
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    // This widget is now only used if instantiated directly
    // The static show() method is the preferred way
    return const SizedBox.shrink();
  }
}
