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

  // Level atlamak için gereken toplam XP (100, 250, 450...)
  int get requiredXpForNextLevel {
    if (level == 1) return 100;
    return 100 + (level - 1) * 150; // İstediğin 100, 250... mantığı
  }

  // UI'daki hataları gidermek için requiredXp getter'ı
  int get requiredXp => requiredXpForNextLevel;

  Character({
    required this.id, required this.name, required this.description, required this.imagePath,
    this.level = 1, this.currentXp = 0, this.title = "Müdavim",
    this.happiness = 0.5, this.success = 0.1, this.love = 0.0,
    this.location = "Dışarıda", this.activity = "Gelmeyi Bekliyor",
    this.isPresent = false, this.isBarista = false,
    this.activeOrder, this.orderFinishTime, this.lastOrderTime,
    this.activeActivity, this.activityFinishTime,
    this.arrivalTime, this.departureTime,
  });

  // VERİ KAYDI İÇİN: Karakteri JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'currentXp': currentXp,
      'happiness': happiness,
      'success': success,
      'love': love,
    };
  }

  // VERİ YÜKLEME İÇİN: JSON'ı Karakter nesnesine çevirir
  factory Character.fromJson(Map<String, dynamic> json, CharacterPreset preset) {
    return Character(
      id: json['id'],
      name: json['name'],
      description: preset.description,
      imagePath: preset.name == "Eren" ? 'assets/eren.png' : (preset.name == "Çınar" ? 'assets/cinar.png' : (preset.name == "Dilay" ? 'assets/dilay.png' : "")),
      level: json['level'] ?? 1,
      currentXp: json['currentXp'] ?? 0,
      happiness: json['happiness'] ?? 0.5,
      success: json['success'] ?? 0.1,
      love: json['love'] ?? 0.0,
      title: preset.title,
      isBarista: preset.title == "Barista",
    );
  }

  // Karakteri presetten üretme (Mevcut metodun)
  factory Character.fromPreset(CharacterPreset preset, {required String id, bool isPresent = false}) {
    String path = (preset.name == "Eren") ? 'assets/eren.png' : (preset.name == "Çınar" ? 'assets/cinar.png' : (preset.name == "Dilay" ? 'assets/dilay.png' : ""));
    return Character(
      id: id, name: preset.name, description: preset.description,
      title: preset.title, imagePath: path,
      isBarista: preset.title == "Barista", isPresent: isPresent,
      location: isPresent ? (preset.title == "Barista" ? "Kasa" : "Masa") : "Ev",
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
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      happiness: (happiness ?? this.happiness).clamp(0.0, 1.0),
      success: (success ?? this.success).clamp(0.0, 1.0),
      love: (love ?? this.love).clamp(0.0, 1.0),
      location: location ?? this.location,
      activity: activity ?? this.activity,
      isPresent: isPresent ?? this.isPresent,
      title: title, isBarista: isBarista,
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