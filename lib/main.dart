import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/category_provider.dart';
import 'providers/home_provider.dart';
import 'providers/search_provider.dart';
import 'screens/main_shell.dart';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)
        ..badCertificateCallback = (cert, host, port) => true;
}

void main() {
  HttpOverrides.global = DevHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()..load()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..load()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: MaterialApp(
        title: 'My Store',
        theme: appTheme,
        debugShowCheckedModeBanner: false,
        home: const MainShell(),
      ),
    );
  }
}
