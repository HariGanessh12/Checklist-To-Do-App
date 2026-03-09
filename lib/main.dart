import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'pages/home_page.dart';
import 'pages/sign_in_page.dart';
import 'services/home_screen_widget_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Offline Storage
  await StorageService.init();
  await NotificationService.init();
  await HomeScreenWidgetService.updateWidgets();

  runApp(const MaterialTasksApp());
}

class MaterialTasksApp extends StatelessWidget {
  const MaterialTasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        StorageService.animationsEnabledNotifier,
        StorageService.themeModeNotifier,
        StorageService.authSignedInNotifier,
      ]),
      builder: (context, _) {
        final animationsEnabled =
            StorageService.animationsEnabledNotifier.value;
        final themeMode = StorageService.themeModeNotifier.value;
        final isSignedIn = StorageService.authSignedInNotifier.value;
        return MaterialApp(
          title: 'Material Tasks',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(animationsEnabled: animationsEnabled),
          darkTheme: AppTheme.darkTheme(animationsEnabled: animationsEnabled),
          themeMode: themeMode,
          home: isSignedIn ? const HomePage() : const SignInPage(),
        );
      },
    );
  }
}
