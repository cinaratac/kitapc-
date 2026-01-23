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
  final int totalBalance;
  final int dayCount;
  final bool showDaySummary; // Gün sonu ekranı kontrolü

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

    final initialState = GameStateData(
      gameTime: DateTime(2025, 1, 1, 9, 30),
      isShopOpen: false,
      dayCount: 1,
      characters: allInitialCharacters,
      terraceSlots: List.generate(13, (i) => SeatSlot(id: i, locationName: "Teras ${i+1}", type: SeatType.terrace)),
      bigTableSlots: List.generate(5, (i) => SeatSlot(id: 100+i, locationName: "Büyük Masa ${i+1}", type: SeatType.bigTable)),
      salonSlots: List.generate(7, (i) => SeatSlot(id: 200+i, locationName: "Salon ${i+1}", type: SeatType.regularTable)),
    );

    Future.microtask(() => _loadAllData());
    return initialState;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _tick());
  }

  void _tick() {
    // EĞER ÖZET EKRANI VARSA ZAMAN AKMAZ
    if (state.showDaySummary) return;

    final oldTime = state.gameTime;
    DateTime newTime = oldTime.add(const Duration(minutes: 1));

    List<Character> chars = [...state.characters];
    List<SeatSlot> tSlots = [...state.terraceSlots];
    List<SeatSlot> bSlots = [...state.bigTableSlots];
    List<SeatSlot> sSlots = [...state.salonSlots];

    // GÜN SONU KONTROLÜ (23:00)
    if (newTime.hour == 23 && newTime.minute == 0) {
      _saveAllData();
      state = state.copyWith(showDaySummary: true);
      return;
    }

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

  // --- YENİ GÜNE BAŞLAMA MANTIĞI ---
  void startNextDay() {
    List<Character> chars = [...state.characters];
    List<SeatSlot> tSlots = [...state.terraceSlots];
    List<SeatSlot> bSlots = [...state.bigTableSlots];
    List<SeatSlot> sSlots = [...state.salonSlots];

    // Bir sonraki güne geç ve saati 09:30 yap
    DateTime nextDay = DateTime(state.gameTime.year, state.gameTime.month, state.gameTime.day)
        .add(const Duration(days: 1, hours: 9, minutes: 30));

    _clearShopForNextDay(chars, tSlots, bSlots, sSlots);

    state = state.copyWith(
      gameTime: nextDay,
      dayCount: state.dayCount + 1,
      dailyRevenue: 0,
      showDaySummary: false,
      characters: chars,
      terraceSlots: tSlots,
      bigTableSlots: bSlots,
      salonSlots: sSlots,
    );
  }

  // --- EKONOMİ VE SİPARİŞ MANTIĞI ---
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

        state = state.copyWith(
          dailyRevenue: state.dailyRevenue + 50,
          totalBalance: state.totalBalance + 50,
          terraceSlots: t, bigTableSlots: b, salonSlots: s,
        );
      }
    }
  }

  // --- MÜDAVİM YAPAY ZEKASI ---
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
        chars[idx] = chars[idx].copyWith(
          isPresent: true, location: "Masa", activity: "Dükkana girdi...",
          arrivalTime: now, departureTime: now.add(Duration(minutes: 45 + _rng.nextInt(180))),
        );
      }
    }
  }

  void _handleOrdersAI(List<Character> chars, DateTime now) {
    int currentOrdersCount = chars.where((c) => c.activeOrder != null).length;
    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];
      if (!c.isPresent || c.isBarista || c.activeOrder != null || c.activeActivity != null || c.socializingWith != null) continue;
      if (currentOrdersCount >= 3) break;
      if ((c.lastOrderTime == null && c.arrivalTime != null && now.difference(c.arrivalTime!).inMinutes > 15) ||
          (c.lastOrderTime != null && now.difference(c.lastOrderTime!).inMinutes >= 90)) {
        if (_rng.nextInt(100) < 10) {
          chars[i] = _triggerNewOrder(c, now);
          currentOrdersCount++;
        }
      }
    }
  }

  void _handleCirculationAI(List<Character> chars, DateTime now) {
    for (int i = 0; i < chars.length; i++) {
      if (!chars[i].isPresent || chars[i].isBarista) continue;
      bool isDepartureTime = chars[i].departureTime != null && now.isAfter(chars[i].departureTime!);
      bool isBusy = chars[i].socializingWith != null || chars[i].activeOrder != null || chars[i].activeActivity != null;
      if (isDepartureTime && !isBusy) {
        chars[i] = chars[i].copyWith(isPresent: false, location: "Ev", activity: "Eve döndü 🏡", clearOrder: true, clearActivity: true, clearSocial: true);
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
            activity: "Servis Hazır! 🔔", orderFinishTime: null,
          );
        }
      }
      if (c.activityFinishTime != null && now.isAfter(c.activityFinishTime!)) {
        if (c.socializingWith != null) {
          _finishSocializing(chars, i);
        } else if (c.activeActivity != null) {
          final preset = allPresets.firstWhere((p) => p.name == c.name);
          final m = preset.multipliers[c.activeActivity!.type] ?? {'xp': 30, 'happiness': 0.05};
          chars[i] = _applyXp(c, (m['xp'] as num).toInt()).copyWith(
            activity: "İşini bitirdi ✅", happiness: (c.happiness + (m['happiness'] as num)).clamp(0.0, 1.0),
            success: (c.success + (m['success'] as num? ?? 0.02)).clamp(0.0, 1.0),
            clearActivity: true, activityFinishTime: null,
          );
        }
      }
    }
  }

  // --- SOSYALLEŞME SİSTEMİ ---
  void startSocializing(String char1Id, String char2Id) {
    if (char1Id == char2Id) return;
    List<Character> updated = [...state.characters];
    int idx1 = updated.indexWhere((c) => c.id == char1Id);
    int idx2 = updated.indexWhere((c) => c.id == char2Id);

    if (idx1 != -1 && idx2 != -1) {
      if (updated[idx1].socializingWith != null || updated[idx2].socializingWith != null) return;
      if (updated[idx1].isPresent && updated[idx2].isPresent) {
        final finishTime = state.gameTime.add(const Duration(minutes: 30));
        updated[idx1] = updated[idx1].copyWith(socializingWith: char2Id, activity: "${updated[idx2].name} ile sohbet ediyor... 💬", activityFinishTime: finishTime);
        updated[idx2] = updated[idx2].copyWith(socializingWith: char1Id, activity: "${updated[idx1].name} ile sohbet ediyor... 💬", activityFinishTime: finishTime);
        state = state.copyWith(characters: updated);
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

  // --- ETKİLEŞİMLER (Eşya Verme) ---
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
      state = state.copyWith(characters: updated);
    } else {
      if (target.isBarista && item.orderStatus == OrderStatus.pending && target.activeOrder == null) {
        updated[idx] = target.copyWith(activeOrder: item.copyWith(orderStatus: OrderStatus.preparing), activity: "${item.name} hazırlıyor...", orderFinishTime: state.gameTime.add(const Duration(minutes: 5)));
        int cIdx = updated.indexWhere((c) => c.id == item.relatedCustomerId);
        if (cIdx != -1) updated[cIdx] = updated[cIdx].copyWith(activity: "Bekliyor...", activeOrder: item.copyWith(orderStatus: OrderStatus.processing));
        state = state.copyWith(characters: updated);
      } else if (item.relatedCustomerId == target.id && item.orderStatus == OrderStatus.ready) {
        updated[idx] = _applyXp(target, 50).copyWith(clearOrder: true, activity: "Kahvesini içiyor ☕", lastOrderTime: state.gameTime, happiness: (target.happiness + 0.1).clamp(0.0, 1.0));
        int bIdx = updated.indexWhere((c) => c.isBarista);
        if (bIdx != -1) updated[bIdx] = updated[bIdx].copyWith(clearOrder: true, activity: "Sipariş Bekliyor");
        state = state.copyWith(characters: updated, totalBalance: state.totalBalance + 60, dailyRevenue: state.dailyRevenue + 60);
      }
    }
  }

  // --- YARDIMCI METOTLAR ---
  void _updateSlotInList(int id, Customer? c, List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s) {
    int idx = t.indexWhere((s) => s.id == id);
    if (idx != -1) { t[idx] = t[idx].copyWith(customer: c); return; }
    idx = b.indexWhere((s) => s.id == id);
    if (idx != -1) { b[idx] = b[idx].copyWith(customer: c); return; }
    idx = s.indexWhere((s) => s.id == id);
    if (idx != -1) { s[idx] = s[idx].copyWith(customer: c); }
  }

  void _spawnGenericCustomer(List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s, DateTime now) {
    List<SeatSlot> allEmpty = [...t, ...b, ...s].where((slot) => slot.customer == null).toList();
    if (allEmpty.isEmpty) return;
    SeatSlot target = allEmpty[_rng.nextInt(allEmpty.length)];
    Customer newCustomer = Customer(id: "gen_${now.millisecondsSinceEpoch}", name: "Müşteri ${_rng.nextInt(999)}", durationMinutes: target.type == SeatType.bigTable ? 120 + _rng.nextInt(120) : 20 + _rng.nextInt(40), lookingFor: ["Kahve", "Çay", "Latte"][_rng.nextInt(3)], state: ActivityState.ordering);
    _updateSlotInList(target.id, newCustomer, t, b, s);
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

  Character _triggerNewOrder(Character c, DateTime now) {
    final pick = [{'name': 'Filtre Kahve', 'type': ItemType.filterCoffee}, {'name': 'Latte', 'type': ItemType.latte}, {'name': 'Espresso', 'type': ItemType.espresso}, {'name': 'Bitki Çayı', 'type': ItemType.herbalTea}][_rng.nextInt(4)];
    return c.copyWith(activeOrder: GameItem(id: "ord_${now.millisecondsSinceEpoch}", name: pick['name'] as String, type: pick['type'] as ItemType, relatedCustomerId: c.id, orderStatus: OrderStatus.pending), activity: "Canı ${pick['name']} çekti!");
  }

  Character _applyXp(Character c, int amount) {
    int newXp = c.currentXp + amount;
    int newLevel = c.level;
    while (newXp >= c.requiredXpForNextLevel) { newXp -= c.requiredXpForNextLevel; newLevel++; }
    return c.copyWith(currentXp: newXp, level: newLevel);
  }

  void _clearShopForNextDay(List<Character> c, List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s) {
    for (int i = 0; i < c.length; i++) {
      c[i] = c[i].copyWith(isPresent: false, location: "Ev", activity: "Uyuyor", clearOrder: true, clearActivity: true, clearSocial: true);
    }
    _clearGenericCustomers(t, b, s);
  }

  void _clearGenericCustomers(List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s) {
    for (int i = 0; i < t.length; i++) t[i] = t[i].copyWith(clearCustomer: true);
    for (int i = 0; i < b.length; i++) b[i] = b[i].copyWith(clearCustomer: true);
    for (int i = 0; i < s.length; i++) s[i] = s[i].copyWith(clearCustomer: true);
  }

  // --- KAYIT VE YÜKLEME ---
  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_character_progress', jsonEncode(state.characters.map((c) => c.toJson()).toList()));
    await prefs.setInt('game_day_count', state.dayCount);
    await prefs.setInt('total_balance', state.totalBalance);
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCharsJson = prefs.getString('saved_character_progress');
    final savedBalance = prefs.getInt('total_balance') ?? 0;
    final savedDay = prefs.getInt('game_day_count') ?? 1;

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
    state = state.copyWith(dayCount: savedDay, characters: updatedChars, totalBalance: savedBalance);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameStateData>(() => GameNotifier());