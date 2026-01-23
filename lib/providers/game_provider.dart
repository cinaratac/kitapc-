// lib/providers/game_provider.dart
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character.dart';
import '../models/game_item.dart';
import '../models/shop_models.dart';
import '../data/character_presets.dart';

// --- OYUNUN TÜM DURUMUNU TAŞIYAN ANA SINIF ---
class GameStateData {
  final List<Character> characters;
  final DateTime gameTime;
  final bool isShopOpen;
  final int dailyRevenue; 
  final int dayCount;

  // Dükkanın fiziksel alanları (Eskiden shop_provider içindeydi)
  final List<SeatSlot> terraceSlots;
  final List<SeatSlot> bigTableSlots;
  final List<SeatSlot> salonSlots;

  GameStateData({
    required this.characters,
    required this.gameTime,
    required this.isShopOpen,
    this.dayCount = 1,
    this.dailyRevenue = 0,
    required this.terraceSlots,
    required this.bigTableSlots,
    required this.salonSlots,
  });

  GameStateData copyWith({
    List<Character>? characters,
    DateTime? gameTime,
    bool? isShopOpen,
    int? dailyRevenue,
    int? dayCount,
    List<SeatSlot>? terraceSlots,
    List<SeatSlot>? bigTableSlots,
    List<SeatSlot>? salonSlots,
  }) {
    return GameStateData(
      characters: characters ?? this.characters,
      gameTime: gameTime ?? this.gameTime,
      isShopOpen: isShopOpen ?? this.isShopOpen,
      dailyRevenue: dailyRevenue ?? this.dailyRevenue,
      dayCount: dayCount ?? this.dayCount,
      terraceSlots: terraceSlots ?? this.terraceSlots,
      bigTableSlots: bigTableSlots ?? this.bigTableSlots,
      salonSlots: salonSlots ?? this.salonSlots,
    );
  }
}

// --- OYUNUN BEYNİ VE YAPAY ZEKA MOTORU ---
class GameNotifier extends Notifier<GameStateData> {
  Timer? _timer;
  final Random _rng = Random();

  @override
  GameStateData build() {
    _startTimer();

    // 1. Tüm müdavim karakterleri presetlerden oluştur
    final allInitialCharacters = allPresets.map((preset) {
      return Character.fromPreset(
        preset, 
        id: preset.name.toLowerCase(), 
        isPresent: false
      ).copyWith(
        location: "Ev",
        activity: "Evde",
      );
    }).toList();

    // 2. İlk state kurulumu (Koltuklar dahil)
    final initialState = GameStateData(
      gameTime: DateTime(2025, 1, 1, 9, 30),
      isShopOpen: false,
      dayCount: 1,
      characters: allInitialCharacters,
      terraceSlots: List.generate(13, (i) => SeatSlot(id: i, locationName: "Teras ${i+1}", type: SeatType.terrace)),
      bigTableSlots: List.generate(5, (i) => SeatSlot(id: 100+i, locationName: "Büyük Masa ${i+1}", type: SeatType.bigTable)),
      salonSlots: List.generate(7, (i) => SeatSlot(id: 200+i, locationName: "Salon ${i+1}", type: SeatType.regularTable)),
    );

    // Kayıtlı verileri yükle
    Future.microtask(() => _loadAllData()); 

    return initialState;
  }

