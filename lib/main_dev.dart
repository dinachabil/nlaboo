import 'package:flutter/material.dart';
import 'package:nlaabo/config/build_config.dart';
import 'package:nlaabo/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import '../app_router.dart' show router;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print build configuration for debugging
  BuildConfig.printConfig();

  // Initialize app with development configuration
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const FootConnectApp(),
    ),
  );
}

class FootConnectApp extends StatelessWidget {
  const FootConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: BuildConfig.appName,
      debugShowCheckedModeBanner: BuildConfig.isDevelopment,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: context.watch<ThemeProvider>().themeMode,
      routerConfig: router,
    );
  }
}
