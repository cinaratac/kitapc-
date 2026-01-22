import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../models/game_item.dart';
import '../data/character_presets.dart'; // Presetleri ekledik

class GameStateData {
  final List<Character> characters;
  final DateTime gameTime;
  final bool isShopOpen;

  GameStateData({
    required this.characters,
    required this.gameTime,
    required this.isShopOpen,
  });

  GameStateData copyWith({
    List<Character>? characters,
    DateTime? gameTime,
    bool? isShopOpen,
  }) {
    return GameStateData(
      characters: characters ?? this.characters,
      gameTime: gameTime ?? this.gameTime,
      isShopOpen: isShopOpen ?? this.isShopOpen,
    );
  }
}

class GameNotifier extends Notifier<GameStateData> {
  Timer? _timer;
  final Random _rng = Random();
  int _customerCounter = 1;

  @override
  GameStateData build() {
    _startTimer();

    // Preset listesinden ana karakterleri buluyoruz
    final erenPreset = allPresets.firstWhere((p) => p.name == "Eren");
    final cinarPreset = allPresets.firstWhere((p) => p.name == "Çınar");

    return GameStateData(
      gameTime: DateTime(2025, 1, 1, 9, 30),
      isShopOpen: false,
      characters: [
        Character(
          id: 'eren',
          name: erenPreset.name,
          description: erenPreset.description,
          imagePath: 'assets/eren.png',
          title: erenPreset.title,
          isBarista: true,
          isPresent: false,
          location: "Ev",
          activity: "Uyanıyor...",
        ),
        Character(
          id: 'cinar',
          name: cinarPreset.name,
          description: cinarPreset.description,
          imagePath: 'assets/cinar.png',
          title: cinarPreset.title,
          isPresent: false,
          location: "Ev",
          activity: "Uyuyor",
        ),
      ],
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  void _tick() {
    DateTime newTime = state.gameTime.add(const Duration(minutes: 1));
    bool isOpen = newTime.hour >= 11 && newTime.hour < 23;
    List<Character> chars = [...state.characters];

    // --- BARISTA RUTİNİ ---
    if (newTime.hour == 10 && newTime.minute == 0) {
      int idx = chars.indexWhere((c) => c.id == 'eren');
      if (idx != -1) {
        chars[idx] = chars[idx].copyWith(
          isPresent: true,
          location: "Kasa",
          activity: "Dükkanı Hazırlıyor 🧹",
        );
      }
    }

    if (newTime.hour == 11 && newTime.minute == 0) {
      int idx = chars.indexWhere((c) => c.id == 'eren');
      if (idx != -1) {
        chars[idx] = chars[idx].copyWith(
          location: "Bar Arkası",
          activity: "Sipariş Bekliyor",
        );
      }
    }

    // --- MÜŞTERİ SİRKÜLASYONU VE SİPARİŞ ZEKSASI ---
    if (isOpen) {
      int currentCustomers = chars.where((c) => c.id.startsWith('musteri')).length;
      if (currentCustomers < 5 && _rng.nextInt(100) < 5) {
        _spawnCustomer(chars, newTime);
      }

      int cinarIdx = chars.indexWhere((c) => c.id == 'cinar');
      if (cinarIdx != -1 && !chars[cinarIdx].isPresent && _rng.nextInt(100) < 2) {
        DateTime depart = newTime.add(Duration(minutes: 120 + _rng.nextInt(240)));
        chars[cinarIdx] = chars[cinarIdx].copyWith(
          isPresent: true,
          location: "Giriş",
          activity: "Selam Veriyor 👋",
          departureTime: depart,
        );
      }

      int activeOrdersCount = chars.where((c) {
        if (c.activeOrder == null) return false;
        return c.activeOrder!.orderStatus == OrderStatus.pending || 
               c.activeOrder!.orderStatus == OrderStatus.processing;
      }).length;

      if (activeOrdersCount < 3) {
        List<int> potentialOrderers = [];
        for (int i = 0; i < chars.length; i++) {
          if (chars[i].isPresent && !chars[i].isBarista && chars[i].activeOrder == null) {
            potentialOrderers.add(i);
          }
        }

        if (potentialOrderers.isNotEmpty && _rng.nextInt(100) < 10) {
          int luckyIdx = potentialOrderers[_rng.nextInt(potentialOrderers.length)];
          chars[luckyIdx] = _generateOrderForCharacter(chars[luckyIdx], newTime);
        }
      }
    }

    // --- AYRILMA VE GÖREV KONTROLLERİ ---
    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];
      if (c.isPresent && !c.isBarista && c.departureTime != null && 
          newTime.isAfter(c.departureTime!) && c.activeOrder == null && c.activeActivity == null) {
        if (c.id.startsWith('musteri')) {
          chars.removeAt(i);
          i--;
          continue;
        } else {
          chars[i] = c.copyWith(
            isPresent: false,
            location: "Ev",
            activity: "Dinleniyor",
            clearOrder: true,
            clearActivity: true,
          );
        }
      }

      // Sipariş/Aktivite bitiş kontrolleri... (Önceki kodla aynı)
      if (c.orderFinishTime != null && newTime.isAfter(c.orderFinishTime!)) {
        if (c.isBarista && c.activeOrder?.orderStatus == OrderStatus.preparing) {
          chars[i] = c.copyWith(
            activeOrder: c.activeOrder!.copyWith(orderStatus: OrderStatus.ready),
            activity: "Servis Hazır! 🔔",
            orderFinishTime: null,
          );
        }
      }

      if (c.activityFinishTime != null && newTime.isAfter(c.activityFinishTime!)) {
        // Preset üzerinden çarpanları uygulama
        final preset = allPresets.firstWhere((p) => p.name == c.name, orElse: () => allPresets[0]);
        final type = c.activeActivity?.type;
        
        if (type != null && preset.multipliers.containsKey(type)) {
          final m = preset.multipliers[type]!;
          chars[i] = c.copyWith(
            activity: "${c.activeActivity?.name} bitti",
            happiness: (c.happiness + (m['happiness'] ?? 0)).clamp(0.0, 1.0),
            success: (c.success + (m['success'] ?? 0)).clamp(0.0, 1.0),
            currentXp: c.currentXp + (m['xp']?.toInt() ?? 20),
            clearActivity: true,
          );
        }
      }
    }

    state = state.copyWith(gameTime: newTime, isShopOpen: isOpen, characters: chars);
  }

