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

  // SABİT MENÜ EŞYALARI (Bunlar asla tükenmez)
  final List<GameItem> menuItems = [
    GameItem(id: 'menu_laptop', name: "Laptop", type: ItemType.laptop, xpValue: 30),
    GameItem(id: 'menu_book', name: "Kitap", type: ItemType.book, xpValue: 10),
  ];

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    String hour = gameState.gameTime.hour.toString().padLeft(2, '0');
    String minute = gameState.gameTime.minute.toString().padLeft(2, '0');

    List<List<Character>> characterPages = [];
    for (int i = 0; i < gameState.characters.length; i += 4) {
      characterPages.add(
        gameState.characters.sublist(
          i, 
          (i + 4) > gameState.characters.length ? gameState.characters.length : i + 4
        )
      );
    }
    if (characterPages.isEmpty) characterPages.add([]);

    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: SafeArea(
        child: Column(
          children: [
            // ÜST PANEL
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("KİTAPÇI SİMÜLASYONU", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                      Text(
                        gameState.isShopOpen ? "🟢 AÇIK" : "🔴 KAPALI (11:00'de açılır)",
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  Text("$hour:$minute", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.brown[900])),
                ],
              ),
            ),

            // ORTA ALAN
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: characterPages.length,
                    itemBuilder: (context, pageIndex) {
                      List<Character> pageChars = characterPages[pageIndex];
                      return GridView.builder(
                        padding: EdgeInsets.all(10),
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: pageChars.length,
                        itemBuilder: (context, index) {
                          return CharacterCard(character: pageChars[index]);
                        },
                      );
                    },
                  ),
                  Positioned(left: 0, top: 0, bottom: 0, width: 40,
                    child: DragTarget<GameItem>(
                      onWillAccept: (_) { _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut); return false; },
                      builder: (c, cand, rej) => Container(color: cand.isNotEmpty ? Colors.black12 : Colors.transparent, child: cand.isNotEmpty ? Icon(Icons.arrow_back_ios, color: Colors.white) : null),
                    ),
                  ),
                  Positioned(right: 0, top: 0, bottom: 0, width: 40,
                    child: DragTarget<GameItem>(
                      onWillAccept: (_) { _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut); return false; },
                      builder: (c, cand, rej) => Container(color: cand.isNotEmpty ? Colors.black12 : Colors.transparent, child: cand.isNotEmpty ? Icon(Icons.arrow_forward_ios, color: Colors.white) : null),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, thickness: 2, color: Colors.brown[200]),

            // --- ALT ALAN (SADECE MENÜ) ---
            // Burası artık DragTarget DEĞİL. Sadece bir Listedir.
            // Bu sayede buraya bir şey bırakamazsın (Kopyalama bug'ı imkansız hale gelir).
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.brown[100],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text("Eylemler (Sınırsız Kullanım)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.all(10),
                        itemCount: menuItems.length,
                        itemBuilder: (context, index) {
                          // Bu kartlar sürüklenebilir ama menüden eksilmez
                          return ItemCard(item: menuItems[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}