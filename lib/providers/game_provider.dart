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
import '../data/activity_items_data.dart'; // Aktivite veri listesi

// --- OYUNUN TÜM DURUMUNU TAŞIYAN ANA SINIF ---
class GameStateData {
  final List<Character> characters;
  final DateTime gameTime;
  final bool isShopOpen;
  final int dailyRevenue;
  final int totalBalance;
  final int dayCount;
  final bool showDaySummary;
  final List<ItemType> unlockedActivityItems; // Satın alınan eşyaların listesi

  final List<SeatSlot> terraceSlots;
  final List<SeatSlot> bigTableSlots;
  final List<SeatSlot> salonSlots;

  GameStateData({
    required this.characters,
    required this.gameTime,
    required this.isShopOpen,
    this.totalBalance = 0,
    this.dayCount = 1,
    this.dailyRevenue = 0,
    this.showDaySummary = false,
    this.unlockedActivityItems = const [],
    required this.terraceSlots,
    required this.bigTableSlots,
    required this.salonSlots,
  });

  GameStateData copyWith({
    List<Character>? characters,
    DateTime? gameTime,
    int? totalBalance,
    bool? isShopOpen,
    int? dailyRevenue,
    int? dayCount,
    bool? showDaySummary,
    List<ItemType>? unlockedActivityItems,
    List<SeatSlot>? terraceSlots,
    List<SeatSlot>? bigTableSlots,
    List<SeatSlot>? salonSlots,
  }) {
    return GameStateData(
      characters: characters ?? this.characters,
      gameTime: gameTime ?? this.gameTime,
      isShopOpen: isShopOpen ?? this.isShopOpen,
      dailyRevenue: dailyRevenue ?? this.dailyRevenue,
      totalBalance: totalBalance ?? this.totalBalance,
      dayCount: dayCount ?? this.dayCount,
      showDaySummary: showDaySummary ?? this.showDaySummary,
      unlockedActivityItems: unlockedActivityItems ?? this.unlockedActivityItems,
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

    final allInitialCharacters = allPresets.map((preset) {
      return Character.fromPreset(
        preset,
        id: preset.name.toLowerCase(),
        isPresent: false,
      ).copyWith(
        location: "Ev",
        activity: "Evde",
      );
    }).toList();

    // Başlangıçta ücretsiz olan eşyaların (Kitap, Laptop vb.) listesini oluştur
    final initialUnlocked = allActivityItems
        .where((item) => item.isInitialUnlocked)
        .map((item) => item.type)
        .toList();

    final initialState = GameStateData(
      gameTime: DateTime(2025, 1, 1, 9, 30),
      isShopOpen: false,
      dayCount: 1,
      characters: allInitialCharacters,
      unlockedActivityItems: initialUnlocked,
      terraceSlots: List.generate(13, (i) => SeatSlot(id: i, locationName: "Teras ${i+1}", type: SeatType.terrace)),
      bigTableSlots: List.generate(5, (i) => SeatSlot(id: 100+i, locationName: "Büyük Masa ${i+1}", type: SeatType.bigTable)),
      salonSlots: List.generate(7, (i) => SeatSlot(id: 200+i, locationName: "Salon ${i+1}", type: SeatType.regularTable)),
    );

    // Kayıtlı verileri yükle
    Future.microtask(() => _loadAllData());
    return initialState;
  }

  // --- EŞYA SATIN ALMA VE KAYDETME ---
  void unlockItem(ActivityItem item) {
    if (state.totalBalance >= item.price && !state.unlockedActivityItems.contains(item.type)) {
      final newBalance = state.totalBalance - item.price;
      final newUnlockedList = [...state.unlockedActivityItems, item.type];

      state = state.copyWith(
        totalBalance: newBalance,
        unlockedActivityItems: newUnlockedList,
      );

      // Satın alma işleminden sonra hemen kalıcı belleğe kaydet
      _saveAllData();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _tick());
  }

  void _tick() {
    if (state.showDaySummary) return;

    final oldTime = state.gameTime;
    DateTime newTime = oldTime.add(const Duration(minutes: 1));

    List<Character> chars = [...state.characters];
    List<SeatSlot> tSlots = [...state.terraceSlots];
    List<SeatSlot> bSlots = [...state.bigTableSlots];
    List<SeatSlot> sSlots = [...state.salonSlots];

    if (newTime.hour == 23 && newTime.minute == 0) {
      _saveAllData();
      state = state.copyWith(showDaySummary: true);
      return;
    }

    _handleIndividualThoughts(chars, newTime);

    bool isOpen = newTime.hour >= 10 && newTime.hour < 23;

    _handleRoutines(chars, newTime);

    if (isOpen) {
      _handleSpawning(chars, newTime);
      _handleOrdersAI(chars, newTime);
      if (_rng.nextInt(100) < 4) {
        _spawnGenericCustomer(tSlots, bSlots, sSlots, newTime);
      }
    } else {
      if (state.isShopOpen && !isOpen) {
        _clearGenericCustomers(tSlots, bSlots, sSlots);
      }
    }

    _handleCirculationAI(chars, newTime);
    _handleProcessCompletions(chars, newTime);
    _updateGenericDurations(tSlots, bSlots, sSlots);

    state = state.copyWith(
      gameTime: newTime,
      isShopOpen: isOpen,
      characters: chars,
      terraceSlots: tSlots,
      bigTableSlots: bSlots,
      salonSlots: sSlots,
    );
  }

  // Karakterlere eşya verme mantığı (Gitar, Resim vb. dahil)
  void giveItemToCharacter(String charId, GameItem item) {
    List<Character> updated = [...state.characters];
    int idx = updated.indexWhere((c) => c.id == charId);
    if (idx == -1) return;
    
    Character target = updated[idx];
    final preset = allPresets.firstWhere((p) => p.name == target.name);

    // Aktivite eşyalarını kontrol et (Gitar, Kitap, Laptop, Resim Seti, Masa Oyunu)
    final activityItemDataList = allActivityItems.where((a) => a.type == item.type).toList();

    if (activityItemDataList.isNotEmpty) {
      // Karakter bir işle meşgulse veya sosyalleşiyorsa yeni eşya almasın
      if (target.activeActivity != null || target.socializingWith != null) return;
      
      final activityData = activityItemDataList.first;
      
      // ÖZEL TEPKİ KONTROLÜ: Karakterin o eşyaya özel bir yazısı var mı? Yoksa varsayılanı kullan.
      String activityText = preset.activityTexts[item.type] ?? activityData.defaultActivityText;

      updated[idx] = target.copyWith(
        activity: activityText,
        activityFinishTime: state.gameTime.add(Duration(minutes: activityData.durationMinutes)),
        activeActivity: item.copyWith(orderStatus: OrderStatus.processing),
        clearThought: true,
      );
      state = state.copyWith(characters: updated);
    } else {
      // Barista ve içecek mantığı (Kahve vb.)
      if (target.isBarista && item.orderStatus == OrderStatus.pending && target.activeOrder == null) {
        updated[idx] = target.copyWith(
          activeOrder: item.copyWith(orderStatus: OrderStatus.preparing), 
          activity: "${item.name} hazırlıyor...", 
          orderFinishTime: state.gameTime.add(const Duration(minutes: 5))
        );
        int cIdx = updated.indexWhere((c) => c.id == item.relatedCustomerId);
        if (cIdx != -1) updated[cIdx] = updated[cIdx].copyWith(activity: "Bekliyor...", activeOrder: item.copyWith(orderStatus: OrderStatus.processing), clearThought: true);
        state = state.copyWith(characters: updated);
      } else if (item.relatedCustomerId == target.id && item.orderStatus == OrderStatus.ready) {
        updated[idx] = _applyXp(target, 50).copyWith(clearOrder: true, activity: "Kahvesini içiyor ☕", lastOrderTime: state.gameTime, happiness: (target.happiness + 0.1).clamp(0.0, 1.0), clearThought: true);
        int bIdx = updated.indexWhere((c) => c.isBarista);
        if (bIdx != -1) updated[bIdx] = updated[bIdx].copyWith(clearOrder: true, activity: "Sipariş Bekliyor");
        state = state.copyWith(characters: updated, totalBalance: state.totalBalance + 60, dailyRevenue: state.dailyRevenue + 60);
      }
    }
  }

  // --- YARDIMCI AI VE SİSTEM METOTLARI ---

  void _handleIndividualThoughts(List<Character> chars, DateTime now) {
    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];
      if (!c.isPresent) continue;
      if (c.activeThought != null && c.lastThoughtTime != null) {
        if (now.difference(c.lastThoughtTime!).inMinutes >= 20) {
          chars[i] = chars[i].copyWith(clearThought: true);
        }
      }
      DateTime referenceTime = c.lastThoughtCheckTime ?? c.arrivalTime ?? now;
      if (now.difference(referenceTime).inMinutes >= 120) {
        chars[i] = chars[i].copyWith(lastThoughtCheckTime: now);
        if (_rng.nextInt(100) < 10) {
          final preset = allPresets.firstWhere((p) => p.name == c.name);
          if (preset.thoughts.isNotEmpty) {
            final randomThought = preset.thoughts[_rng.nextInt(preset.thoughts.length)];
            chars[i] = chars[i].copyWith(activeThought: randomThought, lastThoughtTime: now);
          }
        }
      }
    }
  }

  void startNextDay() {
    List<Character> chars = [...state.characters];
    List<SeatSlot> tSlots = [...state.terraceSlots];
    List<SeatSlot> bSlots = [...state.bigTableSlots];
    List<SeatSlot> sSlots = [...state.salonSlots];
    DateTime nextDay = DateTime(state.gameTime.year, state.gameTime.month, state.gameTime.day)
        .add(const Duration(days: 1, hours: 9, minutes: 30));
    _clearShopForNextDay(chars, tSlots, bSlots, sSlots);
    state = state.copyWith(gameTime: nextDay, dayCount: state.dayCount + 1, dailyRevenue: 0, showDaySummary: false, characters: chars, terraceSlots: tSlots, bigTableSlots: bSlots, salonSlots: sSlots);
  }

  void fulfillGenericOrder(int slotId, GameItem item) {
    List<SeatSlot> t = [...state.terraceSlots];
    List<SeatSlot> b = [...state.bigTableSlots];
    List<SeatSlot> s = [...state.salonSlots];
    SeatSlot? targetSlot;
    for (var list in [t, b, s]) {
      int idx = list.indexWhere((slot) => slot.id == slotId);
      if (idx != -1) { targetSlot = list[idx]; break; }
    }
    if (targetSlot != null && targetSlot.customer != null) {
      final customer = targetSlot.customer!;
      if (item.name.toLowerCase().contains(customer.lookingFor.toLowerCase()) || customer.lookingFor == "") {
        final updatedCustomer = customer.copyWith(state: ActivityState.consuming);
        _updateSlotInList(slotId, updatedCustomer, t, b, s);
        state = state.copyWith(dailyRevenue: state.dailyRevenue + 50, totalBalance: state.totalBalance + 50, terraceSlots: t, bigTableSlots: b, salonSlots: s);
      }
    }
  }

  void startSocializing(String char1Id, String char2Id) {
    if (char1Id == char2Id) return;
    List<Character> updated = [...state.characters];
    int idx1 = updated.indexWhere((c) => c.id == char1Id);
    int idx2 = updated.indexWhere((c) => c.id == char2Id);
    if (idx1 != -1 && idx2 != -1 && updated[idx1].socializingWith == null && updated[idx2].socializingWith == null) {
      final finishTime = state.gameTime.add(const Duration(minutes: 30));
      updated[idx1] = updated[idx1].copyWith(socializingWith: char2Id, activity: "${updated[idx2].name} ile sohbet ediyor... 💬", activityFinishTime: finishTime, clearThought: true);
      updated[idx2] = updated[idx2].copyWith(socializingWith: char1Id, activity: "${updated[idx1].name} ile sohbet ediyor... 💬", activityFinishTime: finishTime, clearThought: true);
      state = state.copyWith(characters: updated);
    }
  }

  void _spawnGenericCustomer(List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s, DateTime now) {
    List<SeatSlot> allEmpty = [...t, ...b, ...s].where((slot) => slot.customer == null).toList();
    if (allEmpty.isEmpty) return;
    SeatSlot target = allEmpty[_rng.nextInt(allEmpty.length)];
    Customer newCustomer = Customer(id: "gen_${now.millisecondsSinceEpoch}", name: "Müşteri ${_rng.nextInt(999)}", durationMinutes: target.type == SeatType.bigTable ? 120 + _rng.nextInt(120) : 20 + _rng.nextInt(40), lookingFor: ["Kahve", "Çay", "Latte"][_rng.nextInt(3)], state: ActivityState.ordering);
    _updateSlotInList(target.id, newCustomer, t, b, s);
  }

  void _updateSlotInList(int id, Customer? c, List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s) {
    int idx = t.indexWhere((s) => s.id == id);
    if (idx != -1) { t[idx] = t[idx].copyWith(customer: c); return; }
    idx = b.indexWhere((s) => s.id == id);
    if (idx != -1) { b[idx] = b[idx].copyWith(customer: c); return; }
    idx = s.indexWhere((s) => s.id == id);
    if (idx != -1) { s[idx] = s[idx].copyWith(customer: c); }
  }

  void _handleRoutines(List<Character> chars, DateTime now) {
    int erenIdx = chars.indexWhere((c) => c.id == 'eren');
    if (erenIdx != -1) {
      if (now.hour == 9 && now.minute >= 30 && !chars[erenIdx].isPresent) {
        chars[erenIdx] = chars[erenIdx].copyWith(isPresent: true, location: "Mutfak", activity: "Tezgahı siliyor... 🧹");
      }
      if (now.hour >= 10 && chars[erenIdx].location == "Mutfak") {
        chars[erenIdx] = chars[erenIdx].copyWith(location: "Bar Arkası", activity: "Sipariş Bekliyor");
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
        chars[idx] = chars[idx].copyWith(isPresent: true, location: "Masa", activity: "Dükkana girdi...", arrivalTime: now, departureTime: now.add(Duration(minutes: 45 + _rng.nextInt(180))));
      }
    }
  }

  void _handleOrdersAI(List<Character> chars, DateTime now) {
    int currentOrdersCount = chars.where((c) => c.activeOrder != null).length;
    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];
      if (!c.isPresent || c.isBarista || c.activeOrder != null || c.activeActivity != null || c.socializingWith != null) continue;
      if (currentOrdersCount >= 3) break;
      if ((c.lastOrderTime == null && c.arrivalTime != null && now.difference(c.arrivalTime!).inMinutes > 15) || (c.lastOrderTime != null && now.difference(c.lastOrderTime!).inMinutes >= 90)) {
        if (_rng.nextInt(100) < 10) { chars[i] = _triggerNewOrder(c, now); currentOrdersCount++; }
      }
    }
  }

  void _handleCirculationAI(List<Character> chars, DateTime now) {
    for (int i = 0; i < chars.length; i++) {
      if (!chars[i].isPresent || chars[i].isBarista) continue;
      bool isDepartureTime = chars[i].departureTime != null && now.isAfter(chars[i].departureTime!);
      bool isBusy = chars[i].socializingWith != null || chars[i].activeOrder != null || chars[i].activeActivity != null;
      if (isDepartureTime && !isBusy) {
        chars[i] = chars[i].copyWith(isPresent: false, location: "Ev", activity: "Eve döndü 🏡", clearOrder: true, clearActivity: true, clearSocial: true, clearThought: true);
      }
    }
  }

  void _handleProcessCompletions(List<Character> chars, DateTime now) {
    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];
      if (c.orderFinishTime != null && now.isAfter(c.orderFinishTime!)) {
        if (c.isBarista && c.activeOrder?.orderStatus == OrderStatus.preparing) {
          chars[i] = _applyXp(c, 40).copyWith(activeOrder: c.activeOrder!.copyWith(orderStatus: OrderStatus.ready), activity: "Servis Hazır! 🔔", orderFinishTime: null, clearOrderFinishTime: true);
        }
      }
      if (c.activityFinishTime != null && now.isAfter(c.activityFinishTime!)) {
        if (c.socializingWith != null) {
          _finishSocializing(chars, i);
        } else if (c.activeActivity != null) {
          final preset = allPresets.firstWhere((p) => p.name == c.name);
          final m = preset.multipliers[c.activeActivity!.type] ?? {};
          final num xpGain = m['xp'] ?? 30;
          final num happinessGain = m['happiness'] ?? 0.05;
          final num successGain = m['success'] ?? 0.02;
          chars[i] = _applyXp(c, xpGain.toInt()).copyWith(activity: "İşini bitirdi ✅", happiness: (c.happiness + happinessGain.toDouble()).clamp(0.0, 1.0), success: (c.success + successGain.toDouble()).clamp(0.0, 1.0), clearActivity: true, activityFinishTime: null, clearActivityFinishTime: true);
        }
      }
    }
  }

  void _finishSocializing(List<Character> chars, int idx) {
    final char = chars[idx];
    if (char.socializingWith == null) return;
    String partnerId = char.socializingWith!;
    Map<String, double> newRels = Map.from(char.relationships);
    newRels[partnerId] = ((newRels[partnerId] ?? 0.0) + 0.1).clamp(0.0, 1.0);
    chars[idx] = char.copyWith(relationships: newRels, activity: "Güzel bir sohbetti 😊", clearSocial: true, clearActivity: true, activityFinishTime: null);
  }

  void _updateGenericDurations(List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s) {
    for (var list in [t, b, s]) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].customer != null) {
          int timeLeft = list[i].customer!.durationMinutes - 1;
          list[i] = timeLeft <= 0 ? list[i].copyWith(clearCustomer: true) : list[i].copyWith(customer: list[i].customer!.copyWith(durationMinutes: timeLeft));
        }
      }
    }
  }

  void _clearGenericCustomers(List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s) {
    for (var list in [t, b, s]) {
      for (int i = 0; i < list.length; i++) list[i] = list[i].copyWith(clearCustomer: true);
    }
  }

  Character _triggerNewOrder(Character c, DateTime now) {
    final pick = [{'name': 'Filtre Kahve', 'type': ItemType.filterCoffee}, {'name': 'Latte', 'type': ItemType.latte}, {'name': 'Espresso', 'type': ItemType.espresso}, {'name': 'Bitki Çayı', 'type': ItemType.herbalTea}][_rng.nextInt(4)];
    return c.copyWith(activeOrder: GameItem(id: "ord_${now.millisecondsSinceEpoch}", name: pick['name'] as String, type: pick['type'] as ItemType, relatedCustomerId: c.id, orderStatus: OrderStatus.pending), activity: "Canı ${pick['name']} çekti!", clearThought: true);
  }

  Character _applyXp(Character c, int amount) {
    int newXp = c.currentXp + amount;
    int newLevel = c.level;
    while (newXp >= c.requiredXpForNextLevel) { newXp -= c.requiredXpForNextLevel; newLevel++; }
    return c.copyWith(currentXp: newXp, level: newLevel);
  }

  void _clearShopForNextDay(List<Character> c, List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s) {
    for (int i = 0; i < c.length; i++) {
      c[i] = c[i].copyWith(isPresent: false, location: "Ev", activity: "Uyuyor", clearOrder: true, clearActivity: true, clearSocial: true, clearThought: true);
    }
    _clearGenericCustomers(t, b, s);
  }

  // --- KAYIT VE YÜKLEME SİSTEMİ (KALICI HAFIZA) ---

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_character_progress', jsonEncode(state.characters.map((c) => c.toJson()).toList()));
    await prefs.setInt('game_day_count', state.dayCount);
    await prefs.setInt('total_balance', state.totalBalance);
    final unlockedStringList = state.unlockedActivityItems.map((e) => e.toString()).toList();
    await prefs.setString('unlocked_activity_items', jsonEncode(unlockedStringList));
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCharsJson = prefs.getString('saved_character_progress');
    final savedBalance = prefs.getInt('total_balance') ?? 0;
    final savedDay = prefs.getInt('game_day_count') ?? 1;
    final savedUnlockedJson = prefs.getString('unlocked_activity_items');

    List<Character> updatedChars = [...state.characters];
    if (savedCharsJson != null) {
      final List<dynamic> decoded = jsonDecode(savedCharsJson);
      for (var savedData in decoded) {
        int idx = updatedChars.indexWhere((c) => c.id == savedData['id']);
        if (idx != -1) {
          Map<String, double> loadedRels = {};
          if (savedData['relationships'] != null) {
            (savedData['relationships'] as Map<String, dynamic>).forEach((key, value) => loadedRels[key] = (value as num).toDouble());
          }
          updatedChars[idx] = updatedChars[idx].copyWith(
            level: savedData['level'], currentXp: savedData['currentXp'],
            happiness: savedData['happiness'], success: savedData['success'],
            love: savedData['love'], relationships: loadedRels,
          );
        }
      }
    }

    List<ItemType> loadedUnlocked = [...state.unlockedActivityItems];
    if (savedUnlockedJson != null) {
      final List<dynamic> decoded = jsonDecode(savedUnlockedJson);
      loadedUnlocked = decoded.map((s) => ItemType.values.firstWhere((e) => e.toString() == s)).toList();
    }

    state = state.copyWith(
      dayCount: savedDay, 
      characters: updatedChars, 
      totalBalance: savedBalance,
      unlockedActivityItems: loadedUnlocked,
    );
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameStateData>(() => GameNotifier());