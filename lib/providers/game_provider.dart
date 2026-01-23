import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../models/game_item.dart';
import '../data/character_presets.dart';

// OYUNUN TÜM DURUMUNU TAŞIYAN ANA SINIF
class GameStateData {
  final List<Character> characters;
  final DateTime gameTime;
  final bool isShopOpen;
  final int dailyRevenue; // Günlük puan/başarı takibi

  GameStateData({
    required this.characters,
    required this.gameTime,
    required this.isShopOpen,
    this.dailyRevenue = 0,
  });

  GameStateData copyWith({
    List<Character>? characters,
    DateTime? gameTime,
    bool? isShopOpen,
    int? dailyRevenue,
  }) {
    return GameStateData(
      characters: characters ?? this.characters,
      gameTime: gameTime ?? this.gameTime,
      isShopOpen: isShopOpen ?? this.isShopOpen,
      dailyRevenue: dailyRevenue ?? this.dailyRevenue,
    );
  }
}

// OYUNUN BEYNİ VE YAPAY ZEKA MOTORU
class GameNotifier extends Notifier<GameStateData> {
  Timer? _timer;
  final Random _rng = Random();
  int _customerCounter = 1;
  // XP ekleme ve Level kontrolü yapan yardımcı fonksiyon
 Character _applyXp(Character c, int amount) {
  int newXp = c.currentXp + amount;
  int newLevel = c.level;
  
  // Seviye atlama kontrolü (Character modelindeki requiredXpForNextLevel'i kullanır)
  while (newXp >= c.requiredXpForNextLevel) {
    newXp -= c.requiredXpForNextLevel;
    newLevel++;
  }

  return c.copyWith(currentXp: newXp, level: newLevel);
}
  @override
  GameStateData build() {
    _startTimer();

    // Ana karakterleri preset dosyasından çekiyoruz
    final erenP = allPresets.firstWhere((p) => p.name == "Eren");
    final cinarP = allPresets.firstWhere((p) => p.name == "Çınar");

    return GameStateData(
      gameTime: DateTime(2025, 1, 1, 10, 0), // Sabah 10:00 Hazırlık
      isShopOpen: false,
      characters: [
        Character.fromPreset(erenP, id: 'eren', isPresent: false).copyWith(
          location: "Ev", 
          activity: "Güne hazırlanıyor..."
        ),
        Character.fromPreset(cinarP, id: 'cinar', isPresent: false).copyWith(
          location: "Ev", 
          activity: "Uyuyor"
        ),
      ],
    );
  }

  // ZAMAN DÖNGÜSÜ: 1 Saniye = 1 Dakika
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  // HER DAKİKA ÇALIŞAN ANA MOTOR
  void _tick() {
    DateTime newTime = state.gameTime.add(const Duration(minutes: 1));
    bool isOpen = newTime.hour >= 11 && newTime.hour < 23;
    List<Character> chars = [...state.characters];

    // --- 1. BARISTA VE ANA KARAKTER RUTİNLERİ ---
    _handleRoutines(chars, newTime);

    // --- 2. SİPARİŞ VE MÜŞTERİ ZEKSASI (AI) ---
    if (isOpen) {
      _handleSpawning(chars, newTime);
      _handleOrdersAI(chars, newTime);
    }

    // --- 3. KAPANIŞ VE AYRILMA STRATEJİSİ ---
    _handleClosingAI(chars, newTime, isOpen);

    // --- 4. SÜREÇ TAMAMLANMALARI ---
    _handleProcessCompletions(chars, newTime);

    state = state.copyWith(
      gameTime: newTime,
      isShopOpen: isOpen,
      characters: chars,
    );
  }

  // BARİSTA VE ANA KARAKTERLERİN GÜNLÜK HAREKETLERİ
  void _handleRoutines(List<Character> chars, DateTime now) {
    int erenIdx = chars.indexWhere((c) => c.id == 'eren');
    if (erenIdx != -1) {
      // 10:30'da hazırlığa gelir
      if (now.hour == 10 && now.minute == 30 && !chars[erenIdx].isPresent) {
        chars[erenIdx] = chars[erenIdx].copyWith(
          isPresent: true, 
          location: "Mutfak", 
          activity: "Tezgahı siliyor... 🧹"
        );
      }
      // 11:00'de bar arkasına geçer
      if (now.hour == 11 && now.minute == 0) {
        chars[erenIdx] = chars[erenIdx].copyWith(
          location: "Bar Arkası", 
          activity: "Sipariş Bekliyor"
        );
      }
    }
  }

