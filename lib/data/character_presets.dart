import '../models/game_item.dart';

class CharacterPreset {
  final String name;
  final String description;
  final String title;
  final Map<ItemType, String> activityTexts; 
  final Map<ItemType, Map<String, double>> multipliers;

  CharacterPreset({
    required this.name,
    required this.description,
    required this.title,
    required this.activityTexts,
    required this.multipliers,
  });
}

// 50 karakterlik listenin başlangıcı
final List<CharacterPreset> allPresets = [
  CharacterPreset(
    name: "Çınar",
    description: "Duygular göstermek için varlar. Asla hiç bir şeyi saklamam",
    title: "Klasik Çınar",
    activityTexts: {
      ItemType.laptop: "Karanlık temada kod yazıyor... 💻",
      ItemType.book: "Felsefe kitabı okuyup uzaklara dalıyor... 📖",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.25, 'happiness': -0.05, 'xp': 80},
      ItemType.book: {'happiness': 0.03, 'xp': 20},
    },
  ),
  CharacterPreset(
    name: "Eren",
    description: "Üzgün olmadığıma dair kendimi kandırmıyorum. Sadece şımarık değilim",
    title: "Müzisyen Barista",
    activityTexts: {
      ItemType.laptop: "Gizlice Openfront oynuyor! 🎮",
      ItemType.book: "Kahve ansiklopedisi karıştırıyor. ☕",
    },
    multipliers: {
      ItemType.laptop: {'happiness': 0.4, 'success': -0.1, 'xp': 10},
      ItemType.book: {'success': 0.15, 'xp': 50},
    },
  ),
  CharacterPreset(
    name: "Dilay",
    description: "Gülüyorum ama galiba biraz yalnız hissediyorum",
    title: "Ressam",
    activityTexts: {
      ItemType.laptop: "Blog yazısı hazırlıyor... ✍️",
      ItemType.book: "Aşk romanına gömülmüş durumda... 💖",
    },
    multipliers: {
      ItemType.laptop: {'success': 0.1, 'xp': 40},
      ItemType.book: {'happiness': 0.15, 'love': 0.05, 'xp': 70},
    },
  ),
  // ... Geri kalan 47 karakter bu yapıya göre eklenebilir.
];