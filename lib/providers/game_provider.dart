import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../models/game_item.dart';

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
    return GameStateData(
      gameTime: DateTime(2025, 1, 1, 9, 30),
      isShopOpen: false,
      characters: [
        Character(
          id: 'eren',
          name: 'Eren',
          description: 'Dükkanın ruhu, gamer barista.',
          imagePath: 'assets/eren.png',
          title: 'Barista',
          isBarista: true,
          isPresent: false,
          location: "Ev",
          activity: "Uyanıyor...",
        ),
        Character(
          id: 'cinar',
          name: 'Çınar',
          description: 'Depresif ama dahi bir yazılımcı.',
          imagePath: 'assets/cinar.png',
          title: 'Müdavim',
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

    // --- MÜŞTERİ SİRKÜLASYONU ---
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
    }

    // --- AYRILMA VE GÖREV KONTROLLERİ ---
    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];

      // Müşterinin ayrılması için hem sipariş hem aktivite yuvası boş olmalı
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

      // Sipariş Hazırlanma Tamamlanması (Barista için)
      if (c.orderFinishTime != null && newTime.isAfter(c.orderFinishTime!)) {
        if (c.isBarista && c.activeOrder?.orderStatus == OrderStatus.preparing) {
          chars[i] = c.copyWith(
            activeOrder: c.activeOrder!.copyWith(orderStatus: OrderStatus.ready),
            activity: "Servis Hazır! 🔔",
            orderFinishTime: null,
          );
        }
      }

      // Aktivite Tamamlanması (Kitap/Laptop)
      if (c.activityFinishTime != null && newTime.isAfter(c.activityFinishTime!)) {
        if (c.activeActivity?.type == ItemType.book) {
          chars[i] = c.copyWith(
            activity: "Kitabı Bitirdi 🧠",
            happiness: (c.happiness + 0.2).clamp(0.0, 1.0),
            currentXp: c.currentXp + 30,
            clearActivity: true,
          );
        } else if (c.activeActivity?.type == ItemType.laptop) {
          double successIncr = c.id == 'cinar' ? 0.2 : 0.1;
          chars[i] = c.copyWith(
            activity: "Projeyi Tamamladı 💻",
            currentXp: c.currentXp + 60,
            success: (c.success + successIncr).clamp(0.0, 1.0),
            clearActivity: true,
          );
        }
      }
    }

    // --- KAPANIŞ ---
    if (newTime.hour == 23 && newTime.minute == 0) {
      chars.removeWhere((c) => c.id.startsWith('musteri'));
      for (int i = 0; i < chars.length; i++) {
        chars[i] = chars[i].copyWith(
          isPresent: false,
          location: "Ev",
          activity: "Dinleniyor",
          clearOrder: true,
          clearActivity: true,
        );
      }
    }

    state = state.copyWith(gameTime: newTime, isShopOpen: isOpen, characters: chars);
  }

  void _spawnCustomer(List<Character> list, DateTime currentTime) {
    List<ItemType> drinks = [ItemType.filterCoffee, ItemType.latte, ItemType.espresso, ItemType.herbalTea];
    ItemType wanted = drinks[_rng.nextInt(drinks.length)];
    String custId = "musteri_$_customerCounter";
    _customerCounter++;

    int stayDuration = 15 + _rng.nextInt(285);
    DateTime departAt = currentTime.add(Duration(minutes: stayDuration));

    GameItem order = GameItem(
      id: "ord_${currentTime.millisecondsSinceEpoch}",
      name: wanted.name,
      type: wanted,
      relatedCustomerId: custId,
      orderStatus: OrderStatus.pending,
    );

    list.add(Character(
      id: custId,
      name: "Müşteri ${_customerCounter - 1}",
      description: "Kahve içmeye gelmiş bir misafir.",
      imagePath: 'assets/cinar.png',
      title: 'Misafir',
      isPresent: true,
      location: "Masa",
      activity: "Sipariş Bekliyor",
      activeOrder: order,
      arrivalTime: currentTime, // Gecikme uyarısı için giriş saati
      departureTime: departAt,
    ));
  }

  void giveItemToCharacter(String charId, GameItem item) {
    List<Character> updatedChars = [...state.characters];
    int idx = updatedChars.indexWhere((c) => c.id == charId);
    if (idx == -1) return;
    Character target = updatedChars[idx];

    // EŞYA TÜRÜNE GÖRE MANTIK (Sipariş vs Aktivite)
    if (item.type != ItemType.laptop && item.type != ItemType.book) {
      // Barista Sipariş Alımı
      if (target.isBarista && item.orderStatus == OrderStatus.pending) {
        if (target.activeOrder != null) return;
        updatedChars[idx] = target.copyWith(
          activeOrder: item.copyWith(orderStatus: OrderStatus.preparing),
          activity: "${item.name} Yapıyor...",
          orderFinishTime: state.gameTime.add(const Duration(minutes: 15)),
          currentXp: target.currentXp + 10,
        );
        int cIdx = updatedChars.indexWhere((c) => c.id == item.relatedCustomerId);
        if (cIdx != -1) {
          updatedChars[cIdx] = updatedChars[cIdx].copyWith(
            activeOrder: item.copyWith(orderStatus: OrderStatus.processing),
            activity: "Bekliyor...",
          );
        }
      }
      // Müşteriye Teslimat
      else if (item.relatedCustomerId == target.id && item.orderStatus == OrderStatus.ready) {
        updatedChars[idx] = target.copyWith(
          clearOrder: true,
          activity: "Keyif Yapıyor ☕",
          currentXp: target.currentXp + 50,
          happiness: (target.happiness + 0.3).clamp(0.0, 1.0),
          // Kahve tesliminden sonra kalış süresini uzat
          departureTime: state.gameTime.add(const Duration(minutes: 30)),
        );
        int bIdx = updatedChars.indexWhere((c) => c.isBarista && c.activeOrder?.id == item.id);
        if (bIdx != -1) {
          updatedChars[bIdx] = updatedChars[bIdx].copyWith(
            clearOrder: true,
            activity: "Sipariş Bekliyor",
          );
        }
      }
    } 
    // AKTİVİTE BAŞLATMA (Laptop / Kitap)
    else if (item.type == ItemType.laptop || item.type == ItemType.book) {
      if (target.activeActivity != null) return; // Zaten bir aktivite yapıyorsa ikincisini alamaz

      int duration = item.type == ItemType.laptop ? 120 : 60;
      String activityText = (item.type == ItemType.laptop)
          ? (target.id == 'eren' ? "Openfront oynuyor! 🎮" : "Kod Yazıyor...")
          : "Kitap Okuyor...";

      updatedChars[idx] = target.copyWith(
        activity: activityText,
        activityFinishTime: state.gameTime.add(Duration(minutes: duration)),
        activeActivity: item.copyWith(
          id: "act_${_rng.nextInt(999)}",
          orderStatus: OrderStatus.processing,
        ),
      );
    }

    state = state.copyWith(characters: updatedChars);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameStateData>(() => GameNotifier());