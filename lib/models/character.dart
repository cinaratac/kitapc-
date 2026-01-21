import 'game_item.dart'; 

class Character {
  final String id;
  final String name;
  final String imagePath;
  final int level;
  final int currentXp;
  final int requiredXp;
  final String title;
  final bool isBarista;
  
  // İKİ AYRI KANAL
  final GameItem? activeOrder;       // Kahve siparişleri için
  final DateTime? orderFinishTime;   // Kahve bitiş süresi
  
  final GameItem? activeActivity;    // Kitap/Kod aktiviteleri için
  final DateTime? activityFinishTime;// Aktivite bitiş süresi
  
  final double happiness;
  final double success;
  final double love; 
  final String location;
  final String activity;
  final bool isPresent;

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
    this.love = 0.0,
    this.location = "Dışarıda",
    this.activity = "Gelmeyi Bekliyor",
    this.isPresent = false,
    this.isBarista = false,
    this.activeOrder,
    this.orderFinishTime,
    this.activeActivity,
    this.activityFinishTime,
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
    GameItem? activeActivity,
    DateTime? activityFinishTime,
    bool? clearOrder,    // Sipariş temizleme flag'i
    bool? clearActivity, // Aktivite temizleme flag'i
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
      location: location ?? this.location,
      activity: activity ?? this.activity,
      isPresent: isPresent ?? this.isPresent,
      isBarista: isBarista ?? this.isBarista,
      // Sipariş Kanalı Kontrolü
      activeOrder: (clearOrder == true) ? null : (activeOrder ?? this.activeOrder),
      orderFinishTime: (clearOrder == true) ? null : (orderFinishTime ?? this.orderFinishTime),
      // Aktivite Kanalı Kontrolü
      activeActivity: (clearActivity == true) ? null : (activeActivity ?? this.activeActivity),
      activityFinishTime: (clearActivity == true) ? null : (activityFinishTime ?? this.activityFinishTime),
    );
  }
}