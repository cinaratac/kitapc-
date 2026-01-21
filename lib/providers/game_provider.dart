import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../models/game_item.dart';

// DİKKAT: Artık "StateNotifier" değil "Notifier" kullanıyoruz.
// Bu sınıf Riverpod'un en güncel yapısıdır.
class GameState extends Notifier<List<Character>> {
  
  // Constructor yerine build() metodu kullanıyoruz.
  // Başlangıç verileri burada tanımlanır.
  @override
  List<Character> build() {
    return [
      Character(id: 'eren', name: 'Eren', imagePath: 'assets/eren.png', title: 'Çırak Barista'),
      Character(id: 'cinar', name: 'Çınar', imagePath: 'assets/cinar.png', title: 'Depresif Öğrenci'),
    ];
  }

  // Eşya verildiğinde çalışacak fonksiyon
  void giveItem(String characterId, GameItem item) {
    // state = [...] diyerek listeyi güncelliyoruz
    state = [
      for (final char in state)
        if (char.id == characterId)
          _processItem(char, item)
        else
          char
    ];
  }

  Character _processItem(Character char, GameItem item) {
    int newXp = char.currentXp + item.xpValue;
    double newHappiness = char.happiness;
    double newSuccess = char.success;
    double newLove = char.love;

    // Eşya tipine göre etki (Mantığı sen değiştirebilirsin)
    switch (item.type) {
      case ItemType.coffee:
        newHappiness += 0.1; // Kahve mutluluk verir
        newSuccess += 0.05;  // Biraz da enerji verir
        break;
      case ItemType.laptop: // Kod yazmak
        newSuccess += 0.15;  // Başarı artar
        newHappiness -= 0.05; // Ama yorar (Mutluluk düşer)
        break;
      case ItemType.book:
        newSuccess += 0.05;
        newHappiness += 0.05;
        break;
      case ItemType.catFood:
        newLove += 0.2; // Kediyi beslemek aşkı artırır
        newHappiness += 0.1;
        break;
    }
    newHappiness = newHappiness.clamp(0.0, 1.0);
    newSuccess = newSuccess.clamp(0.0, 1.0);
    newLove = newLove.clamp(0.0, 1.0);
    int newLevel = char.level;
    int newRequiredXp = char.requiredXp;
    String newTitle = char.title;

    if (newXp >= char.requiredXp) {
      newXp = newXp - char.requiredXp;
      newLevel++;
      newRequiredXp = (newRequiredXp * 1.5).toInt();
      
      if (char.id == 'eren' && newLevel == 5) newTitle = "Usta Barista";
      if (char.id == 'cinar' && newLevel == 5) newTitle = "Junior Developer";
    }

    return char.copyWith(
      currentXp: newXp,
      level: newLevel,
      requiredXp: newRequiredXp,
      title: newTitle,
      happiness: newHappiness,
      success: newSuccess,
      love: newLove,
    );
  }
}

// Sağlayıcı (Provider) tanımı da değişti:
// StateNotifierProvider -> NotifierProvider oldu.
final gameProvider = NotifierProvider<GameState, List<Character>>(() {
  return GameState();
});