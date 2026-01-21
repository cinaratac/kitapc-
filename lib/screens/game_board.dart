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
  // Sayfa kontrolcüsü (Kaydırma için lazım)
  final PageController _pageController = PageController();

  final List<GameItem> sourceItems = [
    // İçecekleri buradan SİLDİK. Sadece aktivite eşyaları kaldı.
    GameItem(id: 'src_laptop', name: "Laptop", type: ItemType.laptop, xpValue: 30),
    GameItem(id: 'src_book', name: "Kitap", type: ItemType.book, xpValue: 10),
    // İleride buraya "Sohbet", "Müzik" gibi şeyler ekleyebilirsin.
  ];

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    String hour = gameState.gameTime.hour.toString().padLeft(2, '0');
    String minute = gameState.gameTime.minute.toString().padLeft(2, '0');

    // Karakterleri 4'erli gruplara bölüyoruz (Sayfalamak için)
    List<List<Character>> characterPages = [];
    for (int i = 0; i < gameState.characters.length; i += 4) {
      characterPages.add(
        gameState.characters.sublist(
          i, 
          (i + 4) > gameState.characters.length ? gameState.characters.length : i + 4
        )
      );
    }
    // Eğer hiç karakter yoksa boş bir sayfa olsun hata vermesin
    if (characterPages.isEmpty) characterPages.add([]);

    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: SafeArea(
        child: Column(
          children: [
            // --- ÜST PANEL ---
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

            // --- ORTA ALAN: SAYFALAMA VE SÜRÜKLEME SENSÖRLERİ ---
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  // 1. ANA KARAKTER SAYFALARI (PageView)
                  PageView.builder(
                    controller: _pageController,
                    itemCount: characterPages.length,
                    itemBuilder: (context, pageIndex) {
                      List<Character> pageChars = characterPages[pageIndex];
                      
                      // 2x2 IZGARA YAPISI
                      return GridView.builder(
                        padding: EdgeInsets.all(10),
                        physics: NeverScrollableScrollPhysics(), // Sayfa içinde scroll olmasın
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Yan yana 2 tane
                          childAspectRatio: 0.65, // Kartların boy/en oranı (Dikdörtgen olsun)
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

                  // 2. SOL KENAR SENSÖRÜ (Geri Gitmek İçin)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 40, // Sol tarafta 40px'lik görünmez bir alan
                    child: DragTarget<GameItem>(
                      onWillAccept: (data) {
                        // Üzerine gelince ÖNCEKİ SAYFAYA git
                        _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                        return false; // Eşyayı yutma, sadece kaydır
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          color: candidateData.isNotEmpty ? Colors.black12 : Colors.transparent, // Test için hafif gri yapabilirsin
                          child: candidateData.isNotEmpty ? Center(child: Icon(Icons.arrow_back_ios, color: Colors.white)) : null,
                        );
                      },
                    ),
                  ),

                  // 3. SAĞ KENAR SENSÖRÜ (İleri Gitmek İçin)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 40, // Sağ tarafta 40px'lik alan
                    child: DragTarget<GameItem>(
                      onWillAccept: (data) {
                        // Üzerine gelince SONRAKİ SAYFAYA git
                        _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                        return false;
                      },
                      builder: (context, candidateData, rejectedData) {
                         return Container(
                          color: candidateData.isNotEmpty ? Colors.black12 : Colors.transparent,
                          child: candidateData.isNotEmpty ? Center(child: Icon(Icons.arrow_forward_ios, color: Colors.white)) : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, thickness: 2, color: Colors.brown[200]),

            // --- ALT KUTU (DEPO) ---
            Expanded(
              flex: 1,
              child: DragTarget<GameItem>(
                onAccept: (item) {
                  ref.read(gameProvider.notifier).addToInventory(item);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Depoya kaldırıldı!"), duration: Duration(milliseconds: 500)));
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    color: candidateData.isNotEmpty ? Colors.orange[100] : Colors.brown[100],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text("Menü & Depo (Eşyaları buraya bırakabilirsin)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
                        ),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.all(10),
                            itemCount: sourceItems.length + gameState.inventory.length,
                            itemBuilder: (context, index) {
                              if (index < sourceItems.length) {
                                return ItemCard(item: sourceItems[index]);
                              } else {
                                return ItemCard(item: gameState.inventory[index - sourceItems.length]);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}