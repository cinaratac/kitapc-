import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character.dart';
import '../models/game_item.dart';
import '../data/character_presets.dart';

// OYUNUN TÜM DURUMUNU TAŞIYAN ANA SINIF
class GameStateData {
  final List<Character> characters;
  final DateTime gameTime;
  final bool isShopOpen;
  final int dailyRevenue; 
  final int dayCount;

  GameStateData({
    required this.characters,
    required this.gameTime,
    required this.isShopOpen,
    this.dayCount = 1,
    this.dailyRevenue = 0,
  });

  GameStateData copyWith({
    List<Character>? characters,
    DateTime? gameTime,
    bool? isShopOpen,
    int? dailyRevenue,
    int? dayCount,
  }) {
    return GameStateData(
      characters: characters ?? this.characters,
      gameTime: gameTime ?? this.gameTime,
      isShopOpen: isShopOpen ?? this.isShopOpen,
      dailyRevenue: dailyRevenue ?? this.dailyRevenue,
      dayCount: dayCount ?? this.dayCount,
    );
  }
}

// OYUNUN BEYNİ VE YAPAY ZEKA MOTORU
class GameNotifier extends Notifier<GameStateData> {
  Timer? _timer;
  final Random _rng = Random();
  int _customerCounter = 1;

  @override
  GameStateData build() {
    _startTimer();
    _loadAllData();

    final erenP = allPresets.firstWhere((p) => p.name == "Eren");
    final cinarP = allPresets.firstWhere((p) => p.name == "Çınar");

    // Oyun başlangıç saati 09:30 olarak ayarlandı
    return GameStateData(
      gameTime: DateTime(2025, 1, 1, 9, 30),
      isShopOpen: false,
      dayCount: 1,
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

  // --- XP VE SEVİYE SİSTEMİ ---
  Character _applyXp(Character c, int amount) {
    int newXp = c.currentXp + amount;
    int newLevel = c.level;
    while (newXp >= c.requiredXpForNextLevel) {
      newXp -= c.requiredXpForNextLevel;
      newLevel++;
    }
    return c.copyWith(currentXp: newXp, level: newLevel);
  }

  // --- VERİ KAYDETME ---
  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final charProgress = state.characters.map((c) => {
      'id': c.id,
      'name': c.name,
      'level': c.level,
      'currentXp': c.currentXp,
      'happiness': c.happiness,
      'success': c.success,
      'love': c.love,
    }).toList();

    await prefs.setString('saved_character_progress', jsonEncode(charProgress));
    await prefs.setInt('game_day_count', state.dayCount);
    print("SİSTEM: Veriler kaydedildi.");
  }

  // --- VERİ YÜKLEME ---
  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDay = prefs.getInt('game_day_count') ?? 1;
    final savedCharsJson = prefs.getString('saved_character_progress');

    if (savedCharsJson != null) {
      final List<dynamic> decoded = jsonDecode(savedCharsJson);
      List<Character> updatedChars = [...state.characters];
      for (var savedData in decoded) {
        int idx = updatedChars.indexWhere((c) => c.id == savedData['id']);
        if (idx != -1) {
          updatedChars[idx] = updatedChars[idx].copyWith(
            level: savedData['level'],
            currentXp: savedData['currentXp'],
            happiness: savedData['happiness'],
            success: savedData['success'],
            love: savedData['love'],
          );
        }
      }
      state = state.copyWith(dayCount: savedDay, characters: updatedChars);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _tick());
  }

  void _tick() {
    final oldTime = state.gameTime;
    DateTime newTime = oldTime.add(const Duration(minutes: 1));
    int currentDay = state.dayCount;
    List<Character> chars = [...state.characters];

    // --- GÜN SONU VE ZAMAN SIÇRAMASI (23:00) ---
    if (newTime.hour == 23 && newTime.minute == 0) {
      _saveAllData(); 
      currentDay++; 
      
      // Müşterileri temizle ve çalışanları eve gönder
      chars.removeWhere((c) => c.id.startsWith('musteri'));
      for (int i = 0; i < chars.length; i++) {
        chars[i] = chars[i].copyWith(
          isPresent: false,
          location: "Ev",
          activity: "Uyuyor 💤",
          clearOrder: true,
          clearActivity: true,
        );
      }
      
      // Zamanı doğrudan ertesi sabah 09:30'a ayarla
      newTime = DateTime(newTime.year, newTime.month, newTime.day)
          .add(const Duration(days: 1, hours: 9, minutes: 30));
    }

    // Dükkan Açılış: 10:00, Kapanış: 23:00
    bool isOpen = newTime.hour >= 10 && newTime.hour < 23;

    _handleRoutines(chars, newTime);

    if (isOpen) {
      _handleSpawning(chars, newTime);
      _handleOrdersAI(chars, newTime);
    }

    _handleCirculationAI(chars, newTime, isOpen);
    _handleProcessCompletions(chars, newTime);

    state = state.copyWith(
      gameTime: newTime,
      isShopOpen: isOpen,
      characters: chars,
      dayCount: currentDay,
    );
  }

  void _handleRoutines(List<Character> chars, DateTime now) {
    int erenIdx = chars.indexWhere((c) => c.id == 'eren');
    if (erenIdx != -1) {
      // 09:30 - 10:00 arası hazırlık aşaması
      if (now.hour == 9 && now.minute >= 30 && !chars[erenIdx].isPresent) {
        chars[erenIdx] = chars[erenIdx].copyWith(
          isPresent: true, 
          location: "Mutfak", 
          activity: "Tezgahı siliyor... 🧹"
        );
      }
      // 10:00'da dükkan açılır, Barista bar arkasına geçer
      if (now.hour >= 10 && chars[erenIdx].location == "Mutfak") {
        chars[erenIdx] = chars[erenIdx].copyWith(
          location: "Bar Arkası", 
          activity: "Sipariş Bekliyor"
        );
      }
    }
  }

