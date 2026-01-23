import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../providers/game_provider.dart';

class CharacterDetailScreen extends ConsumerWidget {
  final Character character;

  const CharacterDetailScreen({Key? key, required this.character}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Diğer karakterlerin bilgilerine (resim vb.) erişmek için listeyi alıyoruz
    final allCharacters = ref.watch(gameProvider).characters;

    // Bağ kurulan kişileri en yüksek puandan en düşüğe doğru sıralıyoruz
    final sortedRelations = character.relationships.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text(character.name),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Üst Bölüm: Karakter Resmi ve Temel Bilgiler
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.brown[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Hero(
                    tag: character.id,
                    child: character.imagePath.isNotEmpty
                        ? Image.asset(character.imagePath, height: 200)
                        : const Icon(Icons.person, size: 100, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    character.name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown),
                  ),
                  Text(
                    character.title,
                    style: TextStyle(fontSize: 18, color: Colors.brown[300], fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HAKKINDA BÖLÜMÜ ---
                  const Text(
                    "Hakkında",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.brown[100]!),
                    ),
                    child: Text(
                      character.description,
                      style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- KARAKTER DURUMU (İstatistikler) ---
                  const Text(
                    "Karakter Durumu",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow("Mutluluk", character.happiness, Colors.orange),
                  _buildStatRow("Başarı", character.success, Colors.blue),
                  _buildStatRow("Sevgi", character.love, Colors.red),
                  
                  const SizedBox(height: 24),
                  
                  // Seviye ve XP Bilgisi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Seviye ${character.level}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("${character.currentXp} / ${character.requiredXp} XP"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (character.currentXp / character.requiredXp).clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),

                  // --- ARKADAŞLAR & BAĞLAR BÖLÜMÜ ---
                  const Row(
                    children: [
                      Icon(Icons.people, color: Colors.pink),
                      SizedBox(width: 8),
                      Text(
                        "Arkadaşlar & Bağlar",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (sortedRelations.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Henüz kimseyle bağ kurmamış...",
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedRelations.length,
                      itemBuilder: (context, index) {
                        final relEntry = sortedRelations[index];
                        // Arkadaşın ID'sinden tüm bilgilerini buluyoruz
                        final friend = allCharacters.firstWhere((c) => c.id == relEntry.key);
                        final int bondPercent = (relEntry.value * 100).toInt();

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.pink[50]!),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.brown[50],
                              backgroundImage: friend.imagePath.isNotEmpty ? AssetImage(friend.imagePath) : null,
                              child: friend.imagePath.isEmpty ? const Icon(Icons.person) : null,
                            ),
                            title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(friend.title, style: const TextStyle(fontSize: 10)),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: relEntry.value,
                                  backgroundColor: Colors.pink[50],
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.pink[300]!),
                                  minHeight: 4,
                                ),
                              ],
                            ),
                            trailing: Text(
                              "%$bondPercent",
                              style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // İstatistik çubuklarını oluşturan yardımcı metot
  Widget _buildStatRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text("%${(value * 100).toInt()}", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}