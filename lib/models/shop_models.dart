// lib/models/shop_models.dart

enum ActivityState { idle, ordering, consuming, leaving }
enum SeatType { terrace, bigTable, regularTable }

class Customer {
  final String id;
  final String name;
  final String lookingFor; // Ne istiyor? (Kahve, Çay)
  final int durationMinutes; // Ne kadar oturacak?
  final ActivityState state;
  final bool isGroup; // Arkadaşıyla mı geldi?

  Customer({
    required this.id,
    required this.name,
    this.lookingFor = "",
    required this.durationMinutes,
    this.state = ActivityState.idle,
    this.isGroup = false,
  });

  Customer copyWith({ActivityState? state, String? lookingFor, int? durationMinutes}) {
    return Customer(
      id: id,
      name: name,
      lookingFor: lookingFor ?? this.lookingFor,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      state: state ?? this.state,
      isGroup: isGroup,
    );
  }
}

class SeatSlot {
  final int id;
  final String locationName; // "Teras Masa 1", "Büyük Masa"
  final SeatType type;
  final Customer? customer; // Boşsa null olur

  SeatSlot({required this.id, required this.locationName, required this.type, this.customer});

  SeatSlot copyWith({Customer? customer, bool clearCustomer = false}) {
    return SeatSlot(
      id: id,
      locationName: locationName,
      type: type,
      customer: clearCustomer ? null : (customer ?? this.customer),
    );
  }
}