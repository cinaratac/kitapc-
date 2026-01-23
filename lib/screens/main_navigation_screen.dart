import 'package:flutter/material.dart';
import 'game_board.dart';
import 'character_list_screen.dart'; // Yeni oluşturacağız
import 'calendar_screen.dart';       // Yeni oluşturacağız

class MainNavigationScreen extends StatefulWidget {
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    GameBoard(),           // Oyun alanı
    const CharacterListScreen(), // Karakterler sayfası
    const CalendarScreen(),      // Takvim sayfası
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Dükkan'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Müdavimler'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Takvim'),
        ],
      ),
    );
  }
}