  void _spawnCustomer(List<Character> list, DateTime currentTime) {
    // Eren ve Çınar dışındaki presetlerden rastgele seçiyoruz
    final availablePresets = allPresets.where((p) => p.name != "Eren" && p.name != "Çınar").toList();
    final randomPreset = availablePresets[_rng.nextInt(availablePresets.length)];
    
    String custId = "musteri_$_customerCounter";
    _customerCounter++;

    int stayDuration = 60 + _rng.nextInt(180);
    DateTime departAt = currentTime.add(Duration(minutes: stayDuration));

    list.add(Character(
      id: custId,
      name: randomPreset.name,
      description: randomPreset.description,
      imagePath: 'assets/cinar.png', // Tüm müşteriler şimdilik aynı görseli kullanabilir
      title: randomPreset.title,
      isPresent: true,
      location: "Masa",
      activity: "Dükkana girdi...",
      departureTime: departAt,
    ));
  }

  Character _generateOrderForCharacter(Character c, DateTime currentTime) {
    List<ItemType> drinks = [ItemType.filterCoffee, ItemType.latte, ItemType.espresso, ItemType.herbalTea];
    ItemType wanted = drinks[_rng.nextInt(drinks.length)];
    
    GameItem order = GameItem(
      id: "ord_${currentTime.millisecondsSinceEpoch}",
      name: wanted.name,
      type: wanted,
      relatedCustomerId: c.id,
      orderStatus: OrderStatus.pending,
    );

    return c.copyWith(
      activeOrder: order,
      activity: "Canı ${order.name} çekti...",
      arrivalTime: currentTime,
    );
  }

  void giveItemToCharacter(String charId, GameItem item) {
    List<Character> updatedChars = [...state.characters];
    int idx = updatedChars.indexWhere((c) => c.id == charId);
    if (idx == -1) return;
    Character target = updatedChars[idx];

    // Karakterin presetini bul (Özel diyaloglar için)
    final preset = allPresets.firstWhere((p) => p.name == target.name, orElse: () => allPresets[0]);

    if (item.type == ItemType.laptop || item.type == ItemType.book) {
      if (target.activeActivity != null) return;

      int duration = item.type == ItemType.laptop ? 120 : 60;
      // Preset içindeki özel aktivite metnini kullanıyoruz
      String activityText = preset.activityTexts[item.type] ?? "Çalışıyor...";

      updatedChars[idx] = target.copyWith(
        activity: activityText,
        activityFinishTime: state.gameTime.add(Duration(minutes: duration)),
        activeActivity: item.copyWith(
          id: "act_${_rng.nextInt(999)}",
          orderStatus: OrderStatus.processing,
        ),
      );
    } else {
      // Sipariş mantığı aynı...
      if (target.isBarista && item.orderStatus == OrderStatus.pending) {
        updatedChars[idx] = target.copyWith(
          activeOrder: item.copyWith(orderStatus: OrderStatus.preparing),
          activity: "${item.name} Hazırlıyor...",
          orderFinishTime: state.gameTime.add(const Duration(minutes: 15)),
        );
        // ... müşteri güncellemesi
      } else if (item.relatedCustomerId == target.id && item.orderStatus == OrderStatus.ready) {
        updatedChars[idx] = target.copyWith(
          clearOrder: true,
          activity: "Kahvesini yudumluyor ☕",
          currentXp: target.currentXp + 50,
          success: (target.success + 0.02).clamp(0.0, 1.0),
        );
      }
    }
    state = state.copyWith(characters: updatedChars);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameStateData>(() => GameNotifier());