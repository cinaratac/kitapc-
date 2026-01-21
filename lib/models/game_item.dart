enum ItemType { 
  // İçecekler
  filterCoffee, latte, espresso, herbalTea, salep, hotChocolate, 
  // Diğer Eşyalar
  laptop, book, generic 
}

// Bir siparişin durumu
enum OrderStatus { pending, preparing, ready }

class GameItem {
  final String id;
  final String name;
  final ItemType type;
  final int xpValue;
  final String? relatedCustomerId; // Bu eşya kime ait? (Sipariş için)
  final OrderStatus? orderStatus;  // Siparişin durumu ne?

  GameItem({
    required this.id,
    required this.name,
    required this.type,
    this.xpValue = 10,
    this.relatedCustomerId,
    this.orderStatus,
  });

  // İkon seçici (Resimlerin yoksa ikon kullanırız)
  String get iconAsset {
    switch (type) {
      case ItemType.filterCoffee: return "☕";
      case ItemType.latte: return "🥛";
      case ItemType.espresso: return "🧉";
      case ItemType.herbalTea: return "🍵";
      case ItemType.salep: return "🥛";
      case ItemType.hotChocolate: return "🍫";
      case ItemType.laptop: return "💻";
      case ItemType.book: return "📖";
      default: return "📦";
    }
  }
}