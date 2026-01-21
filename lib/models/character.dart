// lib/models/character.dart
class Character {
  final String id;
  final String name;
  final String imagePath;
  final int level;
  final int currentXp;
  final int requiredXp;
  final String title;
  
  // YENİ EKLENENLER:
  final double happiness; // Mutluluk (0.0 - 1.0 arası)
  final double success;   // Başarı
  final double love;      // Aşk

  Character({
    required this.id,
    required this.name,
    required this.imagePath,
    this.level = 1,
    this.currentXp = 0,
    this.requiredXp = 100,
    this.title = "Başlangıç",
    this.happiness = 0.5, // %50 ile başlasın
    this.success = 0.1,
    this.love = 0.0,
  });

  Character copyWith({
    int? level,
    int? currentXp,
    int? requiredXp,
    String? title,
    double? happiness,
    double? success,
    double? love,
  }) {
    return Character(
      id: id,
      name: name,
      imagePath: imagePath,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      requiredXp: requiredXp ?? this.requiredXp,
      title: title ?? this.title,
      happiness: happiness ?? this.happiness,
      success: success ?? this.success,
      love: love ?? this.love,
    );
  }
}