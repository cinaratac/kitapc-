import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../models/game_item.dart';

class GameStateData {
  final List<Character> characters;
  final List<GameItem> inventory; // AŞAĞIDAKİ KUTUDAKİ EŞYALAR
  final DateTime gameTime;
  final bool isShopOpen;

  GameStateData({
    required this.characters,
    required this.inventory, // Yeni
    required this.gameTime,
    required this.isShopOpen,
  });

  GameStateData copyWith({
    List<Character>? characters,
    List<GameItem>? inventory,
    DateTime? gameTime,
    bool? isShopOpen,
  }) {
    return GameStateData(
      characters: characters ?? this.characters,
      inventory: inventory ?? this.inventory,
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
      gameTime: DateTime(2025, 1, 1, 10, 00),
      isShopOpen: false,
      inventory: [
        // Başlangıçta boş veya test için item koyabilirsin
        GameItem(id: 'pc1', name: 'Laptop', type: ItemType.laptop),
      ], 
      characters: [
        Character(
          id: 'eren', name: 'Eren', imagePath: 'assets/eren.png', title: 'Barista', 
          isBarista: true, isPresent: true, location: "Bar", activity: "Hazır",
        ),
        Character(
          id: 'cinar', name: 'Çınar', imagePath: 'assets/cinar.png', title: 'Müdavim', 
          isPresent: true, location: "Giriş", activity: "Oturuyor",
        ),
      ],
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  void _tick() {
    DateTime newTime = state.gameTime.add(Duration(minutes: 1));
    bool isOpen = newTime.hour >= 11 && newTime.hour < 23;
    List<Character> chars = [...state.characters];

    // 1. MÜŞTERİ GELİŞİ (SPAWN)
    if (isOpen && chars.where((c) => c.id.startsWith('musteri')).length < 4 && _rng.nextInt(100) < 15) {
      _spawnCustomer(chars);
    }

    // 2. BARISTA KONTROLÜ (Kahve Pişti mi?)
    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];
      // Eğer barista kahve yapıyorsa ve süre dolduysa
      if (c.isBarista && c.activeOrder != null && c.activeOrder!.orderStatus == OrderStatus.preparing) {
        if (c.orderFinishTime != null && newTime.isAfter(c.orderFinishTime!)) {
          // KAHVE HAZIR!
          GameItem finishedDrink = GameItem(
            id: c.activeOrder!.id,
            name: "${c.activeOrder!.name} (Hazır)",
            type: c.activeOrder!.type,
            relatedCustomerId: c.activeOrder!.relatedCustomerId,
            orderStatus: OrderStatus.ready, // Durumu değişti
          );
          
          chars[i] = c.copyWith(
            activeOrder: finishedDrink,
            activity: "Servis Bekliyor! 🔔",
            orderFinishTime: null,
          );
        }
      }
    }

    state = state.copyWith(
      gameTime: newTime,
      isShopOpen: isOpen,
      characters: chars,
    );
  }

  void _spawnCustomer(List<Character> list) {
    // Rastgele İçecek İsteği
    List<ItemType> drinks = [ItemType.filterCoffee, ItemType.latte, ItemType.espresso, ItemType.herbalTea, ItemType.salep, ItemType.hotChocolate];
    ItemType wanted = drinks[_rng.nextInt(drinks.length)];
    String drinkName = _getDrinkName(wanted);
    String custId = "musteri_${_customerCounter++}";

    // Müşterinin kafasında belirecek sipariş balonu
    GameItem orderRequest = GameItem(
      id: "ord_${DateTime.now().millisecondsSinceEpoch}",
      name: drinkName,
      type: wanted,
      relatedCustomerId: custId, // Müşteriye bağladık
      orderStatus: OrderStatus.pending,
    );

    list.add(Character(
      id: custId,
      name: "Müşteri $_customerCounter",
      imagePath: 'assets/musteri.png',
      title: 'Misafir',
      isPresent: true,
      location: "Masa",
      activity: "$drinkName İstiyor",
      activeOrder: orderRequest, // Sipariş isteğiyle doğdu
    ));
  }

  // --- SÜRÜKLE BIRAK MANTIĞI ---

