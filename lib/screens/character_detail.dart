// lib/screens/character_detail.dart
import 'package:flutter/material.dart';
import '../models/character.dart';

class CharacterDetailScreen extends StatelessWidget {
  final Character character;

  const CharacterDetailScreen({Key? key, required this.character}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(title: Text(character.name)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Büyük Karakter Resmi
            Center(
              child: Hero( // Hero animasyonu geçişi havalı yapar
                tag: character.id,
                child: Container(
                  height: 200,
                  child: Image.asset(character.imagePath, fit: BoxFit.contain), // Resim sığdırma sorunu için
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(character.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
            Text("Level ${character.level}", style: TextStyle(fontSize: 16, color: Colors.grey)),
            
            Divider(height: 40, thickness: 2),
            
            // İstatistik Barları
            _buildStatBar("Mutluluk", character.happiness, Colors.orange),
            _buildStatBar("Başarı", character.success, Colors.blue),
            _buildStatBar("Aşk / Sevgi", character.love, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
              Text("%${(value * 100).toInt()}"),
            ],
          ),
          SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 15,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}