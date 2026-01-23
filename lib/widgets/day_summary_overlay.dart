import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

class DaySummaryOverlay extends ConsumerWidget {
  const DaySummaryOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    return Container(
      color: Colors.black.withOpacity(0.85), // Arka planı karart
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.brown[50],
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.brown, width: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wb_twilight, size: 60, color: Colors.brown),
              const SizedBox(height: 20),
              Text(
                "${gameState.dayCount}. Gün Bitti",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 10),
              const Text("Dükkan kapandı, herkes evine döndü."),
              const Divider(height: 40, color: Colors.brown),
              
              // Günlük Kazanç Özeti
              _buildSummaryRow("Bugünkü Ciro:", "${gameState.dailyRevenue} TL", Colors.green),
              _buildSummaryRow("Toplam Kasa:", "${gameState.totalBalance} TL", Colors.blueGrey),
              
              const SizedBox(height: 30),
              
              // Sonraki Güne Geç Butonu
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(gameProvider.notifier).startNextDay();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    "BİR SONRAKİ GÜNE GEÇ",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}