// lib/widgets/item_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_item.dart';
import '../data/activity_items_data.dart';
import '../providers/game_provider.dart';

class ItemCard extends ConsumerWidget {
  final GameItem item;
  final bool isLocked;

  const ItemCard({Key? key, required this.item, this.isLocked = false}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLocked) {
      // EŞYA KİLİTLİ: Sürüklenemez, tıklandığında satın alma ekranı açılır
      return GestureDetector(
        onTap: () => _showPurchaseDialog(context, ref),
        child: _buildItemBox(isLocked: true),
      );
    }

    // EŞYA AÇIK: Draggable (Sürüklenebilir)
    return Draggable<GameItem>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: _buildItemBox(isFeedback: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildItemBox(),
      ),
      child: _buildItemBox(),
    );
  }

  void _showPurchaseDialog(BuildContext context, WidgetRef ref) {
    final activityData = allActivityItems.firstWhere((a) => a.type == item.type);
    final balance = ref.read(gameProvider).totalBalance;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${activityData.name} Satın Al"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(activityData.icon, style: const TextStyle(fontSize: 50)),
            const SizedBox(height: 10),
            Text("Fiyat: ${activityData.price} TL"),
            Text("Bakiye: $balance TL", style: TextStyle(color: balance >= activityData.price ? Colors.green : Colors.red)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            onPressed: balance >= activityData.price 
              ? () {
                  ref.read(gameProvider.notifier).unlockItem(activityData);
                  Navigator.pop(context);
                }
              : null,
            child: const Text("Satın Al"),
          ),
        ],
      ),
    );
  }

  Widget _buildItemBox({bool isLocked = false, bool isFeedback = false}) {
    final activityData = allActivityItems.firstWhere((a) => a.type == item.type, 
      orElse: () => ActivityItem(type: item.type, name: item.name, icon: "📦", price: 0, durationMinutes: 30, defaultActivityText: ""));

    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      decoration: BoxDecoration(
        color: isLocked ? Colors.grey[300] : Colors.amber[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLocked ? Colors.grey : Colors.brown, width: 2),
        boxShadow: isFeedback ? [] : [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(activityData.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(item.name, style: TextStyle(fontSize: 10, fontWeight: isLocked ? FontWeight.normal : FontWeight.bold)),
            ],
          ),
          if (isLocked)
            Container(
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Icon(Icons.lock, color: Colors.white, size: 24)),
            ),
        ],
      ),
    );
  }
}