// lib/widgets/seat_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop_models.dart';
import '../models/game_item.dart';
import '../providers/shop_provider.dart';

class SeatWidget extends ConsumerWidget {
  final SeatSlot slot;

  const SeatWidget({Key? key, required this.slot}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<GameItem>(
      onAccept: (item) {
        // Siparişi teslim etme logiği buraya
        // ref.read(shopProvider.notifier).fulfillOrder(slot.id, item.name);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sipariş verildi!")));
      },
      builder: (context, candidateData, rejectedData) {
        bool isOccupied = slot.customer != null;
        bool wantsOrder = isOccupied && slot.customer!.state == ActivityState.ordering;

        return Container(
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isOccupied ? Colors.brown[200] : Colors.grey[300], // Dolu/Boş rengi
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.brown, width: 1),
            boxShadow: candidateData.isNotEmpty ? [BoxShadow(color: Colors.green, blurRadius: 5)] : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Koltuk Numarası
              Text(slot.locationName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              
              if (isOccupied) ...[
                Icon(Icons.person, size: 20),
                Text(slot.customer!.name, style: TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis),
                
                // Müşteri Ne Yapıyor?
                Text(
                  wantsOrder ? "Wait: ${slot.customer!.lookingFor}" : "Ders...", // Durum
                  style: TextStyle(fontSize: 9, color: wantsOrder ? Colors.red : Colors.blue),
                ),
                
                // İstek Bildirimi (Baloncuk)
                if (wantsOrder)
                  Icon(Icons.notification_important, color: Colors.red, size: 14),
              ] else
                 Text("Boş", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}