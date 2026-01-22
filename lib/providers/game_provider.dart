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

    // --- BARISTA ROUTINE ---
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

    // --- CUSTOMER CIRCULATION ---
    if (isOpen) {
      // Spawn Customers
      int currentCustomers = chars.where((c) => c.id.startsWith('musteri')).length;
      if (currentCustomers < 5 && _rng.nextInt(100) < 5) {
        _spawnCustomer(chars, newTime);
      }

      // Random arrival for main characters
      int cinarIdx = chars.indexWhere((c) => c.id == 'cinar');
      if (cinarIdx != -1 && !chars[cinarIdx].isPresent && _rng.nextInt(100) < 2) {
        // Main characters stay until close or a random long duration
        DateTime depart = newTime.add(Duration(minutes: 120 + _rng.nextInt(240)));
        chars[cinarIdx] = chars[cinarIdx].copyWith(
          isPresent: true,
          location: "Giriş",
          activity: "Selam Veriyor 👋",
          departureTime: depart,
        );
      }
    }

    // --- CHECK DEPARTURES AND TASKS ---
    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];

      // Handle Departure (Except the Barista during work hours)
      if (c.isPresent && !c.isBarista && c.departureTime != null && newTime.isAfter(c.departureTime!)) {
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
          );
        }
      }

      // Handle Task Completion
      if (c.orderFinishTime != null && newTime.isAfter(c.orderFinishTime!)) {
        if (c.isBarista && c.activeOrder?.orderStatus == OrderStatus.preparing) {
          chars[i] = c.copyWith(
            activeOrder: c.activeOrder!.copyWith(orderStatus: OrderStatus.ready),
            activity: "Servis Hazır! 🔔",
            orderFinishTime: null,
          );
        } else if (c.activity.contains("Kitap")) {
          chars[i] = c.copyWith(
            activity: "Kitabı Bitirdi 🧠",
            happiness: (c.happiness + 0.2).clamp(0.0, 1.0),
            currentXp: c.currentXp + 30,
            clearOrder: true,
          );
        } else if (c.activity.contains("Kod")) {
          // Specific stats for Çınar vs others can be handled here
          double successIncr = c.id == 'cinar' ? 0.2 : 0.1;
          chars[i] = c.copyWith(
            activity: "Projeyi Tamamladı 💻",
            currentXp: c.currentXp + 60,
            success: (c.success + successIncr).clamp(0.0, 1.0),
            clearOrder: true,
          );
        }
      }
    }

    // --- CLOSING TIME ---
    if (newTime.hour == 23 && newTime.minute == 0) {
      chars.removeWhere((c) => c.id.startsWith('musteri'));
      for (int i = 0; i < chars.length; i++) {
        chars[i] = chars[i].copyWith(
          isPresent: false,
          location: "Ev",
          activity: "Dinleniyor",
          clearOrder: true,
        );
      }
    }

    state = state.copyWith(gameTime: newTime, isShopOpen: isOpen, characters: chars);
  }

  void _spawnCustomer(List<Character> list, DateTime currentTime) {
    List<ItemType> drinks = [ItemType.filterCoffee, ItemType.latte, ItemType.espresso, ItemType.herbalTea];
    ItemType wanted = drinks[_rng.nextInt(drinks.length)];
    String custId = "musteri_${_customerCounter++}";

    // Random stay duration: 15 mins to 5 hours (300 mins)
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
      name: "Müşteri $_customerCounter",
      description: "Kahve içmeye gelmiş bir misafir.",
      imagePath: 'assets/cinar.png',
      title: 'Misafir',
      isPresent: true,
      location: "Masa",
      activity: "Sipariş Bekliyor",
      activeOrder: order,
      departureTime: departAt,
    ));
  }

  void giveItemToCharacter(String charId, GameItem item) {
    List<Character> updatedChars = [...state.characters];
    int idx = updatedChars.indexWhere((c) => c.id == charId);
    if (idx == -1) return;
    Character target = updatedChars[idx];

    // Barista Take Order
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
    // Customer Delivery
    else if (item.relatedCustomerId == target.id && item.orderStatus == OrderStatus.ready) {
      updatedChars[idx] = target.copyWith(
        clearOrder: true,
        activity: "Keyif Yapıyor ☕",
        currentXp: target.currentXp + 50,
        happiness: (target.happiness + 0.3).clamp(0.0, 1.0),
      );
      int bIdx = updatedChars.indexWhere((c) => c.isBarista && c.activeOrder?.id == item.id);
      if (bIdx != -1) {
        updatedChars[bIdx] = updatedChars[bIdx].copyWith(
          clearOrder: true,
          activity: "Sipariş Bekliyor",
        );
      }
    }
    // Start Activities (Laptop / Book)
    else if (item.type == ItemType.laptop || item.type == ItemType.book) {
      if (target.activeOrder != null) return;
      int duration = item.type == ItemType.laptop ? 120 : 60;

      String activityText = "";
      if (item.type == ItemType.laptop) {
        activityText = target.id == 'eren' ? "Openfront oynuyor! 🎮" : "Kod Yazıyor...";
      } else {
        activityText = "Kitap Okuyor...";
      }

      updatedChars[idx] = target.copyWith(
        activity: activityText,
        orderFinishTime: state.gameTime.add(Duration(minutes: duration)),
        activeOrder: item.copyWith(
          id: "act_${_rng.nextInt(999)}",
          orderStatus: OrderStatus.processing,
        ),
      );
    }

    state = state.copyWith(characters: updatedChars);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameStateData>(() => GameNotifier());