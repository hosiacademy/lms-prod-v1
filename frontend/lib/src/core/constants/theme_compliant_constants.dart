// lib/src/core/constants/theme_compliant_constants.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Import the theme extension from your app_theme.dart
import '../../core/theme/app_theme.dart';

// ENVIRONMENT FIX: Import environment configuration
import '../config/environment.dart';
import '../extensions/context_extensions.dart';

/// Theme-compliant spacing using WordPress design tokens
class ThemeSpacing {
  static EdgeInsets all(BuildContext context, String size) {
    return EdgeInsets.all(context.wpSpacingValue(size));
  }

  static EdgeInsets symmetric(BuildContext context,
      {String horizontal = 'md', String vertical = 'md'}) {
    return EdgeInsets.symmetric(
      horizontal: context.wpSpacingValue(horizontal),
      vertical: context.wpSpacingValue(vertical),
    );
  }

  static EdgeInsets fromLTRB(BuildContext context, String left, String top,
      String right, String bottom) {
    return EdgeInsets.fromLTRB(
      context.wpSpacingValue(left),
      context.wpSpacingValue(top),
      context.wpSpacingValue(right),
      context.wpSpacingValue(bottom),
    );
  }
}

/// Theme-compliant widget builders
class ThemeWidgets {
  /// Create a card with theme-compliant styling
  static Card card({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    double? elevation,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      color: backgroundColor ?? colors.surface,
      elevation: elevation ?? 2,
      shape: RoundedRectangleBorder(
        borderRadius: context.wpBorderRadius,
        side: BorderSide(
          color: colors.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: context.wpBorderRadius,
        child: Padding(
          padding: padding ?? ThemeSpacing.all(context, 'md'),
          child: child,
        ),
      ),
    );
  }

  /// Create a button with theme-compliant styling
  static Widget primaryButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isFullWidth = false,
    String? size, // 'sm', 'md', 'lg'
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final padding = switch (size) {
      'sm' => ThemeSpacing.symmetric(context, horizontal: 'sm', vertical: 'xs'),
      'lg' => ThemeSpacing.symmetric(context, horizontal: 'xl', vertical: 'md'),
      _ => ThemeSpacing.symmetric(context, horizontal: 'lg', vertical: 'sm'),
    };

    final textStyle = switch (size) {
      'sm' => theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.onPrimary,
        ),
      'lg' => theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.onPrimary,
        ),
      _ => theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.onPrimary,
        ),
    };

    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: context.wpBorderRadius,
        ),
        padding: padding,
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: size == 'sm' ? 16 : 20, color: colors.onPrimary),
                SizedBox(width: context.wpSpacingValue('sm')),
                Text(label, style: textStyle),
              ],
            )
          : Text(label, style: textStyle),
    );

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  /// Create a secondary button with theme-compliant styling
  static Widget secondaryButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isFullWidth = false,
    String? size,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final padding = switch (size) {
      'sm' => ThemeSpacing.symmetric(context, horizontal: 'sm', vertical: 'xs'),
      'lg' => ThemeSpacing.symmetric(context, horizontal: 'xl', vertical: 'md'),
      _ => ThemeSpacing.symmetric(context, horizontal: 'lg', vertical: 'sm'),
    };

    final textStyle = switch (size) {
      'sm' => theme.textTheme.labelMedium?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
      'lg' => theme.textTheme.titleMedium?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
      _ => theme.textTheme.labelLarge?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
    };

    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: context.wpBorderRadius,
        ),
        padding: padding,
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: size == 'sm' ? 16 : 20, color: colors.primary),
                SizedBox(width: context.wpSpacingValue('sm')),
                Text(
                  label,
                  style: textStyle,
                ),
              ],
            )
          : Text(
              label,
              style: textStyle,
            ),
    );

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  /// Create a chip with theme-compliant styling
  static Chip chip({
    required BuildContext context,
    required String label,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    VoidCallback? onDeleted,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Chip(
      label: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: textColor ?? colors.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      avatar: icon != null
          ? Icon(icon, size: 16, color: textColor ?? colors.onSurface)
          : null,
      backgroundColor: backgroundColor ?? colors.surfaceContainerHighest,
      deleteIcon: onDeleted != null
          ? Icon(Icons.close, size: 16, color: colors.onSurface)
          : null,
      onDeleted: onDeleted,
      shape: RoundedRectangleBorder(
        borderRadius: context.wpBorderRadius,
        side: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
      ),
    );
  }

  /// Create a loading indicator with theme-compliant styling
  static Widget loadingIndicator({
    required BuildContext context,
    String? label,
    bool isCircular = true,
    double size = 40,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (isCircular) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                color: colors.primary,
                strokeWidth: 3,
              ),
            ),
            if (label != null) ...[
              SizedBox(height: context.wpSpacingValue('sm')),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              color: colors.primary,
              backgroundColor: colors.surfaceContainerHighest,
            ),
            if (label != null) ...[
              SizedBox(height: context.wpSpacingValue('sm')),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ],
          ],
        ),
      );
    }
  }
}

/// Theme-compliant typography helpers
class ThemeTypography {
  static TextStyle displayLarge(BuildContext context) {
    return Theme.of(context).textTheme.displayLarge!;
  }

  static TextStyle headlineMedium(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium!;
  }

  static TextStyle titleLarge(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!;
  }

  static TextStyle bodyLarge(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!;
  }

  static TextStyle bodyMedium(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!;
  }

  static TextStyle labelLarge(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!;
  }

  static TextStyle labelSmall(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.labelSmall!.copyWith(
      letterSpacing: 1.2,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );
  }

