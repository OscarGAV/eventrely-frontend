import 'package:flutter/material.dart';
import 'themes/app_theme.dart';

/// Utilidades para UI consistente en toda la app
class UIHelpers {
  // Espaciado vertical
  static const SizedBox verticalSpaceTiny = SizedBox(height: 4);
  static const SizedBox verticalSpaceSmall = SizedBox(height: 8);
  static const SizedBox verticalSpaceMedium = SizedBox(height: 16);
  static const SizedBox verticalSpaceLarge = SizedBox(height: 24);
  static const SizedBox verticalSpaceExtraLarge = SizedBox(height: 32);
  static const SizedBox verticalSpaceMassive = SizedBox(height: 48);
  
  // Espaciado horizontal
  static const SizedBox horizontalSpaceTiny = SizedBox(width: 4);
  static const SizedBox horizontalSpaceSmall = SizedBox(width: 8);
  static const SizedBox horizontalSpaceMedium = SizedBox(width: 16);
  static const SizedBox horizontalSpaceLarge = SizedBox(width: 24);
  
  // Padding
  static const EdgeInsets paddingAll = EdgeInsets.all(16);
  static const EdgeInsets paddingAllLarge = EdgeInsets.all(24);
  static const EdgeInsets paddingHorizontal = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets paddingVertical = EdgeInsets.symmetric(vertical: 16);
  
  // Border Radius
  static BorderRadius borderRadiusSmall = BorderRadius.circular(8);
  static BorderRadius borderRadiusMedium = BorderRadius.circular(12);
  static BorderRadius borderRadiusLarge = BorderRadius.circular(16);
  static BorderRadius borderRadiusExtraLarge = BorderRadius.circular(24);
  
  /// Muestra un SnackBar con estilo moderno
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color backgroundColor;
    IconData icon;
    
    if (isError) {
      backgroundColor = AppTheme.errorColor;
      icon = Icons.error_outline_rounded;
    } else if (isSuccess) {
      backgroundColor = AppTheme.successColor;
      icon = Icons.check_circle_outline_rounded;
    } else {
      backgroundColor = AppTheme.infoColor;
      icon = Icons.info_outline_rounded;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            horizontalSpaceMedium,
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
        elevation: 8,
      ),
    );
  }
  
  /// Widget de loading moderno
  static Widget buildLoadingIndicator({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [AppTheme.cardShadow],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            verticalSpaceMedium,
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Widget de error moderno
  static Widget buildErrorWidget({
    required String message,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: paddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppTheme.errorColor,
              ),
            ),
            verticalSpaceLarge,
            Text(
              'Oops!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            verticalSpaceSmall,
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              verticalSpaceLarge,
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Widget de estado vacío moderno
  static Widget buildEmptyState({
    required String title,
    required String message,
    IconData? icon,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Center(
      child: Padding(
        padding: paddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.calendar_today_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            verticalSpaceLarge,
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            verticalSpaceSmall,
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              verticalSpaceLarge,
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Crea un gradiente de fondo para pantallas
  static BoxDecoration get screenBackgroundDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppTheme.backgroundColor,
        AppTheme.backgroundColor.withBlue(40),
      ],
    ),
  );
}