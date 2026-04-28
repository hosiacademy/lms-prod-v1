import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'src/core/theme/app_theme.dart';
import 'src/core/services/theme_service.dart';
import 'src/core/services/socket_service.dart' as socketSvc;
import 'src/core/navigation/app_router.dart';
import 'src/core/providers/cart_provider.dart';
import 'src/presentation/widgets/ai/native_ai_assistant.dart';
import 'src/core/services/currency_service.dart';

import 'src/core/api/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Sentry for error tracking and performance monitoring
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://e590241e4409ae1ccb884023ca3aa781@o4511036540190720.ingest.de.sentry.io/4511036759146576';
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
      options.environment = kDebugMode ? 'development' : 'production';
      options.sendDefaultPii = false;
    },
  );

  // Initialize API Client (Auth Interceptors)
  ApiClient.initialize();

  // Initialize Currency Service (detect location and rates)
  await CurrencyService.instance.initialize();

  // Initialize WebView platform for web
  if (kIsWeb) {
    // Initialize web platform for WebView
    // This enables WebView functionality on web
  }

  final themeService = ThemeService();
  await themeService.initialize();

  runApp(MyApp(themeService: themeService));
}

class MyApp extends StatefulWidget {
  final ThemeService themeService;

  const MyApp({super.key, required this.themeService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      const userId = 'user-123';
      socketSvc.socketService.initialize(userId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.themeService),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp.router(
            title: 'Hosi Academy',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            routerConfig: router,
            builder: (context, child) {
              return Stack(
                children: [
                  // Main app content
                  if (child != null)
                    Material(
                      type: MaterialType.transparency,
                      child: child,
                    ),

                  // AI Assistant overlay - web only uses direct header concierge button
                  if (!kIsWeb)
                    NativeAIAssistant(
                      key: NativeAIAssistant.globalKey,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
