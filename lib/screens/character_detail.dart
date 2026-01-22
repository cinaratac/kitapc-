import 'package:flutter/material.dart';
import '../models/character.dart';

class CharacterDetailScreen extends StatelessWidget {
  final Character character;

  const CharacterDetailScreen({Key? key, required this.character}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  // --- YENİ EKLENEN: AÇIKLAMA BÖLÜMÜ ---
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
                      character.description, // Modeldeki açıklama burada gösterilir
                      style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // İstatistikler Başlığı
                  const Text(
                    "Karakter Durumu",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown),
                  ),
                  const SizedBox(height: 16),

                  // İstatistik Kartları
                  _buildStatRow("Mutluluk", character.happiness, Colors.orange),
                  _buildStatRow("Başarı", character.success, Colors.blue),
                  _buildStatRow("Sevgi", character.love, Colors.red),
                  
                  const SizedBox(height: 24),
                  
                  // Level ve XP Bilgisi
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