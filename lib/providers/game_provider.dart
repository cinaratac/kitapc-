import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../models/game_item.dart';

// --- OYUNUN DURUM VERİSİ (STATE) ---
class GameStateData {
  final List<Character> characters;
  final List<GameItem> inventory; // Depodaki eşyalar (Laptop, Kitap vb.)
  final DateTime gameTime;        // Oyun saati
  final bool isShopOpen;          // Dükkan açık mı?

  GameStateData({
    required this.characters,
    required this.inventory,
    required this.gameTime,
    required this.isShopOpen,
  });

  // State'i güncellemek için kopya oluşturucu
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

// --- OYUN MOTORU (NOTIFIER) ---
class GameNotifier extends Notifier<GameStateData> {
  Timer? _timer;
  final Random _rng = Random();
  int _customerCounter = 1; // Müşteri isimlendirmek için sayaç

  @override
  GameStateData build() {
    _startTimer();
    
    // BAŞLANGIÇ AYARLARI
    // Saat: 09:30 (Dükkan Kapalı)
    // Envanter: Sadece Laptop var (İçecekler yok)
    return GameStateData(
      gameTime: DateTime(2025, 1, 1, 9, 30), 
      isShopOpen: false,
      inventory: [
         GameItem(id: 'pc1', name: 'Laptop', type: ItemType.laptop, xpValue: 10),
      ],
      characters: [
        // EREN: Başlangıçta evde
        Character(
          id: 'eren', name: 'Eren', imagePath: 'assets/eren.png', title: 'Barista', 
          isBarista: true, 
          isPresent: false, location: "Ev", activity: "Uyanıyor...",
        ),
        // ÇINAR: Başlangıçta evde
        Character(
          id: 'cinar', name: 'Çınar', imagePath: 'assets/cinar.png', title: 'Müdavim', 
          isPresent: false, location: "Ev", activity: "Uyuyor",
        ),
      ],
    );
  }

