import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop_models.dart';
import '../models/game_item.dart';
import '../providers/game_provider.dart';

class SeatWidget extends ConsumerWidget {
  final SeatSlot slot;

  const SeatWidget({Key? key, required this.slot}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOccupied = slot.customer != null;
    final wantsOrder = isOccupied && slot.customer!.state == ActivityState.ordering;

    return DragTarget<GameItem>(
      onWillAccept: (data) => isOccupied && wantsOrder, // Sadece sipariş bekleyen koltuğa bırakılabilir
      onAccept: (item) {
        // Merkezi provider üzerinden siparişi tamamla
        ref.read(gameProvider.notifier).fulfillGenericOrder(slot.id, item);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${slot.locationName}: ${item.name} teslim edildi! 💰"),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.brown,
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty 
                ? Colors.green[100] // Üzerine ürün getirilince parlar
                : (isOccupied ? Colors.brown[100] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: candidateData.isNotEmpty ? Colors.green : Colors.brown.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: candidateData.isNotEmpty 
                ? [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 8)] 
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(slot.locationName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown)),
              const SizedBox(height: 4),
              if (isOccupied) ...[
                const Icon(Icons.person, size: 24, color: Colors.brown),
                Text(slot.customer!.name, style: const TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis),
                
                // Durum Göstergesi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: wantsOrder ? Colors.red[400] : Colors.blue[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    wantsOrder ? "İstiyor: ${slot.customer!.lookingFor}" : "Tüketiyor...",
                    style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else
                const Text("Boş", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}