  void _handleSpawning(List<Character> chars, DateTime now) {
    int currentCustomers = chars.where((c) => c.id.startsWith('musteri')).length;
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

  void _handleOrdersAI(List<Character> chars, DateTime now) {
    int globalActiveOrders = chars.where((c) => c.activeOrder != null).length;
    if (globalActiveOrders >= 3) return;

    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];
      if (!c.isPresent || c.isBarista || c.activeOrder != null || c.activeActivity != null) continue;

      bool wantsToOrder = false;
      if (c.lastOrderTime == null) {
        if (c.arrivalTime != null && now.difference(c.arrivalTime!).inMinutes > 20) {
          wantsToOrder = true;
        }
      } else {
        if (now.difference(c.lastOrderTime!).inMinutes >= 120) {
          wantsToOrder = true;
        }
      }

      if (now.hour == 22 && now.minute > 30) wantsToOrder = false;

      if (wantsToOrder && _rng.nextInt(100) < 10) {
        chars[i] = _triggerNewOrder(c, now);
      }
    }
  }

  void _handleCirculationAI(List<Character> chars, DateTime now, bool isOpen) {
    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];
      if (!c.isPresent || c.isBarista) continue;

      bool isTimeUp = c.departureTime != null && now.isAfter(c.departureTime!);
      bool isIdle = c.activeOrder == null && c.activeActivity == null;

      if (isTimeUp && isIdle) {
        _sendHome(chars, i);
        i--;
      }
    }
  }

  void _handleProcessCompletions(List<Character> chars, DateTime now) {
    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];
      if (c.orderFinishTime != null && now.isAfter(c.orderFinishTime!)) {
        if (c.isBarista && c.activeOrder?.orderStatus == OrderStatus.preparing) {
          chars[i] = _applyXp(c, 40).copyWith(
            activeOrder: c.activeOrder!.copyWith(orderStatus: OrderStatus.ready),
            activity: "Servis Hazır! 🔔",
            success: (c.success + 0.05).clamp(0.0, 1.0),
            orderFinishTime: null,
          );
        }
      }
      if (c.activityFinishTime != null && now.isAfter(c.activityFinishTime!)) {
        final preset = allPresets.firstWhere((p) => p.name == c.name, orElse: () => allPresets[0]);
        final m = preset.multipliers[c.activeActivity!.type] ?? {'xp': 25, 'happiness': 0.05};
        chars[i] = _applyXp(c, m['xp']?.toInt() ?? 30).copyWith(
          activity: "İşini bitirdi ✅",
          happiness: (c.happiness + (m['happiness'] ?? 0.05)).clamp(0.0, 1.0),
          success: (c.success + (m['success'] ?? 0.02)).clamp(0.0, 1.0),
          clearActivity: true,
        );
      }
    }
  }

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

  void _sendHome(List<Character> list, int index) {
    if (list[index].id.startsWith('musteri')) {
      list.removeAt(index);
    } else {
      list[index] = list[index].copyWith(
        isPresent: false, 
        location: "Ev", 
        activity: "Eve döndü 🏡", 
        clearOrder: true, 
        clearActivity: true
      );
    }
  }

  void giveItemToCharacter(String charId, GameItem item) {
    List<Character> updated = [...state.characters];
    int idx = updated.indexWhere((c) => c.id == charId);
    if (idx == -1) return;
    Character target = updated[idx];
    final preset = allPresets.firstWhere((p) => p.name == target.name, orElse: () => allPresets[0]);

    if (item.type == ItemType.laptop || item.type == ItemType.book) {
      if (target.activeActivity != null) return;
      updated[idx] = target.copyWith(
        activity: preset.activityTexts[item.type] ?? "Çalışıyor...",
        activityFinishTime: state.gameTime.add(Duration(minutes: item.type == ItemType.laptop ? 60 : 30)),
        activeActivity: item.copyWith(orderStatus: OrderStatus.processing),
      );
    } else {
      if (target.isBarista && item.orderStatus == OrderStatus.pending && target.activeOrder == null) {
        updated[idx] = target.copyWith(
          activeOrder: item.copyWith(orderStatus: OrderStatus.preparing),
          activity: "${item.name} hazırlıyor...",
          orderFinishTime: state.gameTime.add(const Duration(minutes: 5)),
        );
        int cIdx = updated.indexWhere((c) => c.id == item.relatedCustomerId);
        if (cIdx != -1) updated[cIdx] = updated[cIdx].copyWith(activity: "Bekliyor...", activeOrder: item.copyWith(orderStatus: OrderStatus.processing));
      } else if (item.relatedCustomerId == target.id && item.orderStatus == OrderStatus.ready) {
        updated[idx] = _applyXp(target, 50).copyWith(
          clearOrder: true,
          activity: "Kahvesini içiyor ☕",
          lastOrderTime: state.gameTime,
          happiness: (target.happiness + 0.1).clamp(0.0, 1.0),
        );
        int bIdx = updated.indexWhere((c) => c.isBarista);
        if (bIdx != -1) updated[bIdx] = updated[bIdx].copyWith(clearOrder: true, activity: "Sipariş Bekliyor");
      }
    }
    state = state.copyWith(characters: updated);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameStateData>(() => GameNotifier());