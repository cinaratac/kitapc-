import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text("Dükkan Kayıtları & Zaman"),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- KASA / TOPLAM BAKİYE KARTI ---
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown[800]!, Colors.brown[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.orangeAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "TOPLAM KASA BAKİYESİ",
                      style: TextStyle(
                        color: Colors.white70, 
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        letterSpacing: 1.5
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "${gameState.totalBalance} TL",
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 42, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Güvenli Birikim",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),

          // --- GÜNLÜK İSTATİSTİKLER ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                // İşletme Günü
                Expanded(
                  child: _buildInfoTile(
                    "İşletme Günü", 
                    "${gameState.dayCount}. Gün", 
                    Icons.calendar_today, 
                    Colors.blueGrey
                  ),
                ),
                const SizedBox(width: 12),
                // Günlük Ciro
                Expanded(
                  child: _buildInfoTile(
                    "Bugünkü Ciro", 
                    "${gameState.dailyRevenue} TL", 
                    Icons.trending_up, 
                    Colors.green
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 32, indent: 24, endIndent: 24),

          // --- TAKVİM GÖRÜNÜMÜ ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.brown),
                SizedBox(width: 8),
                Text(
                  "OYUN TAKVİMİ",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 14),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.brown[100]!),
              ),
              child: CalendarDatePicker(
                initialDate: gameState.gameTime,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
                onDateChanged: (date) {}, // Sadece izleme amaçlı
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bilgi kutucukları için yardımcı metot
  Widget _buildInfoTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.brown[50]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[900])),
        ],
      ),
    );
  }
}