enum ItemType { 
  filterCoffee, latte, espresso, herbalTea, 
  laptop, book, 
  guitar, paintingKit, boardGame 
}

enum OrderStatus { 
  pending,    // Sarı (İstiyor)
  processing, // Mavi (Sipariş verildi, bekliyor)
  preparing,  // Gri (Barista hazırlıyor)
  ready       // Yeşil (Hazır)
}

class GameItem {
  final String id;
  final String name;
  final ItemType type;
  final int xpValue;
  final String? relatedCustomerId;
  final int price;
  final OrderStatus? orderStatus;

  GameItem({
    required this.id,
    required this.name,
    required this.type,
    this.xpValue = 10,
    this.relatedCustomerId,
    this.orderStatus,
    this.price = 0,
  });

  // Hata Çözümü: copyWith metodu eklendi
  GameItem copyWith({
    String? id,
    String? name,
    ItemType? type,
    int? xpValue,
    String? relatedCustomerId,
    OrderStatus? orderStatus,
  }) {
    return GameItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      xpValue: xpValue ?? this.xpValue,
      relatedCustomerId: relatedCustomerId ?? this.relatedCustomerId,
      orderStatus: orderStatus ?? this.orderStatus,
    );
  }

  String get iconAsset {
    switch (type) {
      case ItemType.filterCoffee: return "☕";
      case ItemType.latte: return "🥛";
      case ItemType.espresso: return "🧉";
      case ItemType.herbalTea: return "🍵";
      case ItemType.laptop: return "💻";
      case ItemType.book: return "📖";
      case ItemType.guitar: return "🎸";
      case ItemType.paintingKit: return "🎨";
      case ItemType.boardGame: return "🎲";
    // ... diğerleri
      default: return "📦";
    }
  }
}