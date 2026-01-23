import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/activity_items_data.dart';
import '../providers/game_provider.dart';

class ActivityShopDialog extends ConsumerWidget {
  const ActivityShopDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Eşya Mağazası",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown),
              ),
              // Mevcut bakiyeyi göster
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(20)),
                child: Text("💰 ${gameState.totalBalance} TL", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          // Eşya Listesi
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allActivityItems.length,
              itemBuilder: (context, index) {
                final item = allActivityItems[index];
                final isUnlocked = gameState.unlockedActivityItems.contains(item.type);
                final canAfford = gameState.totalBalance >= item.price;

                return Card(
                  elevation: 0,
                  color: isUnlocked ? Colors.green[50] : Colors.grey[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Text(item.icon, style: const TextStyle(fontSize: 30)),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(isUnlocked ? "Sahipsin" : "${item.price} TL"),
                    trailing: isUnlocked
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                            onPressed: canAfford ? () => gameNotifier.unlockItem(item) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Satın Al"),
                          ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}