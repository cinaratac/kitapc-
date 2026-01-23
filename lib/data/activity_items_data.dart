// lib/data/activity_items_data.dart
import '../models/game_item.dart';

class ActivityItem {
  final ItemType type;
  final String name;
  final String icon;
  final int price;
  final int durationMinutes;
  final String defaultActivityText; // Karakterin özel tepkisi yoksa kullanılacak yazı
  final bool isInitialUnlocked;    // Oyun başında açık mı? (Kitap/Laptop gibi)

  ActivityItem({
    required this.type,
    required this.name,
    required this.icon,
    required this.price,
    required this.durationMinutes,
    required this.defaultActivityText,
    this.isInitialUnlocked = false,
  });
}

// Satın alınabilir tüm aktivite eşyalarının listesi
final List<ActivityItem> allActivityItems = [
  ActivityItem(
    type: ItemType.book,
    name: "Kitap",
    icon: "📖",
    price: 0,
    durationMinutes: 30,
    defaultActivityText: "Kitap okuyor...",
    isInitialUnlocked: true,
  ),
  ActivityItem(
    type: ItemType.laptop,
    name: "Laptop",
    icon: "💻",
    price: 0,
    durationMinutes: 60,
    defaultActivityText: "Bilgisayarda çalışıyor...",
    isInitialUnlocked: true,
  ),
  ActivityItem(
    type: ItemType.guitar,
    name: "Gitar",
    icon: "🎸",
    price: 1000,
    durationMinutes: 45,
    defaultActivityText: "Gitar tellerine dokunuyor... 🎶",
  ),
  ActivityItem(
    type: ItemType.paintingKit,
    name: "Resim Seti",
    icon: "🎨",
    price: 600,
    durationMinutes: 50,
    defaultActivityText: "Resim yapıyor... 🖌️",
  ),
  ActivityItem(
    type: ItemType.boardGame,
    name: "Masa Oyunu",
    icon: "🎲",
    price: 350,
    durationMinutes: 40,
    defaultActivityText: "Oyun oynuyor... ♟️",
  ),
];