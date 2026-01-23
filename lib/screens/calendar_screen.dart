import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Zaman Tüneli"), backgroundColor: Colors.brown),
      body: Column(
        children: [
          // Gün Sayacı Kartı
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.brown,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text("Şu an dükkandaki", style: TextStyle(color: Colors.white70)),
                Text("${gameState.dayCount}. GÜN", 
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                const Icon(Icons.auto_awesome, color: Colors.orange),
              ],
            ),
          ),
          // Takvim Görünümü
          Expanded(
            child: CalendarDatePicker(
              initialDate: gameState.gameTime,
              firstDate: DateTime(2025),
              lastDate: DateTime(2030),
              onDateChanged: (date) {}, // Sadece görüntüleme amaçlı
            ),
          ),
        ],
      ),
    );
  }
}