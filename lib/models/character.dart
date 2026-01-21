import 'game_item.dart'; 
class Character {
  final String id;
  final String name;
  final String imagePath;
  final int level;
  final int currentXp;
  final int requiredXp;
  final String title;
  final bool isBarista; // Bu karakter kahve yapabilir mi?
  final GameItem? activeOrder; // Şu an ilgilendiği sipariş/baloncuk
  final DateTime? orderFinishTime;
  
  // DUYGULAR (Eksik olan 'love' buraya eklendi)
  final double happiness;
  final double success;
  final double love; 
  
  // KONUM VE DURUM BİLGİSİ
  final String location; // Örn: "Büyük Masa", "Bar Arkası"
  final String activity; // Örn: "Ders Çalışıyor", "Kahve Yapıyor"
  final bool isPresent;  // Şu an dükkanda mı?

  Character({
    required this.id,
    required this.name,
    required this.imagePath,
    this.level = 1,
    this.currentXp = 0,
    this.requiredXp = 100,
    this.title = "Başlangıç",
    this.happiness = 0.5,
    this.success = 0.1,
    this.love = 0.0, // Varsayılan değer
    this.location = "Dışarıda",
    this.activity = "Gelmeyi Bekliyor",
    this.isPresent = false,
    this.isBarista = false,
    this.activeOrder,
    this.orderFinishTime,
  });

  Character copyWith({
    int? level,
    int? currentXp,
    int? requiredXp,
    String? title,
    double? happiness,
    double? success,
    double? love,
    String? location,
    String? activity,
    bool? isPresent,
    bool? isBarista,
    GameItem? activeOrder,
    DateTime? orderFinishTime,
    bool? clearOrder,
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
      love: love ?? this.love, // Kopyalarken aşkı unutma
      location: location ?? this.location,
      activity: activity ?? this.activity,
      isPresent: isPresent ?? this.isPresent,
      isBarista: isBarista ?? this.isBarista,
      activeOrder: (clearOrder == true) ? null : (activeOrder ?? this.activeOrder),
      orderFinishTime: (clearOrder == true) ? null : (orderFinishTime ?? this.orderFinishTime),
      // ...
    );
  }
}