  /// Get text style with specific color
  static TextStyle withColor(BuildContext context, Color color) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium!.copyWith(color: color);
  }

  /// Get text style for success messages
  static TextStyle success(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.tertiary, // Assuming tertiary is success/green
      fontWeight: FontWeight.w500,
    );
  }

  /// Get text style for error messages
  static TextStyle error(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.error,
      fontWeight: FontWeight.w500,
    );
  }
}

/// Socket.io constants with theme awareness
/// ENVIRONMENT FIX: Migrated to use Environment configuration
class SocketConstants {
  // DEPRECATED: Use Environment.socketUrl instead
  @Deprecated('Use Environment.socketUrl instead')
  static String get serverUrl => _getPlatformUrl();

  // Platform-specific URL handling for development
  static String _getPlatformUrl() {
    // In production, use Environment config
    if (const bool.fromEnvironment('dart.vm.product')) {
      return Environment.socketUrl;
    }

    // Development: Handle platform-specific localhost
    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    }

    return 'http://localhost:8000';
  }

  // DEPRECATED: Use Environment.socketUrl instead
  @Deprecated('Use Environment.socketUrl instead')
  static String get productionServerUrl => Environment.socketUrl;

  // Use Environment configuration for all socket URLs
  static String get currentServerUrl => Environment.socketUrl;

  static const String namespace = '/learning';
  static const String chatNamespace = '/chat';

  // Reconnection settings optimized for mobile
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectInterval = Duration(seconds: 3);
  static const Duration pingTimeout = Duration(seconds: 10);
  static const Duration pingInterval = Duration(seconds: 25);

  // Event names
  static const String connectEvent = 'connect';
  static const String disconnectEvent = 'disconnect';
  static const String errorEvent = 'error';
  static const String connectErrorEvent = 'connect_error';
  static const String reconnectEvent = 'reconnect';
  static const String reconnectAttemptEvent = 'reconnect_attempt';
  static const String reconnectErrorEvent = 'reconnect_error';
  static const String reconnectFailedEvent = 'reconnect_failed';

  // Custom events
  static const String joinUserEvent = 'join_user';
  static const String userJoined = 'user_joined';
  static const String userLeft = 'user_left';
  static const String updatePresenceEvent = 'update_presence';
  static const String userPresenceEvent = 'user_presence';
  static const String typingEvent = 'typing';
  static const String typingIndicatorEvent = 'typing_indicator';
  static const String sendMessageEvent = 'send_message';
  static const String newMessageEvent = 'new_message';
  static const String messageSentEvent = 'message_sent';
  static const String messageUpdated = 'message_updated';
  static const String messageDeleted = 'message_deleted';
  static const String userOnlineEvent = 'user_online';
  static const String userOfflineEvent = 'user_offline';
  static const String roomCreated = 'room_created';
  static const String roomUpdated = 'room_updated';
  static const String roomDeleted = 'room_deleted';
  static const String userJoinedRoom = 'user_joined_room';
  static const String userLeftRoom = 'user_left_room';

  // Emit events
  static const String joinUser = 'join_user';
  static const String updatePresence = 'update_presence';
  static const String sendMessage = 'send_message';
  static const String markAsRead = 'mark_as_read';
  static const String deleteMessage = 'delete_message';
  static const String editMessage = 'edit_message';
  static const String joinRoom = 'join_room';
  static const String leaveRoom = 'leave_room';
  static const String typing = 'typing';
}

/// BigBlueButton constants
class BBBConstants {
  // Development BigBlueButton
  static String get serverUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    } else if (Platform.isIOS) {
      return 'http://localhost:8080';
    }

    return 'http://localhost:8080';
  }

  // Production URL
  static String get productionServerUrl {
    return 'https://bbb.hosi.academy';
  }

  // Use development or production based on build type
  static String get currentServerUrl {
    return const bool.fromEnvironment('dart.vm.product')
        ? productionServerUrl
        : serverUrl;
  }

  static const String apiSecret = 'your_bbb_secret_key_here';

  // API endpoints
  static const String createMeeting = '/bigbluebutton/api/create';
  static const String joinMeeting = '/bigbluebutton/api/join';
  static const String endMeeting = '/bigbluebutton/api/end';
  static const String getMeetingInfo = '/bigbluebutton/api/getMeetingInfo';
  static const String getRecordings = '/bigbluebutton/api/getRecordings';

  // Default settings
  static const String defaultWelcome = 'Welcome to Hosi Academy Live Session';
  static const Duration defaultDuration = Duration(hours: 2);
  static const int maxParticipants = 250;

  // Recording settings
  static const bool autoStartRecording = true;
  static const bool allowStartStopRecording = true;
}

/// API constants with environment awareness
class ApiConstants {
  static String get baseUrl {
    return const bool.fromEnvironment('dart.vm.product')
        ? 'https://api.hosi.academy'
        : 'http://localhost:8000';
  }

  static const String apiVersion = '/api/v1';

  // Authentication endpoints
  static const String login = '/auth/login/';
  static const String register = '/auth/register/';
  static const String logout = '/auth/logout/';
  static const String refreshToken = '/auth/refresh/';

  // User endpoints
  static const String userProfile = '/users/profile/';
  static const String updateProfile = '/users/update/';

  // Course endpoints
  static const String courses = '/courses/';
  static const String enroll = '/courses/enroll/';
  static const String progress = '/courses/progress/';

  // Socket.io authentication
  static const String socketAuth = '/socket/auth/';
}

/// App-specific constants
class AppConstants {
  // App version
  static const String version = '1.0.0';
  static const String buildNumber = '1';

  // App name
  static const String appName = 'Hosi Academy';

  // Storage keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String themeModeKey = 'theme_mode';

  // Cache duration
  static const Duration cacheDuration = Duration(minutes: 5);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
}
