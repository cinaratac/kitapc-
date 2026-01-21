import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../models/game_item.dart';
import '../providers/game_provider.dart';
import '../screens/character_detail.dart'; // Dosya adın farklıysa düzelt

class CharacterCard extends ConsumerWidget {
  final Character character;

  const CharacterCard({Key? key, required this.character}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Karakter dükkanda değilse soluk gözüksün
    double opacity = character.isPresent ? 1.0 : 0.4;

    return DragTarget<GameItem>(
      onWillAccept: (item) => character.isPresent, // Sadece dükkandaysa eşya kabul et
      onAccept: (item) {
        ref.read(gameProvider.notifier).giveItemToCharacter(character.id, item);
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // --- TIKLANABİLİR KART ALANI ---
            GestureDetector(
              onTap: () {
                // TIKLAMA BURADA ÇALIŞACAK
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CharacterDetailScreen(character: character),
                  ),
                );
              },
              child: Opacity(
                opacity: opacity,
                child: Card(
                  elevation: candidateData.isNotEmpty ? 10 : 4,
                  // Üzerine eşya gelince yeşil yanar
                  color: candidateData.isNotEmpty ? Colors.green[50] : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    width: 160,
                    height: 270,
                    padding: EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Konum Rozeti
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Text(
                            character.location,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Karakter Resmi
                        Expanded(
                          child: Hero(
                            tag: character.id,
                            child: character.imagePath.isNotEmpty
                                ? Image.asset(character.imagePath, fit: BoxFit.contain)
                                : Icon(Icons.person, size: 60, color: Colors.grey),
                          ),
                        ),
            
                        // İsim ve Durum
                        Column(
                          children: [
                            Text(character.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(
                              character.activity,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.orange[800], fontStyle: FontStyle.italic),
                              maxLines: 1,
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 6),
            
                        // --- LEVEL VE XP BARI (GERİ GELDİ) ---
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Lvl ${character.level}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                Text("${character.currentXp}/${character.requiredXp} XP", style: TextStyle(fontSize: 9, color: Colors.grey)),
                              ],
                            ),
                            SizedBox(height: 2),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (character.currentXp / character.requiredXp).clamp(0.0, 1.0),
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                minHeight: 6,
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

            // --- SİPARİŞ BALONCUĞU (Sağ Üst) ---
            if (character.activeOrder != null && character.isPresent)
              Positioned(
                right: -5,
                top: -5,
                child: Draggable<GameItem>(
                  data: character.activeOrder,
                  feedback: _buildBubble(character.activeOrder!, isDragging: true),
                  childWhenDragging: Container(),
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
    if (item.orderStatus == OrderStatus.pending) color = Colors.yellow[100]!;
    if (item.orderStatus == OrderStatus.preparing) color = Colors.grey[300]!;
    if (item.orderStatus == OrderStatus.ready) color = Colors.green[100]!;

    return Material( // Feedback modunda text'in altı çizili olmasın diye Material
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
          border: Border.all(color: Colors.brown, width: 1),
        ),
        child: Text(
          item.iconAsset,
          style: TextStyle(fontSize: isDragging ? 30 : 20),
        ),
      ),
    );
  }
}