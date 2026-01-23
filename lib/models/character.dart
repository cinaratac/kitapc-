// lib/models/character.dart
import 'dart:convert';
import 'game_item.dart';
import '../data/character_presets.dart';

class Character {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  
  // --- SEVİYE VE XP SİSTEMİ ---
  final int level;
  final int currentXp;
  
  // --- İSTATİSTİK BARLARI ---
  final double happiness; // 0.0 - 1.0
  final double success;   // 0.0 - 1.0 (Barista için kritik)
  final double love;      // 0.0 - 1.0 (İleride sosyal ilişkiler için)
  int get requiredXp => 100 + (level - 1) * 50;
  // --- OYUN MANTIĞI ALANLARI ---
  final String title;
  final bool isBarista;
  final GameItem? activeOrder;
  final DateTime? orderFinishTime;
  final DateTime? lastOrderTime; 
  final GameItem? activeActivity;
  final DateTime? activityFinishTime;
  final DateTime? arrivalTime;
  final DateTime? departureTime; 
  final String location;
  final String activity;
  final bool isPresent;

  Character({
    required this.id, required this.name, required this.description, required this.imagePath,
    this.level = 1, this.currentXp = 0, this.happiness = 0.5, this.success = 0.1, this.love = 0.0,
    this.title = "Müdavim", this.isBarista = false, this.location = "Dışarıda",
    this.activity = "Dinleniyor", this.isPresent = false, this.activeOrder,
    this.orderFinishTime, this.lastOrderTime, this.activeActivity, this.activityFinishTime,
    this.arrivalTime, this.departureTime,
  });

  // Bir sonraki seviye için gereken XP miktarını hesaplayan zeka
  int get requiredXpForNextLevel {
    // L1->L2: 100, L2->L3: 250, L3->L4: 450 (+150, +200...)
    if (level == 1) return 100;
    int total = 100;
    int increment = 150;
    for (int i = 2; i <= level; i++) {
      if (i == level) return total + increment;
      total += increment;
      increment += 50;
    }
    return 1000; // Default fallback
  }

  // --- PERSISTENCE (KAYIT) İÇİN JSON DÖNÜŞÜMLERİ ---
  Map<String, dynamic> toJson() {
    return {
      'id': id, 'name': name, 'level': level, 'currentXp': currentXp,
      'happiness': happiness, 'success': success, 'love': love,
    };
  }

  factory Character.fromJson(Map<String, dynamic> json, CharacterPreset preset) {
    return Character(
      id: json['id'],
      name: json['name'],
      description: preset.description,
      imagePath: _determineImagePath(json['name']),
      level: json['level'] ?? 1,
      currentXp: json['currentXp'] ?? 0,
      happiness: json['happiness'] ?? 0.5,
      success: json['success'] ?? 0.1,
      love: json['love'] ?? 0.0,
      title: preset.title,
      isBarista: preset.title == "Barista",
    );
  }

  static String _determineImagePath(String name) {
    if (name == "Eren") return 'assets/eren.png';
    if (name == "Çınar") return 'assets/cinar.png';
    if (name == "Dilay") return 'assets/dilay.png';
    return ""; // Diğerleri için boş, UI ikon basar
  }

  factory Character.fromPreset(CharacterPreset preset, {required String id, bool isPresent = false}) {
    return Character(
      id: id, name: preset.name, description: preset.description,
      title: preset.title, imagePath: _determineImagePath(preset.name),
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