// lib/providers/shop_provider.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/shop_models.dart';
import '../models/game_item.dart'; // Önceki item modelin

class ShopState {
  final DateTime gameTime; // Oyun saati
  final bool isOpen;
  final List<SeatSlot> terraceSlots;
  final List<SeatSlot> bigTableSlots;
  final List<SeatSlot> salonSlots;

  ShopState({
    required this.gameTime,
    required this.isOpen,
    required this.terraceSlots,
    required this.bigTableSlots,
    required this.salonSlots,
  });
}

class ShopNotifier extends StateNotifier<ShopState> {
  Timer? _timer;
  final Random _rng = Random();

  ShopNotifier() : super(_initialState()) {
    _startTimer();
  }

  static ShopState _initialState() {
    // Başlangıç: Cuma sabah 10:00 (Açılışa 1 saat var)
    DateTime start = DateTime(2025, 1, 1, 10, 0); 
    
    return ShopState(
      gameTime: start,
      isOpen: false,
      // 13 Teras Yeri
      terraceSlots: List.generate(13, (i) => SeatSlot(id: i, locationName: "Teras ${i+1}", type: SeatType.terrace)),
      // 5 Büyük Masa Yeri
      bigTableSlots: List.generate(5, (i) => SeatSlot(id: 100+i, locationName: "Büyük Masa ${i+1}", type: SeatType.bigTable)),
      // 7 Salon Yeri
      salonSlots: List.generate(7, (i) => SeatSlot(id: 200+i, locationName: "Salon ${i+1}", type: SeatType.regularTable)),
    );
  }

  void _startTimer() {
    // Gerçek hayatta 1 saniye = Oyunda 10 dakika (Hızlı aksın diye)
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  void _tick() {
    // 1. Zamanı İlerlet
    DateTime newTime = state.gameTime.add(Duration(minutes: 10));
    
    // 2. Açık/Kapalı Kontrolü
    // Cuma(5) veya Cumartesi(6) -> Kapanış 23:00, Diğer -> 22:00
    int closingHour = (newTime.weekday == 5 || newTime.weekday == 6) ? 23 : 22;
    bool newIsOpen = newTime.hour >= 11 && newTime.hour < closingHour;

    // 3. Müşteri Döngüsü (Sadece Açıksa)
    List<SeatSlot> tSlots = [...state.terraceSlots];
    List<SeatSlot> bSlots = [...state.bigTableSlots];
    List<SeatSlot> sSlots = [...state.salonSlots];

    if (newIsOpen) {
      // Rastgele Müşteri Gelme Şansı (%30)
      if (_rng.nextInt(100) < 30) _spawnCustomer(tSlots, bSlots, sSlots);
    } else {
      // Dükkan kapalıysa herkesi kov :)
      if (state.isOpen) { // Yeni kapandıysa
         tSlots = tSlots.map((s) => s.copyWith(clearCustomer: true)).toList();
         bSlots = bSlots.map((s) => s.copyWith(clearCustomer: true)).toList();
         sSlots = sSlots.map((s) => s.copyWith(clearCustomer: true)).toList();
      }
    }

    // 4. Mevcut Müşterilerin Zamanını Azalt
    _updateCustomers(tSlots);
    _updateCustomers(bSlots);
    _updateCustomers(sSlots);

    state = ShopState(
      gameTime: newTime,
      isOpen: newIsOpen,
      terraceSlots: tSlots,
      bigTableSlots: bSlots,
      salonSlots: sSlots,
    );
  }

  void _spawnCustomer(List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s) {
    // Boş yer bul
    List<SeatSlot> allEmpty = [...t, ...b, ...s].where((slot) => slot.customer == null).toList();
    if (allEmpty.isEmpty) return;

    // Rastgele bir yere oturt
    SeatSlot targetSlot = allEmpty[_rng.nextInt(allEmpty.length)];
    
    // Müşteri Özellikleri
    bool isBigTable = targetSlot.type == SeatType.bigTable;
    int duration = isBigTable ? 120 + _rng.nextInt(120) : 10 + _rng.nextInt(50); // Büyük masadakiler uzun oturur (2-4 saat)
    String activity = isBigTable ? "Ders Çalışıyor" : "Sohbet Ediyor";
    if (_rng.nextBool() && !isBigTable) activity = "Kitap Okuyor";

    Customer newCustomer = Customer(
      id: DateTime.now().toIso8601String(),
      name: "Müşteri ${_rng.nextInt(900)}",
      durationMinutes: duration,
      lookingFor: _rng.nextBool() ? "Kahve" : "Çay", // Sipariş isteği
      state: ActivityState.ordering, // İlk gelince sipariş bekler
    );

    // Listeyi Güncelle
    _updateSlotInList(targetSlot.id, newCustomer, t, b, s);
  }

  void _updateCustomers(List<SeatSlot> slots) {
    for (int i = 0; i < slots.length; i++) {
      if (slots[i].customer != null) {
        Customer c = slots[i].customer!;
        int timeLeft = c.durationMinutes - 10;
        
        if (timeLeft <= 0) {
          // Süresi bitti, gidiyor
          slots[i] = slots[i].copyWith(clearCustomer: true);
        } else {
          // Süre azalıyor
          slots[i] = slots[i].copyWith(customer: c.copyWith(durationMinutes: timeLeft));
        }
      }
    }
  }

  // Sipariş Teslim Etme Fonksiyonu
  void fulfillOrder(int slotId, String itemName) {
    // Bu fonksiyonu UI'dan çağıracağız
    List<SeatSlot> all = [...state.terraceSlots, ...state.bigTableSlots, ...state.salonSlots];
    var slotIndex = all.indexWhere((s) => s.id == slotId);
    
    if (slotIndex != -1 && all[slotIndex].customer != null) {
      Customer c = all[slotIndex].customer!;
      if (c.state == ActivityState.ordering && (itemName.contains(c.lookingFor) || c.lookingFor == "")) {
        // Sipariş Doğru!
        // Hangi listede olduğunu bul ve güncelle (Basitleştirilmiş logic)
        // Gerçek implementasyonda hangi listede olduğunu kontrol edip orada güncellemelisin
        // Burası örnek olduğu için sadece print atıyorum:
        print("Sipariş teslim edildi: $itemName");
        // Burada state güncellemesi yaparak müşterinin durumunu 'consuming' yapmalısın
      }
    }
  }

  void _updateSlotInList(int id, Customer? c, List<SeatSlot> t, List<SeatSlot> b, List<SeatSlot> s) {
    // Helper: Hangi listedeyse onu bul ve güncelle
    int index = t.indexWhere((slot) => slot.id == id);
    if (index != -1) { t[index] = t[index].copyWith(customer: c); return; }
    
    index = b.indexWhere((slot) => slot.id == id);
    if (index != -1) { b[index] = b[index].copyWith(customer: c); return; }

    index = s.indexWhere((slot) => slot.id == id);
    if (index != -1) { s[index] = s[index].copyWith(customer: c); return; }
  }
}

final shopProvider = StateNotifierProvider<ShopNotifier, ShopState>((ref) => ShopNotifier());