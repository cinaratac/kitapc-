import 'game_item.dart';

class Character {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final int level;
  final int currentXp;
  final int requiredXp;
  final String title;
  final bool isBarista;
  
  final GameItem? activeOrder; // Kahve/Çay siparişleri için
  final DateTime? orderFinishTime;
  
  final GameItem? activeActivity; // Laptop/Kitap aktiviteleri için
  final DateTime? activityFinishTime;
  
  final DateTime? arrivalTime; // Gecikme uyarısı için
  final DateTime? departureTime; 
  
  final double happiness;
  final double success;
  final double love; 
  
  final String location;
  final String activity;
  final bool isPresent;

  Character({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    this.level = 1,
    this.currentXp = 0,
    this.requiredXp = 100,
    this.title = "Müdavim",
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
    this.arrivalTime,
    this.departureTime,
  });

  Character copyWith({
    int? level, int? currentXp, double? happiness, double? success,
    double? love, String? location, String? activity, bool? isPresent,
    GameItem? activeOrder, DateTime? orderFinishTime,
    GameItem? activeActivity, DateTime? activityFinishTime,
    DateTime? arrivalTime, DateTime? departureTime,
    bool? clearOrder, bool? clearActivity,
  }) {
    return Character(
      id: id, name: name, description: description, imagePath: imagePath,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      requiredXp: requiredXp, title: title, isBarista: isBarista,
      happiness: (happiness ?? this.happiness).clamp(0.0, 1.0),
      success: (success ?? this.success).clamp(0.0, 1.0),
      love: (love ?? this.love).clamp(0.0, 1.0),
      location: location ?? this.location,
      activity: activity ?? this.activity,
      isPresent: isPresent ?? this.isPresent,
      activeOrder: (clearOrder == true) ? null : (activeOrder ?? this.activeOrder),
      orderFinishTime: (clearOrder == true) ? null : (orderFinishTime ?? this.orderFinishTime),
      activeActivity: (clearActivity == true) ? null : (activeActivity ?? this.activeActivity),
      activityFinishTime: (clearActivity == true) ? null : (activityFinishTime ?? this.activityFinishTime),
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
    );
  }
}