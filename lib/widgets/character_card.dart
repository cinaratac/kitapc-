import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../models/game_item.dart';
import '../providers/game_provider.dart';
import '../screens/character_detail.dart'; // Detay ekranını import etmeyi unutma

class CharacterCard extends ConsumerWidget {
  final Character character;

  const CharacterCard({Key? key, required this.character}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // DragTarget: Üzerine eşya sürüklenebilen alan
    return DragTarget<GameItem>(
      onWillAccept: (item) => true,
      onAccept: (item) {
        ref.read(gameProvider.notifier).giveItem(character.id, item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${character.name} tepki verdi! (+${item.xpValue} XP)"),
            duration: Duration(milliseconds: 500),
            behavior: SnackBarBehavior.floating, // Daha şık görünür
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        // Tıklama özelliği (GestureDetector)
        return GestureDetector(
          onTap: () {
            // Detay sayfasına geçiş
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CharacterDetailScreen(character: character),
              ),
            );
          },
          child: Card(
            elevation: candidateData.isNotEmpty ? 10 : 4,
            // Sürüklenen eşya üzerindeyse kart yeşillensin
            color: candidateData.isNotEmpty ? Colors.green[50] : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Container(
              width: 160, // Genişliği biraz artırdım
              height: 260,
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  // Level Göstergesi
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Lvl ${character.level}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800], fontSize: 12),
                    ),
                  ),
                  
                  SizedBox(height: 10),

                  // RESİM ALANI (Düzeltilen Kısım)
                  Expanded(
                    child: Hero(
                      tag: character.id, // Animasyon için id
                      child: character.imagePath.isNotEmpty 
                        ? Image.asset(
                            character.imagePath,
                            fit: BoxFit.contain, // Resmi kutuya sığdır
                          )
                        : Icon(Icons.person, size: 50, color: Colors.grey), // Resim yoksa ikon göster
                    ),
                  ),

                  SizedBox(height: 10),

                  // İsim ve Unvan
                  Text(
                    character.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    character.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                  
                  SizedBox(height: 8),
                  
                  // XP Barı
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: character.currentXp / character.requiredXp,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}