  // MÜŞTERİ GELİŞ-GİDİŞ YÖNETİMİ
  void _handleSpawning(List<Character> chars, DateTime now) {
    int currentCustomers = chars.where((c) => c.id.startsWith('musteri')).length;
    
    // Rastgele yeni müşteri (%8 şans)
    if (currentCustomers < 6 && _rng.nextInt(100) < 8) {
      final available = allPresets.where((p) => p.name != "Eren" && p.name != "Çınar").toList();
      final p = available[_rng.nextInt(available.length)];
      
      if (!chars.any((c) => c.name == p.name && c.isPresent)) {
        int stayMinutes = 45 + _rng.nextInt(180);
        chars.add(Character.fromPreset(p, id: "musteri_$_customerCounter", isPresent: true).copyWith(
          arrivalTime: now,
          departureTime: now.add(Duration(minutes: stayMinutes)),
          activity: "Dükkana girdi...",
          location: "Masa",
        ));
        _customerCounter++;
      }
    }

    // Çınar her dakika %2 şansla gelmeyi dener
    int cinarIdx = chars.indexWhere((c) => c.id == 'cinar');
    if (cinarIdx != -1 && !chars[cinarIdx].isPresent && _rng.nextInt(100) < 2) {
      chars[cinarIdx] = chars[cinarIdx].copyWith(
        isPresent: true, 
        location: "Giriş", 
        activity: "Selam! 🙋‍♂️", 
        arrivalTime: now,
        departureTime: now.add(const Duration(minutes: 150)),
      );
    }
  }

  // GELİŞMİŞ SİPARİŞ ZEKSASI
  void _handleOrdersAI(List<Character> chars, DateTime now) {
    // KURAL: Dükkanda toplamda en fazla 3 sipariş olabilir (Bekleyen + Hazırlanan + Hazır)
    int globalActiveOrders = chars.where((c) => c.activeOrder != null).length;
    if (globalActiveOrders >= 3) return;

    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];
      if (!c.isPresent || c.isBarista || c.activeOrder != null || c.activeActivity != null) continue;

      bool wantsToOrder = false;

      // KURAL: İlk sipariş dükkana girdikten 15-30 dk sonra verilmeli
      if (c.lastOrderTime == null) {
        if (c.arrivalTime != null && now.difference(c.arrivalTime!).inMinutes > 20) {
          wantsToOrder = true;
        }
      } else {
        // KURAL: Her siparişten sonra minimum 2 saat (120 dk) beklenmeli
        if (now.difference(c.lastOrderTime!).inMinutes >= 120) {
          wantsToOrder = true;
        }
      }

      // Kapanışa 30 dk kala yeni sipariş verilmez
      if (now.hour == 22 && now.minute > 30) wantsToOrder = false;

