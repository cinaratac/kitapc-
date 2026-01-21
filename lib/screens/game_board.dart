import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../widgets/character_card.dart';
import '../widgets/item_card.dart'; // Bunu unutma
import '../models/game_item.dart';

class GameBoard extends ConsumerWidget {
  
  // GÜNCELLENMİŞ EŞYA LİSTESİ (Hatasız)
  final List<GameItem> availableItems = [
    GameItem(
      id: 'source_coffee', 
      name: "Filtre Kahve", 
      type: ItemType.filterCoffee, // 'coffee' yerine 'filterCoffee'
      xpValue: 15
      // iconPath ARTIK YOK (Otomatik geliyor)
    ),
    GameItem(
      id: 'source_latte',
      name: "Latte",
      type: ItemType.latte,
      xpValue: 20
    ),
    GameItem(
      id: 'source_tea',
      name: "Bitki Çayı",
      type: ItemType.herbalTea,
      xpValue: 10
    ),
    GameItem(
      id: 'source_laptop', 
      name: "Laptop", 
      type: ItemType.laptop, 
      xpValue: 30
    ),
    GameItem(
      id: 'source_book', 
      name: "Kitap", 
      type: ItemType.book, 
      xpValue: 10
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    // Saat Formatı
    String hour = gameState.gameTime.hour.toString().padLeft(2, '0');
    String minute = gameState.gameTime.minute.toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: SafeArea(
        child: Column(
          children: [
            // 1. ÜST BİLGİ PANELİ
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
                  Text(
                    "$hour:$minute",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.brown[900]),
                  ),
                ],
              ),
            ),

            // 2. KARAKTERLER VE MÜŞTERİLER (Yatay Liste)
            Expanded(
              flex: 4,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: 10),
                      // Tüm karakterleri listele (Eren, Çınar ve Müşteriler)
                      ...gameState.characters.map((char) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 15.0),
                          child: CharacterCard(character: char),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),

            Divider(height: 1, thickness: 2, color: Colors.brown[200]),

            // 3. EŞYA KUTUSU (Senin Kontrol Panelin)
            Expanded(
              flex: 1,
              // DragTarget ekliyoruz ki buraya baloncuk bırakabilelim
              child: DragTarget<GameItem>(
                onAccept: (item) {
                  // Eşyayı envantere kaydet (Provider fonksiyonunu çağır)
                  ref.read(gameProvider.notifier).addToInventory(item);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eşya depoya kaldırıldı!"), duration: Duration(milliseconds: 500)));
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    height: 120,
                    // Üzerine bir şey sürükleniyorsa rengi değişsin
                    color: candidateData.isNotEmpty ? Colors.orange[100] : Colors.brown[100],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10, top: 5),
                          child: Text("Menü & Depo (Sürükle Bırak)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
                        ),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.all(10),
                            // LİSTE BİRLEŞTİRME: Sabit Eşyalar + Envanterdeki Eşyalar
                            itemCount: availableItems.length + gameState.inventory.length,
                            itemBuilder: (context, index) {
                              // Eğer index sabit eşya sayısından küçükse -> Sabit Eşyayı Göster
                              if (index < availableItems.length) {
                                return ItemCard(item: availableItems[index]);
                              } 
                              // Değilse -> Envanterdeki (Depodaki) Eşyayı Göster
                              else {
                                int inventoryIndex = index - availableItems.length;
                                return ItemCard(item: gameState.inventory[inventoryIndex]);
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