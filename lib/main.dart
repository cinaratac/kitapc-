import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitapci/screens/main_navigation_screen.dart';
import 'screens/game_board.dart';

void main() {
  runApp(
    // Riverpod'un çalışması için gerekli
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kitapçı Game',
      theme: ThemeData(primarySwatch: Colors.brown),
      home: MainNavigationScreen(),
    );
  }
}