      if (wantsToOrder && _rng.nextInt(100) < 10) {
        chars[i] = _triggerNewOrder(c, now);
      }
    }
  }

  // YAPAY ZEKA: KAPANIŞ VE AYRILMA MANTIĞI
  void _handleClosingAI(List<Character> chars, DateTime now, bool isOpen) {
    // SAAT 23:00 KURALI: Dükkan kesin kapanır, herkes gider!
    if (now.hour == 23 && now.minute == 0) {
      chars.removeWhere((c) => c.id.startsWith('musteri'));
      for (int i = 0; i < chars.length; i++) {
        chars[i] = chars[i].copyWith(
          isPresent: false, 
          location: "Ev", 
          activity: "Kapandı 💤", 
          clearOrder: true, 
          clearActivity: true
        );
      }
      return;
    }

    // SAAT 22:00'DEN SONRA: Müşteriler yavaş yavaş gitmeye başlar
    if (now.hour == 22) {
      for (int i = 0; i < chars.length; i++) {
        Character c = chars[i];
        if (!c.isPresent || c.isBarista) continue;

        // KURAL: Siparişi varsa ASLA almadan gitmez (23:00'e kadar bekler)
        if (c.activeOrder == null && c.activeActivity == null) {
          // Süresi dolmuşsa veya %15 şansla erken gitmek istiyorsa
          if ((c.departureTime != null && now.isAfter(c.departureTime!)) || _rng.nextInt(100) < 15) {
            _sendHome(chars, i);
            i--;
          }
        }
      }
    }

    // GÜN İÇİNDE NORMAL AYRILMA
    if (isOpen) {
      for (int i = 0; i < chars.length; i++) {
        Character c = chars[i];
        if (c.isPresent && !c.isBarista && c.departureTime != null && now.isAfter(c.departureTime!)) {
          // Sadece işi bittiyse gider
          if (c.activeOrder == null && c.activeActivity == null) {
            _sendHome(chars, i);
            i--;
          }
        }
      }
    }
  }

  // SÜREÇLERİN BİTİŞ KONTROLLERİ
  void _handleProcessCompletions(List<Character> chars, DateTime now) {
    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];

      // Barista kahveyi bitirdi mi?
      if (c.orderFinishTime != null && now.isAfter(c.orderFinishTime!)) {
        if (c.isBarista && c.activeOrder?.orderStatus == OrderStatus.preparing) {
  // Barista için 40 XP ve 0.05 Başarı puanı ekle
  Character updatedEren = _applyXp(c, 40); 
  chars[i] = updatedEren.copyWith(
    activeOrder: c.activeOrder!.copyWith(orderStatus: OrderStatus.ready),
    activity: "Servis Hazır! 🔔",
    success: c.success + 0.05, // Başarı barını yükselt
    orderFinishTime: null,
  );
}
      }

      // Aktivite bitti mi?
      if (c.activityFinishTime != null && now.isAfter(c.activityFinishTime!)) {
  final preset = allPresets.firstWhere((p) => p.name == c.name, orElse: () => allPresets[0]);
  final m = preset.multipliers[c.activeActivity!.type] ?? {'xp': 25, 'happiness': 0.05};
  
  // Aktiviteye göre özel XP ve Mutluluk/Başarı artışı
  Character finishedChar = _applyXp(c, m['xp']?.toInt() ?? 30);
  chars[i] = finishedChar.copyWith(
    activity: "İşini bitirdi ✅",
    happiness: c.happiness + (m['happiness'] ?? 0.05),
    success: c.success + (m['success'] ?? 0.02),
    clearActivity: true,
  );
}
    }
  }

  // YARDIMCI: SİPARİŞ TETİKLEME
  Character _triggerNewOrder(Character c, DateTime now) {
    final drinks = [
      {'name': 'Filtre Kahve', 'type': ItemType.filterCoffee},
      {'name': 'Latte', 'type': ItemType.latte},
      {'name': 'Espresso', 'type': ItemType.espresso},
      {'name': 'Bitki Çayı', 'type': ItemType.herbalTea},
    ];
    final pick = drinks[_rng.nextInt(drinks.length)];

    return c.copyWith(
      activeOrder: GameItem(
        id: "ord_${now.millisecondsSinceEpoch}",
        name: pick['name'] as String,
        type: pick['type'] as ItemType,
        relatedCustomerId: c.id,
        orderStatus: OrderStatus.pending,
      ),
      activity: "Canı ${pick['name']} çekti!",
    );
  }

  // YARDIMCI: EVE GÖNDERME
  void _sendHome(List<Character> list, int index) {
    if (list[index].id.startsWith('musteri')) {
      list.removeAt(index);
    } else {
      list[index] = list[index].copyWith(
        isPresent: false, 
        location: "Ev", 
        activity: "Gitti", 
        clearOrder: true, 
        clearActivity: true
      );
    }
  }

  // --- UI'DAN ÇAĞRILAN: EŞYA TESLİMATI ---
  void giveItemToCharacter(String charId, GameItem item) {
    List<Character> updated = [...state.characters];
    int idx = updated.indexWhere((c) => c.id == charId);
    if (idx == -1) return;
    Character target = updated[idx];
    final preset = allPresets.firstWhere((p) => p.name == target.name, orElse: () => allPresets[0]);

    // 1. AKTİVİTE TEPKİSİ
    if (item.type == ItemType.laptop || item.type == ItemType.book) {
      if (target.activeActivity != null) return;
      
      // PRESET TEPKİSİ: Dosyadan çek, yoksa varsayılan kullan
      String reaction = preset.activityTexts[item.type] ?? (item.type == ItemType.laptop ? "Laptop başında..." : "Kitap okuyor...");

      updated[idx] = target.copyWith(
        activity: reaction,
        activityFinishTime: state.gameTime.add(Duration(minutes: item.type == ItemType.laptop ? 60 : 30)),
        activeActivity: item.copyWith(orderStatus: OrderStatus.processing),
      );
    } 
    // 2. SİPARİŞ YÖNETİMİ
    else {
      // Barista Siparişi Alır
      if (target.isBarista && item.orderStatus == OrderStatus.pending && target.activeOrder == null) {
        updated[idx] = target.copyWith(
          activeOrder: item.copyWith(orderStatus: OrderStatus.preparing),
          activity: "${item.name} hazırlıyor... (5dk)",
          orderFinishTime: state.gameTime.add(const Duration(minutes: 5)),
        );
        int cIdx = updated.indexWhere((c) => c.id == item.relatedCustomerId);
        if (cIdx != -1) updated[cIdx] = updated[cIdx].copyWith(activity: "Bekliyor...", activeOrder: item.copyWith(orderStatus: OrderStatus.processing));
      } 
      // Müşteri Kahvesini Alır
      else if (item.relatedCustomerId == target.id && item.orderStatus == OrderStatus.ready) {
  // Kahve içen müşteriye 50 XP ve 0.1 Mutluluk ekle
  Character happyChar = _applyXp(target, 50);
  updated[idx] = happyChar.copyWith(
    clearOrder: true,
    activity: "Keyfi yerinde ☕",
    lastOrderTime: state.gameTime, // 2 saatlik bekleme süresini başlatır
    happiness: target.happiness + 0.1, // Mutluluk barını yükselt
  );
        int bIdx = updated.indexWhere((c) => c.isBarista);
        if (bIdx != -1) updated[bIdx] = updated[bIdx].copyWith(clearOrder: true, activity: "Sipariş Bekliyor");
      }
    }
    state = state.copyWith(characters: updated);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameStateData>(() => GameNotifier());