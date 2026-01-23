import 'game_item.dart';
import '../data/character_presets.dart';

class Character {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final int level;
  final int currentXp;
  final String title;
  final bool isBarista;
  final double happiness;
  final double success;
  final double love;
  final String location;
  final String activity;
  final bool isPresent;
  final GameItem? activeOrder;
  final DateTime? orderFinishTime;
  final DateTime? lastOrderTime;
  final GameItem? activeActivity;
  final DateTime? activityFinishTime;
  final DateTime? arrivalTime;
  final DateTime? departureTime;

  Character({
    required this.id, required this.name, required this.description, required this.imagePath,
    this.level = 1, this.currentXp = 0, this.title = "Müdavim",
    this.happiness = 0.5, this.success = 0.1, this.love = 0.0,
    this.location = "Dışarıda", this.activity = "Dinleniyor",
    this.isPresent = false, this.isBarista = false,
    this.activeOrder, this.orderFinishTime, this.lastOrderTime,
    this.activeActivity, this.activityFinishTime,
    this.arrivalTime, this.departureTime,
  });

  // XP Mantığı: 100, 250, 450... şeklinde artan zorluk
  int get requiredXpForNextLevel {
    if (level == 1) return 100;
    // Her seviyede gereken XP miktarını kümülatif artırır
    int base = 100;
    for (int i = 1; i < level; i++) {
      base += 150 + (i - 1) * 50;
    }
    return base;
  }

  // UI'daki hataları çözen getter
  int get requiredXp => requiredXpForNextLevel;

  // VERİ KAYDI İÇİN JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id, 'name': name, 'level': level, 'currentXp': currentXp,
      'happiness': happiness, 'success': success, 'love': love,
    };
  }

  // lib/models/character.dart içindeki ilgili kısım

factory Character.fromPreset(CharacterPreset preset, {required String id, bool isPresent = false}) {
  return Character(
    id: id, 
    name: preset.name, 
    description: preset.description,
    title: preset.title, 
    imagePath: preset.imagePath, // Artık preset'ten doğrudan geliyor
    isBarista: preset.title.contains("Barista"), 
    isPresent: isPresent,
    location: isPresent ? (preset.title.contains("Barista") ? "Bar Arkası" : "Masa") : "Ev",
    activity: isPresent ? "Mekanda" : "Uyuyor",
  );
}

  Character copyWith({
    int? level, int? currentXp, double? happiness, double? success,
    double? love, String? location, String? activity, bool? isPresent,
    GameItem? activeOrder, DateTime? orderFinishTime, DateTime? lastOrderTime,
    GameItem? activeActivity, DateTime? activityFinishTime,
    DateTime? arrivalTime, DateTime? departureTime,
    bool? clearOrder, bool? clearActivity,
  }) {
    return Character(
      id: id, name: name, description: description, imagePath: imagePath,
      level: level ?? this.level, currentXp: currentXp ?? this.currentXp,
      happiness: (happiness ?? this.happiness).clamp(0.0, 1.0),
      success: (success ?? this.success).clamp(0.0, 1.0),
      love: (love ?? this.love).clamp(0.0, 1.0),
      location: location ?? this.location, activity: activity ?? this.activity,
      isPresent: isPresent ?? this.isPresent, title: title, isBarista: isBarista,
      activeOrder: (clearOrder == true) ? null : (activeOrder ?? this.activeOrder),
      orderFinishTime: (clearOrder == true) ? null : (orderFinishTime ?? this.orderFinishTime),
      lastOrderTime: lastOrderTime ?? this.lastOrderTime,
      activeActivity: (clearActivity == true) ? null : (activeActivity ?? this.activeActivity),
      activityFinishTime: (clearActivity == true) ? null : (activityFinishTime ?? this.activityFinishTime),
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
    );
  }
}