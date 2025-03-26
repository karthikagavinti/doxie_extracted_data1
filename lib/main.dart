import 'package:doxie_dummy_pdf/services/api_service.dart';
import 'package:doxie_dummy_pdf/theme/app_theme.dart';
import 'package:flutter/material.dart';

import 'services/websocket_service.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Configure your API base URL here
    final apiBaseUrl = 'http://10.0.2.2:3001';
    final apiService = ApiService(baseUrl: apiBaseUrl);
    final websocketService = WebSocketService(baseUrl: apiBaseUrl);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PDF Viewer',
      theme: AppTheme.themeData,
      home: WelcomeScreen(
        apiService: apiService,
        websocketService: websocketService,
      ),
    );
  }
}
