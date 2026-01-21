import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../models/game_item.dart';

// OYUN DURUMU (STATE)
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
        Character(id: 'eren', name: 'Eren', imagePath: 'assets/eren.png', title: 'Barista', isBarista: true, isPresent: false, location: "Ev", activity: "Uyanıyor..."),
        Character(id: 'cinar', name: 'Çınar', imagePath: 'assets/cinar.png', title: 'Müdavim', isPresent: false, location: "Ev", activity: "Uyuyor"),
      ],
    );
  }

  void _startTimer() {
    // 1 Saniye = 1 Oyun Dakikası
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  void _tick() {
    DateTime newTime = state.gameTime.add(const Duration(minutes: 15));
    bool isOpen = newTime.hour >= 11 && newTime.hour < 23;
    List<Character> chars = [...state.characters];

    // --- GÜNLÜK RUTİNLER ---
    if (newTime.hour == 10 && newTime.minute == 0) {
      int idx = chars.indexWhere((c) => c.id == 'eren');
      if (idx != -1) chars[idx] = chars[idx].copyWith(isPresent: true, location: "Kasa", activity: "Dükkanı Hazırlıyor 🧹");
    }

    if (newTime.hour == 11 && newTime.minute == 0) {
      int idx = chars.indexWhere((c) => c.id == 'eren');
      if (idx != -1) chars[idx] = chars[idx].copyWith(location: "Bar Arkası", activity: "Sipariş Bekliyor");
    }

    // --- MÜŞTERİ OLUŞTURMA ---
    int currentCustomers = chars.where((c) => c.id.startsWith('musteri')).length;
    if (isOpen && currentCustomers < 5 && _rng.nextInt(100) < 2) {
      _spawnCustomer(chars);
    }
    
    // ÇINAR GELİŞİ
    int cinarIdx = chars.indexWhere((c) => c.id == 'cinar');
    if (isOpen && cinarIdx != -1 && !chars[cinarIdx].isPresent && _rng.nextInt(100) < 5) {
        chars[cinarIdx] = chars[cinarIdx].copyWith(isPresent: true, location: "Giriş", activity: "Selam Veriyor 👋");
    }

    // --- SÜRELİ İŞLEMLERİN KONTROLÜ (ÇİFT KANAL) ---
    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];
      
      // 1. KANAL: SİPARİŞ KONTROLÜ (Kahve Hazırlama)
      if (c.orderFinishTime != null && newTime.isAfter(c.orderFinishTime!)) {
        if (c.isBarista && c.activeOrder?.orderStatus == OrderStatus.preparing) {
          GameItem finished = GameItem(
            id: c.activeOrder!.id, name: c.activeOrder!.name, type: c.activeOrder!.type,
            relatedCustomerId: c.activeOrder!.relatedCustomerId,
            orderStatus: OrderStatus.ready, 
          );
          chars[i] = c.copyWith(activeOrder: finished, activity: "Servis Hazır! 🔔", orderFinishTime: null);
        }
      }

      // 2. KANAL: AKTİVİTE KONTROLÜ (Kitap/Laptop)
      if (c.activityFinishTime != null && newTime.isAfter(c.activityFinishTime!)) {
        if (c.activeActivity?.type == ItemType.book) {
          chars[i] = c.copyWith(
            activity: "Kitabı Bitirdi 🧠",
            happiness: (c.happiness + 0.2).clamp(0.0, 1.0),
            currentXp: c.currentXp + 30,
            clearActivity: true, // Aktivite kanalını temizle
          );
        } else if (c.activeActivity?.type == ItemType.laptop) {
          chars[i] = c.copyWith(
            activity: "Projeyi Tamamladı 💻",
            currentXp: c.currentXp + 60,
            success: (c.success + 0.1).clamp(0.0, 1.0),
            clearActivity: true, // Aktivite kanalını temizle
          );
        }
      }
    }
    
    // --- KAPANIŞ ---
    if (!isOpen && state.isShopOpen) {
       chars.removeWhere((c) => c.id.startsWith('musteri'));
       for(int i=0; i<chars.length; i++) {
         if (!chars[i].id.startsWith('musteri')) chars[i] = chars[i].copyWith(isPresent: false, location: "Ev", activity: "Dinleniyor");
       }
    }

    state = state.copyWith(gameTime: newTime, isShopOpen: isOpen, characters: chars);
  }

  void _spawnCustomer(List<Character> list) {
    List<ItemType> drinks = [ItemType.filterCoffee, ItemType.latte, ItemType.espresso, ItemType.herbalTea];
    ItemType wanted = drinks[_rng.nextInt(drinks.length)];
    String custId = "musteri_${_customerCounter++}";
    GameItem order = GameItem(id: "ord_${DateTime.now().millisecondsSinceEpoch}", name: "Kahve", type: wanted, relatedCustomerId: custId, orderStatus: OrderStatus.pending);
    list.add(Character(id: custId, name: "Müşteri $_customerCounter", imagePath: 'assets/cinar.png', title: 'Misafir', isPresent: true, location: "Masa", activity: "Sipariş Bekliyor", activeOrder: order));
  }


  // --- EŞYA VERME / ETKİLEŞİM MANTIĞI ---
  void giveItemToCharacter(String charId, GameItem item) {
    List<Character> updatedChars = [...state.characters];
    int idx = updatedChars.indexWhere((c) => c.id == charId);
    if (idx == -1) return;
    Character target = updatedChars[idx];

    // --- BÖLÜM 1: SİPARİŞ MANTIĞI (İçecekler) ---
    if (item.type != ItemType.laptop && item.type != ItemType.book) {
      
      // Baristaya Sipariş Verme (Sarı Balon Transferi)
      if (target.isBarista && item.orderStatus == OrderStatus.pending) {
          if (target.activeOrder != null) return; // Zaten kahve yapıyorsa alamaz

          DateTime finishTime = state.gameTime.add(const Duration(minutes: 15));
          GameItem preparing = GameItem(
            id: item.id, name: item.name, type: item.type,
            relatedCustomerId: item.relatedCustomerId, orderStatus: OrderStatus.preparing, 
          );
          updatedChars[idx] = target.copyWith(activeOrder: preparing, activity: "${item.name} Yapıyor...", orderFinishTime: finishTime, currentXp: target.currentXp + 10);
          
          // Müşteri tarafındaki balonu "İşleniyor (Mavi)" yap
          int cIdx = updatedChars.indexWhere((c) => c.id == item.relatedCustomerId);
          if (cIdx != -1) {
            updatedChars[cIdx] = updatedChars[cIdx].copyWith(
              activeOrder: GameItem(id: item.id, name: item.name, type: item.type, relatedCustomerId: item.relatedCustomerId, orderStatus: OrderStatus.processing),
              activity: "Bekliyor...",
            );
          }
      }
      // Müşteriye Teslimat (Yeşil Balon Transferi)
      else if (item.relatedCustomerId == target.id && item.orderStatus == OrderStatus.ready) {
        updatedChars[idx] = target.copyWith(clearOrder: true, activity: "Keyif Yapıyor ☕", currentXp: target.currentXp + 50, happiness: (target.happiness + 0.3).clamp(0.0, 1.0));
        
        // Baristayı temizle
        int bIdx = updatedChars.indexWhere((c) => c.isBarista && c.activeOrder?.id == item.id);
        if (bIdx != -1) {
          updatedChars[bIdx] = updatedChars[bIdx].copyWith(clearOrder: true, activity: "Sipariş Bekliyor", currentXp: updatedChars[bIdx].currentXp + 40);
        }
      }
    } 
    
    // --- BÖLÜM 2: AKTİVİTE MANTIĞI (Laptop / Kitap) ---
    else {
      // Eğer karakter zaten bir aktivite yapıyorsa yenisine başlayamaz
      if (target.activeActivity != null) return;

      if (item.type == ItemType.laptop) {
        DateTime finishTime = state.gameTime.add(const Duration(minutes: 120)); // 2 Saat
        updatedChars[idx] = target.copyWith(
          activity: "Kod Yazıyor...", 
          activityFinishTime: finishTime,
          activeActivity: GameItem(id: "act_${_rng.nextInt(99999)}", name: "Kod", type: ItemType.laptop, orderStatus: OrderStatus.processing)
        );
      } 
      else if (item.type == ItemType.book) {
        DateTime finishTime = state.gameTime.add(const Duration(minutes: 60)); // 1 Saat
        updatedChars[idx] = target.copyWith(
          activity: "Kitap Okuyor...", 
          activityFinishTime: finishTime,
          activeActivity: GameItem(id: "act_${_rng.nextInt(99999)}", name: "Kitap", type: ItemType.book, orderStatus: OrderStatus.processing)
        );
      }
    }

    state = state.copyWith(characters: updatedChars);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameStateData>(() => GameNotifier());