  // 1. Eşyayı Envantere Koy (Aşağıdaki Kutuya)
  void addToInventory(GameItem item) {
    // Eğer karakterin üzerindeyse, karakterden silmemiz lazım (bunu UI tarafında handle edeceğiz veya buradan id ile bulup silebiliriz)
    _removeItemFromCharacters(item.id);
    
    state = state.copyWith(inventory: [...state.inventory, item]);
  }

  // 2. Karakter Eşya/Sipariş Aldı
  void giveItemToCharacter(String charId, GameItem item) {
    List<Character> updatedChars = [...state.characters];
    int idx = updatedChars.indexWhere((c) => c.id == charId);
    if (idx == -1) return;
    Character target = updatedChars[idx];

    // SENARYO A: SİPARİŞİ BARİSTAYA VERMEK
    if (target.isBarista && item.orderStatus == OrderStatus.pending) {
      // Barista işe başlar
      DateTime finishTime = state.gameTime.add(Duration(minutes: 5)); // 5 dk süre
      
      GameItem preparingItem = GameItem(
        id: item.id, name: item.name, type: item.type, 
        relatedCustomerId: item.relatedCustomerId, 
        orderStatus: OrderStatus.preparing
      );

      updatedChars[idx] = target.copyWith(
        activeOrder: preparingItem,
        activity: "${item.name} Yapıyor...",
        orderFinishTime: finishTime,
      );
      
      // Envanterden siliyoruz (eğer oradan geldiyse)
      _removeFromInventory(item.id);
      // Eğer başka bir karakterden geldiyse onu da temizle
      _removeItemFromCharacters(item.id); 
    }

    // SENARYO B: HAZIR KAHVEYİ MÜŞTERİYE VERMEK
    else if (item.relatedCustomerId == target.id && item.orderStatus == OrderStatus.ready) {
      // Müşteri siparişini aldı! MUTLULUK!
      updatedChars[idx] = target.copyWith(
        activeOrder: null, // Baloncuk gider
        activity: "İçiyor 😋",
        happiness: (target.happiness + 0.3).clamp(0.0, 1.0),
        currentXp: target.currentXp + 50,
      );
      
      // Baristaya da puan verelim (Eren'i bul)
      int erenIdx = updatedChars.indexWhere((c) => c.id == 'eren');
      if (erenIdx != -1) {
        updatedChars[erenIdx] = updatedChars[erenIdx].copyWith(
          currentXp: updatedChars[erenIdx].currentXp + 30, // Barista puanı
          activeOrder: null, // Barista boşa çıkar
          activity: "Sipariş Bekliyor"
        );
      }

      _removeFromInventory(item.id);
      // (Not: Baristadan direkt sürüklediysek baristanın activeOrder'ı zaten yukarıdaki logic ile temizlenmeli ama garanti olsun diye UI tarafında da bakacağız)
    }
    
    // SENARYO C: LAPTOP/KİTAP VERMEK (Eski mantık)
    else {
      // ... eski mantık ...
    }

    state = state.copyWith(characters: updatedChars);
  }

  void _removeFromInventory(String itemId) {
    state = state.copyWith(
      inventory: state.inventory.where((i) => i.id != itemId).toList()
    );
  }
  
  void _removeItemFromCharacters(String itemId) {
    // Tüm karakterleri gez, eğer bu item birinde "activeOrder" ise sil
    List<Character> chars = state.characters.map((c) {
      if (c.activeOrder?.id == itemId) {
        return c.copyWith(clearOrder: true, activity: "Bekliyor"); 
      }
      return c;
    }).toList();
    state = state.copyWith(characters: chars);
  }

  String _getDrinkName(ItemType type) {
    switch (type) {
      case ItemType.filterCoffee: return "Filtre Kahve";
      case ItemType.latte: return "Latte";
      case ItemType.espresso: return "Espresso";
      case ItemType.herbalTea: return "Bitki Çayı";
      case ItemType.salep: return "Salep";
      case ItemType.hotChocolate: return "Sıcak Çikolata";
      default: return "";
    }
  }
}
final gameProvider = NotifierProvider<GameNotifier, GameStateData>(() => GameNotifier());