  // --- ZAMANLAYICI VE ANA DÖNGÜ ---
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _tick());
  }

  void _tick() {
    final oldTime = state.gameTime;
    DateTime newTime = oldTime.add(const Duration(minutes: 1)); // 1 saniye = 1 dakika
    int currentDay = state.dayCount;

    // State kopyalarını oluştur
    List<Character> chars = [...state.characters];
    List<SeatSlot> tSlots = [...state.terraceSlots];
    List<SeatSlot> bSlots = [...state.bigTableSlots];
    List<SeatSlot> sSlots = [...state.salonSlots];

    // --- GÜN SONU SIÇRAMASI (23:00) ---
    if (newTime.hour == 23 && newTime.minute == 0) {
      _saveAllData(); 
      currentDay++; 
      
      // Herkesi temizle ve eve gönder
      _clearShopForNextDay(chars, tSlots, bSlots, sSlots);
      
      newTime = DateTime(newTime.year, newTime.month, newTime.day)
          .add(const Duration(days: 1, hours: 9, minutes: 30));
    }

    bool isOpen = newTime.hour >= 10 && newTime.hour < 23;

    // --- SİSTEMLERİN ÇALIŞTIRILMASI ---
    _handleRoutines(chars, newTime); // Barista hareketleri

    if (isOpen) {
      _handleSpawning(chars, newTime); // Müdavimlerin gelmesi
      _handleOrdersAI(chars, newTime); // Müdavimlerin sipariş vermesi
      
      // Rastgele Müşteri Gelişi (Koltuklara)
      if (_rng.nextInt(100) < 4) { 
        _spawnGenericCustomer(tSlots, bSlots, sSlots, newTime);
      }
    } else {
      // Dükkan yeni kapandıysa herkesi kov (Koltuklar)
      if (state.isShopOpen && !isOpen) {
        _clearGenericCustomers(tSlots, bSlots, sSlots);
      }
    }

    _handleCirculationAI(chars, newTime); // Müdavimlerin gitmesi
    _handleProcessCompletions(chars, newTime); // İş/Hazırlık bitişleri
    _updateGenericDurations(tSlots, bSlots, sSlots); // Koltuk müşterilerinin süreleri

    // State'i güncelle
    state = state.copyWith(
      gameTime: newTime,
      isShopOpen: isOpen,
      characters: chars,
      dayCount: currentDay,
      terraceSlots: tSlots,
      bigTableSlots: bSlots,
      salonSlots: sSlots,
    );
  }

  // --- MÜDAVİM MANTIĞI (PERSONA AI) ---
  void _handleRoutines(List<Character> chars, DateTime now) {
    int erenIdx = chars.indexWhere((c) => c.id == 'eren');
    if (erenIdx != -1) {
      if (now.hour == 9 && now.minute >= 30 && !chars[erenIdx].isPresent) {
        chars[erenIdx] = chars[erenIdx].copyWith(
          isPresent: true, 
          location: "Mutfak", 
          activity: "Tezgahı siliyor... 🧹"
        );
      }
      if (now.hour >= 10 && chars[erenIdx].location == "Mutfak") {
        chars[erenIdx] = chars[erenIdx].copyWith(
          location: "Bar Arkası", 
          activity: "Sipariş Bekliyor"
        );
      }
    }
  }

  void _handleSpawning(List<Character> chars, DateTime now) {
    int currentInShop = chars.where((c) => c.isPresent && !c.isBarista).length;
    if (currentInShop < 6 && _rng.nextInt(100) < 8) {
      final candidates = chars.where((c) => !c.isPresent && !c.isBarista).toList();
      if (candidates.isNotEmpty) {
        final target = candidates[_rng.nextInt(candidates.length)];
        int idx = chars.indexWhere((c) => c.id == target.id);
        int stayMinutes = 45 + _rng.nextInt(180);
        chars[idx] = chars[idx].copyWith(
          isPresent: true,
          location: "Masa",
          activity: "Dükkana girdi...",
          arrivalTime: now,
          departureTime: now.add(Duration(minutes: stayMinutes)),
        );
      }
    }
  }

  void _handleOrdersAI(List<Character> chars, DateTime now) {
    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];
      if (!c.isPresent || c.isBarista || c.activeOrder != null || c.activeActivity != null) continue;

      bool wantsToOrder = false;
      if (c.lastOrderTime == null) {
        if (c.arrivalTime != null && now.difference(c.arrivalTime!).inMinutes > 15) wantsToOrder = true;
      } else {
        if (now.difference(c.lastOrderTime!).inMinutes >= 90) wantsToOrder = true;
      }

      if (wantsToOrder && _rng.nextInt(100) < 10) {
        chars[i] = _triggerNewOrder(c, now);
      }
    }
  }

  void _handleCirculationAI(List<Character> chars, DateTime now) {
    for (int i = 0; i < chars.length; i++) {
      if (!chars[i].isPresent || chars[i].isBarista) continue;
      bool isTimeUp = chars[i].departureTime != null && now.isAfter(chars[i].departureTime!);
      bool isIdle = chars[i].activeOrder == null && chars[i].activeActivity == null;

      if (isTimeUp && isIdle) {
        chars[i] = chars[i].copyWith(
          isPresent: false, 
          location: "Ev", 
          activity: "Eve döndü 🏡", 
          clearOrder: true, 
          clearActivity: true
        );
      }
    }
  }

  void _handleProcessCompletions(List<Character> chars, DateTime now) {
    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];
      // Barista Sipariş Hazırlama Bitişi
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
      // Laptop/Kitap Aktivite Bitişi
      if (c.activityFinishTime != null && now.isAfter(c.activityFinishTime!)) {
        final preset = allPresets.firstWhere((p) => p.name == c.name);
        final m = preset.multipliers[c.activeActivity!.type] ?? {'xp': 30, 'happiness': 0.05};
        chars[i] = _applyXp(c, m['xp']?.toInt() ?? 30).copyWith(
          activity: "İşini bitirdi ✅",
          happiness: (c.happiness + (m['happiness'] ?? 0.05)).clamp(0.0, 1.0),
          success: (c.success + (m['success'] ?? 0.02)).clamp(0.0, 1.0),
          clearActivity: true,
        );
      }
    }
  }

  // --- GENEL MÜŞTERİ MANTIĞI (KOLTUKLAR) ---
  void _spawnGenericCustomer(List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s, DateTime now) {
    List<SeatSlot> allEmpty = [...t, ...b, ...s].where((slot) => slot.customer == null).toList();
    if (allEmpty.isEmpty) return;

    SeatSlot target = allEmpty[_rng.nextInt(allEmpty.length)];
    bool isBig = target.type == SeatType.bigTable;
    
    Customer newCustomer = Customer(
      id: "gen_${now.millisecondsSinceEpoch}_${_rng.nextInt(100)}",
      name: "Müşteri ${_rng.nextInt(999)}",
      durationMinutes: isBig ? 120 + _rng.nextInt(120) : 20 + _rng.nextInt(40),
      lookingFor: ["Kahve", "Çay", "Latte"][_rng.nextInt(3)],
      state: ActivityState.ordering,
    );

    _updateSlotInList(target.id, newCustomer, t, b, s);
  }

  void _updateGenericDurations(List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s) {
    for (var list in [t, b, s]) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].customer != null) {
          Customer c = list[i].customer!;
          int timeLeft = c.durationMinutes - 1;
          if (timeLeft <= 0) {
            list[i] = list[i].copyWith(clearCustomer: true);
          } else {
            list[i] = list[i].copyWith(customer: c.copyWith(durationMinutes: timeLeft));
          }
        }
      }
    }
  }

  // --- ETKİLEŞİM FONKSİYONLARI ---
  void giveItemToCharacter(String charId, GameItem item) {
    List<Character> updated = [...state.characters];
    int idx = updated.indexWhere((c) => c.id == charId);
    if (idx == -1) return;

    Character target = updated[idx];
    final preset = allPresets.firstWhere((p) => p.name == target.name);

    if (item.type == ItemType.laptop || item.type == ItemType.book) {
      if (target.activeActivity != null) return;
      updated[idx] = target.copyWith(
        activity: preset.activityTexts[item.type] ?? "Meşgul...",
        activityFinishTime: state.gameTime.add(Duration(minutes: item.type == ItemType.laptop ? 60 : 30)),
        activeActivity: item.copyWith(orderStatus: OrderStatus.processing),
      );
    } else {
      // Baristaya sipariş ver
      if (target.isBarista && item.orderStatus == OrderStatus.pending && target.activeOrder == null) {
        updated[idx] = target.copyWith(
          activeOrder: item.copyWith(orderStatus: OrderStatus.preparing),
          activity: "${item.name} hazırlıyor...",
          orderFinishTime: state.gameTime.add(const Duration(minutes: 5)),
        );
        // Müşteriyi bekleme moduna al
        int cIdx = updated.indexWhere((c) => c.id == item.relatedCustomerId);
        if (cIdx != -1) updated[cIdx] = updated[cIdx].copyWith(activity: "Bekliyor...", activeOrder: item.copyWith(orderStatus: OrderStatus.processing));
      } 
      // Müşteriye hazır kahveyi ver
      else if (item.relatedCustomerId == target.id && item.orderStatus == OrderStatus.ready) {
        updated[idx] = _applyXp(target, 50).copyWith(
          clearOrder: true,
          activity: "Kahvesini içiyor ☕",
          lastOrderTime: state.gameTime,
          happiness: (target.happiness + 0.1).clamp(0.0, 1.0),
        );
        // Baristayı boşa çıkar
        int bIdx = updated.indexWhere((c) => c.isBarista);
        if (bIdx != -1) updated[bIdx] = updated[bIdx].copyWith(clearOrder: true, activity: "Sipariş Bekliyor");
      }
    }
    state = state.copyWith(characters: updated);
  }

  // --- YARDIMCI METODLAR ---
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

  Character _applyXp(Character c, int amount) {
    int newXp = c.currentXp + amount;
    int newLevel = c.level;
    while (newXp >= c.requiredXpForNextLevel) {
      newXp -= c.requiredXpForNextLevel;
      newLevel++;
    }
    return c.copyWith(currentXp: newXp, level: newLevel);
  }

  void _clearShopForNextDay(List<Character> c, List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s) {
    for (int i = 0; i < c.length; i++) {
      c[i] = c[i].copyWith(isPresent: false, location: "Ev", activity: "Uyuyor", clearOrder: true, clearActivity: true);
    }
    _clearGenericCustomers(t, b, s);
  }

  void _clearGenericCustomers(List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s) {
    for (int i = 0; i < t.length; i++) t[i] = t[i].copyWith(clearCustomer: true);
    for (int i = 0; i < b.length; i++) b[i] = b[i].copyWith(clearCustomer: true);
    for (int i = 0; i < s.length; i++) s[i] = s[i].copyWith(clearCustomer: true);
  }

  void _updateSlotInList(int id, Customer? c, List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s) {
    int idx = t.indexWhere((s) => s.id == id);
    if (idx != -1) { t[idx] = t[idx].copyWith(customer: c); return; }
    idx = b.indexWhere((s) => s.id == id);
    if (idx != -1) { b[idx] = b[idx].copyWith(customer: c); return; }
    idx = s.indexWhere((s) => s.id == id);
    if (idx != -1) { s[idx] = s[idx].copyWith(customer: c); }
  }

  // --- VERİ KAYIT / YÜKLEME ---
  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final charProgress = state.characters.map((c) => c.toJson()).toList();
    await prefs.setString('saved_character_progress', jsonEncode(charProgress));
    await prefs.setInt('game_day_count', state.dayCount);
  }

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
}

final gameProvider = NotifierProvider<GameNotifier, GameStateData>(() => GameNotifier());