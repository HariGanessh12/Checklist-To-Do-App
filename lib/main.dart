import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'pages/home_page.dart';
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
    return MaterialApp(
      title: 'Material Tasks',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}