  // --- ZAMANLAYICI ---
  void _startTimer() {
    // 1 Gerçek Saniye = 1 Oyun Dakikası (YAVAŞLATILDI)
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  // --- HER SANİYE ÇALIŞAN FONKSİYON ---
  void _tick() {
    // 1. Zamanı 1 dakika ilerlet
    DateTime newTime = state.gameTime.add(Duration(minutes: 10));
    
    // Dükkan Saatleri: 11:00 - 23:00
    bool isOpen = newTime.hour >= 11 && newTime.hour < 23;
    
    List<Character> chars = [...state.characters];

    // --- SENARYO MANTIĞI ---

    // SAAT 10:00 -> EREN GELİR (Hazırlık)
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

    // SAAT 11:00 -> DÜKKAN AÇILIR (Eren Bara Geçer)
    if (newTime.hour == 11 && newTime.minute == 0) {
      int idx = chars.indexWhere((c) => c.id == 'eren');
      if (idx != -1) {
        chars[idx] = chars[idx].copyWith(
          location: "Bar Arkası",
          activity: "Sipariş Bekliyor",
        );
      }
    }

    // MÜŞTERİ OLUŞTURMA (SPAWN)
    // Sadece dükkan açıksa ve müşteri sayısı 6'dan azsa
    int currentCustomers = chars.where((c) => c.id.startsWith('musteri')).length;
    // Gelme ihtimali %2 (Çok nadir, zombi istilası olmasın diye)
    if (isOpen && currentCustomers < 6 && _rng.nextInt(100) < 2) {
      _spawnCustomer(chars);
    }

    // ÇINAR'IN GELİŞİ (Rastgele)
    int cinarIdx = chars.indexWhere((c) => c.id == 'cinar');
    if (isOpen && cinarIdx != -1 && !chars[cinarIdx].isPresent) {
      if (_rng.nextInt(100) < 5) { // %5 ihtimalle gelsin
        chars[cinarIdx] = chars[cinarIdx].copyWith(
          isPresent: true,
          location: "Giriş",
          activity: "Selam Veriyor 👋",
        );
      }
    }

    // --- BARISTA PİŞİRME KONTROLÜ ---
    for (int i = 0; i < chars.length; i++) {
      Character c = chars[i];
      // Eğer Barista ise VE sipariş hazırlıyorsa (Preparing - Gri Balon)
      if (c.isBarista && c.activeOrder != null && c.activeOrder!.orderStatus == OrderStatus.preparing) {
        // Süre doldu mu?
        if (c.orderFinishTime != null && newTime.isAfter(c.orderFinishTime!)) {
          // KAHVE HAZIR! (Durumu Ready yap)
          GameItem finished = GameItem(
            id: c.activeOrder!.id,
            name: "${c.activeOrder!.name}",
            type: c.activeOrder!.type,
            relatedCustomerId: c.activeOrder!.relatedCustomerId,
            orderStatus: OrderStatus.ready, // ARTIK YEŞİL OLACAK
          );
          
          chars[i] = c.copyWith(
            activeOrder: finished,
            activity: "Servis Hazır! 🔔",
            orderFinishTime: null,
          );
        }
      }
    }
    
    // --- KAPANIŞ MANTIĞI ---
    if (!isOpen && state.isShopOpen) { // Dükkan yeni kapandıysa
       chars.removeWhere((c) => c.id.startsWith('musteri')); // Müşteriler gider
       // Ana karakterler eve gider
       for(int i=0; i<chars.length; i++) {
         // id'si müşteri olmayanları eve gönder
         if (!chars[i].id.startsWith('musteri')) {
            chars[i] = chars[i].copyWith(isPresent: false, location: "Ev", activity: "Dinleniyor");
         }
       }
    }

    // State'i güncelle
    state = state.copyWith(
      gameTime: newTime,
      isShopOpen: isOpen,
      characters: chars,
    );
  }

  // --- MÜŞTERİ YARATMA ---
  void _spawnCustomer(List<Character> list) {
    List<ItemType> drinks = [ItemType.filterCoffee, ItemType.latte, ItemType.espresso, ItemType.herbalTea];
    ItemType wanted = drinks[_rng.nextInt(drinks.length)];
    String drinkName = _getDrinkName(wanted);
    String custId = "musteri_${_customerCounter++}";

    // Müşteri kafasında SARI (Pending) balonla doğar
    GameItem order = GameItem(
      id: "ord_${DateTime.now().millisecondsSinceEpoch}",
      name: drinkName,
      type: wanted,
      relatedCustomerId: custId,
      orderStatus: OrderStatus.pending, 
    );

    list.add(Character(
      id: custId,
      name: "Müşteri $_customerCounter",
      imagePath: 'assets/cinar.png', // Geçici olarak Çınar resmi veya assets/musteri.png
      title: 'Misafir',
      isPresent: true,
      location: "Masa",
      activity: "Sipariş Bekliyor",
      activeOrder: order,
    ));
  }

  String _getDrinkName(ItemType t) {
     if(t == ItemType.filterCoffee) return "Filtre Kahve";
     if(t == ItemType.latte) return "Latte";
     if(t == ItemType.herbalTea) return "Çay";
     if(t == ItemType.espresso) return "Espresso";
     return "Kahve";
  }

  // --- KRİTİK FONKSİYON: EŞYA VERME / SİPARİŞ İŞLEME ---
  // giveItemToCharacter FONKSİYONUNU BUL VE KOMPLE BUNUNLA DEĞİŞTİR:

  // lib/providers/game_provider.dart içinde bu fonksiyonu bul ve bununla değiştir:

  void giveItemToCharacter(String charId, GameItem item) {
    List<Character> updatedChars = [...state.characters];
    int idx = updatedChars.indexWhere((c) => c.id == charId);
    if (idx == -1) return;
    Character target = updatedChars[idx];

    // --- SENARYO 1: BARİSTAYA SİPARİŞ VERME (Sarı Balon -> Gri Balon) ---
    if (target.isBarista) {
      if (target.activeOrder != null) return; // Barista doluysa alma

      if (item.orderStatus == OrderStatus.pending) {
        DateTime finishTime = state.gameTime.add(Duration(minutes: 15));
        
        // Barista için yeni sipariş oluştur (Gri - Hazırlanıyor)
        GameItem preparingItem = GameItem(
          id: item.id, name: item.name, type: item.type,
          relatedCustomerId: item.relatedCustomerId,
          orderStatus: OrderStatus.preparing, 
        );

        updatedChars[idx] = target.copyWith(
          activeOrder: preparingItem,
          activity: "${item.name} Yapıyor...",
          orderFinishTime: finishTime,
          currentXp: target.currentXp + 10,
        );

        // MÜŞTERİYİ BUL VE GÜNCELLE (Sarı -> Mavi)
        int customerIdx = updatedChars.indexWhere((c) => c.id == item.relatedCustomerId);
        if (customerIdx != -1) {
          updatedChars[customerIdx] = updatedChars[customerIdx].copyWith(
            activeOrder: GameItem(
              id: item.id, name: item.name, type: item.type,
              relatedCustomerId: item.relatedCustomerId,
              orderStatus: OrderStatus.processing, // MAVİ (BEKLİYOR)
            ),
            activity: "Hazırlanmasını Bekliyor...",
          );
        }
        
        _removeFromInventory(item.id);
        _removeItemFromOtherCharacters(item.id);
      }
    }
    
    // --- SENARYO 2: MÜŞTERİYE HAZIR KAHVEYİ VERME (Yeşil Balon -> Yok Olma) ---
    else if (item.relatedCustomerId == target.id && item.orderStatus == OrderStatus.ready) {
      
      // 1. MÜŞTERİ GÜNCELLEMESİ (Balon Silinir)
      updatedChars[idx] = target.copyWith(
        clearOrder: true, // <--- KRİTİK DÜZELTME: Balonu zorla siliyoruz
        activity: "Keyif Yapıyor ☕",
        currentXp: target.currentXp + 50,
        happiness: (target.happiness + 0.3).clamp(0.0, 1.0),
      );
      
      // 2. BARİSTA GÜNCELLEMESİ (Yeşil Balon Silinir)
      int baristaIdx = updatedChars.indexWhere((c) => c.isBarista && c.activeOrder?.id == item.id);
      if (baristaIdx != -1) {
        updatedChars[baristaIdx] = updatedChars[baristaIdx].copyWith(
          clearOrder: true, // <--- KRİTİK DÜZELTME: Baristanın elini boşaltıyoruz
          activity: "Sipariş Bekliyor",
          currentXp: updatedChars[baristaIdx].currentXp + 40,
        );
      }
      
      _removeFromInventory(item.id);
    }
    
    // --- DİĞER EŞYALAR ---
    else if (item.type == ItemType.laptop) {
       updatedChars[idx] = target.copyWith(activity: "Kod Yazıyor 💻", currentXp: target.currentXp + 20);
    }
    else if (item.type == ItemType.book) {
       updatedChars[idx] = target.copyWith(activity: "Kitap Okuyor 📖", happiness: (target.happiness + 0.1).clamp(0.0, 1.0));
    }

    state = state.copyWith(characters: updatedChars);
  }

  // Eşyayı depoya (aşağıdaki kutuya) ekle
  void addToInventory(GameItem item) {
    // Önce karakterlerin üzerinden sil (Sürüklenen item kopyalanmasın)
    _removeItemFromOtherCharacters(item.id);
    // Depoya ekle
    state = state.copyWith(inventory: [...state.inventory, item]);
  }

  // Depodan sil
  void _removeFromInventory(String id) {
    state = state.copyWith(inventory: state.inventory.where((i) => i.id != id).toList());
  }

  // Bir karakterden eşyayı al (Sürükleme başladığında veya transfer olduğunda)
  void _removeItemFromOtherCharacters(String itemId) {
    List<Character> chars = state.characters.map((c) {
      // Eğer karakterin elindeki sipariş ID'si bu ise, sil
      if (c.activeOrder?.id == itemId) {
        return c.copyWith(clearOrder: true, activity: "Bekliyor"); 
      }
      return c;
    }).toList();
    state = state.copyWith(characters: chars);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameStateData>(() => GameNotifier());