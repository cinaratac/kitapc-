import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../widgets/character_card.dart';
import '../widgets/item_card.dart';
import '../models/game_item.dart';

class GameBoard extends ConsumerWidget {
  // Test için sabit eşyalar
  final List<GameItem> availableItems = [
    GameItem(name: "Kahve", type: ItemType.coffee, xpValue: 20, iconPath: ""),
    GameItem(name: "Kod", type: ItemType.laptop, xpValue: 50, iconPath: ""),
    GameItem(name: "Kitap", type: ItemType.book, xpValue: 30, iconPath: ""),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider'dan karakter listesini dinle
    final characters = ref.watch(gameProvider);

    return Scaffold(
      backgroundColor: Colors.brown[50], // Kafe rengi
      appBar: AppBar(title: Text("Kitapçı Kafe Simülasyonu")),
      body: Column(
        children: [
          // ÜST KISIM: KARAKTERLER
          Expanded(
            flex: 3,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: characters.map((char) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CharacterCard(character: char),
                  )).toList(),
                ),
              ),
            ),
          ),
          
          Divider(thickness: 2),

          // ALT KISIM: EŞYALAR (SÜRÜKLENECEK OLANLAR)
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: availableItems.length,
                itemBuilder: (context, index) {
                  return ItemCard(item: availableItems[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}