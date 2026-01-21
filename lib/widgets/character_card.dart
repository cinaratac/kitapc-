import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../models/game_item.dart';
import '../providers/game_provider.dart';
import '../screens/character_detail.dart';

class CharacterCard extends ConsumerWidget {
  final Character character;

  const CharacterCard({Key? key, required this.character}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double opacity = character.isPresent ? 1.0 : 0.4;

    return DragTarget<GameItem>(
      onWillAccept: (incomingItem) {
        if (!character.isPresent || incomingItem == null) return false;

        // 1. BARISTA: Sadece "Sarı" (Pending) siparişleri alır
        if (character.isBarista) {
          // Barista zaten doluysa alma
          if (character.activeOrder != null) return false;
          return incomingItem.orderStatus == OrderStatus.pending;
        }

        // 2. MÜŞTERİ: Sadece "Kendi Siparişi" ve "Hazırsa (Yeşil)" alır
        if (!character.isBarista && incomingItem.relatedCustomerId == character.id) {
          return incomingItem.orderStatus == OrderStatus.ready;
        }

        // 3. GENEL EŞYALAR
        if (incomingItem.type == ItemType.laptop || incomingItem.type == ItemType.book) {
          return true;
        }

        return false;
      },
      onAccept: (item) {
        ref.read(gameProvider.notifier).giveItemToCharacter(character.id, item);
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CharacterDetailScreen(character: character)));
              },
              child: Opacity(
                opacity: opacity,
                child: Card(
                  elevation: candidateData.isNotEmpty ? 10 : 6,
                  color: candidateData.isNotEmpty ? Colors.green[100] : (rejectedData.isNotEmpty ? Colors.red[50] : Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    width: 160,
                    height: 270,
                    padding: EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Konum
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50], borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Text(character.location, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue[900]), overflow: TextOverflow.ellipsis),
                        ),
                        // Resim
                        Expanded(
                          child: Hero(
                            tag: character.id,
                            child: character.imagePath.isNotEmpty
                                ? Image.asset(character.imagePath, fit: BoxFit.contain)
                                : Icon(Icons.person, size: 60, color: Colors.grey[400]),
                          ),
                        ),
                        // İsim & Aktivite
                        Column(
                          children: [
                            Text(character.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(character.activity, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.orange[800], fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        SizedBox(height: 5),
                        // Level Bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Lvl ${character.level}", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                            SizedBox(height: 2),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (character.currentXp / character.requiredXp).clamp(0.0, 1.0),
                                backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(Colors.orange), minHeight: 6,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // SİPARİŞ BALONCUĞU
            if (character.activeOrder != null && character.isPresent)
              Positioned(
                right: -5, top: -5,
                child: Draggable<GameItem>(
                  data: character.activeOrder,
                  feedback: _buildBubble(character.activeOrder!, isDragging: true),
                  childWhenDragging: Container(), // Sürüklerken orijinal kaybolsun
                  child: _buildBubble(character.activeOrder!),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBubble(GameItem item, {bool isDragging = false}) {
    Color color = Colors.white;
    // RENK AYARLARI BURADA
    if (item.orderStatus == OrderStatus.pending) color = Colors.yellow[100]!;    // Sarı
    if (item.orderStatus == OrderStatus.processing) color = Colors.blue[100]!;   // MAVİ (Bekliyor)
    if (item.orderStatus == OrderStatus.preparing) color = Colors.grey[300]!;    // Gri
    if (item.orderStatus == OrderStatus.ready) color = Colors.green[100]!;       // Yeşil

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color, shape: BoxShape.circle,
          boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
          border: Border.all(color: Colors.brown, width: 1),
        ),
        child: Text(item.iconAsset, style: TextStyle(fontSize: isDragging ? 32 : 22)),
      ),
    );
  }
}