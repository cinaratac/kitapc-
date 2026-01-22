import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../widgets/character_card.dart';
import '../widgets/item_card.dart'; 
import '../models/game_item.dart';
import '../models/character.dart';

class GameBoard extends ConsumerStatefulWidget {
  @override
  ConsumerState<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends ConsumerState<GameBoard> {
  final PageController _pageController = PageController();
  final List<GameItem> menuItems = [
    GameItem(id: 'menu_laptop', name: "Laptop", type: ItemType.laptop),
    GameItem(id: 'menu_book', name: "Kitap", type: ItemType.book),
  ];

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    
    final presentCharacters = gameState.characters.where((c) => c.isPresent).toList();

    List<List<Character>> characterPages = [];
    for (int i = 0; i < presentCharacters.length; i += 4) {
      characterPages.add(presentCharacters.sublist(i, (i + 4) > presentCharacters.length ? presentCharacters.length : i + 4));
    }
    if (characterPages.isEmpty) characterPages.add([]);

    String timeStr = "${gameState.gameTime.hour.toString().padLeft(2, '0')}:${gameState.gameTime.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("KİTAPÇI SİMÜLASYONU", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                      Text(gameState.isShopOpen ? "🟢 AÇIK" : "🔴 KAPALI (Hazırlık: 10:00)", style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                  Text(timeStr, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.brown)),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: characterPages.length,
                    itemBuilder: (context, pageIndex) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, 
                          childAspectRatio: 0.65, 
                          crossAxisSpacing: 10, 
                          mainAxisSpacing: 10,
                        ),
                        itemCount: characterPages[pageIndex].length,
                        itemBuilder: (context, index) => CharacterCard(character: characterPages[pageIndex][index]),
                      );
                    },
                  ),
                  
                  // SOL KENAR: Sürükleme şeridi (Sipariş balonlarını engellememesi için daraltıldı ve ortalandı)
                  Positioned(
                    left: 0, 
                    top: 100,    // Üstteki baloncukları serbest bırakır
                    bottom: 120, // Menü alanını serbest bırakır
                    width: 25,   // Hassas sürükleme alanı
                    child: DragTarget<GameItem>(
                      onWillAccept: (data) {
                        if (_pageController.page! > 0) {
                          _pageController.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                        }
                        return false; 
                      },
                      builder: (context, _, __) => Container(color: Colors.transparent),
                    ),
                  ),

                  // SAĞ KENAR: Sürükleme şeridi (Sipariş balonlarını engellememesi için daraltıldı ve ortalandı)
                  Positioned(
                    right: 0, 
                    top: 100,    // Sağ üstteki sipariş balonlarını kurtarır
                    bottom: 120, 
                    width: 25,   
                    child: DragTarget<GameItem>(
                      onWillAccept: (data) {
                        if (_pageController.page! < characterPages.length - 1) {
                          _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                        }
                        return false;
                      },
                      builder: (context, _, __) => Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 120,
              color: Colors.brown[100],
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: menuItems.length,
                itemBuilder: (context, index) => ItemCard(item: menuItems[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}