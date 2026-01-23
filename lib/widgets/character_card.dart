import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../models/game_item.dart';
import '../providers/game_provider.dart';
import '../screens/character_detail.dart';

class CharacterCard extends ConsumerWidget {
  final Character character;

  const CharacterCard({Key? key, required this.character}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    double opacity = character.isPresent ? 1.0 : 0.4;
    bool isSocializing = character.socializingWith != null; //

    // 20 DAKİKALIK BEKLEME KONTROLÜ
    bool isWaitingTooLong = false;
    if (character.activeOrder?.orderStatus == OrderStatus.pending && 
        character.arrivalTime != null) {
      final waitDuration = gameState.gameTime.difference(character.arrivalTime!).inMinutes;
      if (waitDuration >= 20) {
        isWaitingTooLong = true;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // EŞYA TESLİMİ İÇİN DRAG TARGET
        return DragTarget<GameItem>(
          onWillAccept: (incomingItem) {
            if (!character.isPresent || incomingItem == null) return false;
            if (character.isBarista) {
              if (incomingItem.orderStatus == OrderStatus.pending) {
                return character.activeOrder == null;
              }
            }
            if (!character.isBarista && incomingItem.relatedCustomerId == character.id) {
              if (incomingItem.orderStatus == OrderStatus.ready) return true;
            }
            if (incomingItem.type == ItemType.laptop || incomingItem.type == ItemType.book) {
              return character.activeActivity == null;
            }
            return false;
          },
          onAccept: (item) {
            ref.read(gameProvider.notifier).giveItemToCharacter(character.id, item);
          },
          builder: (context, candidateData, rejectedData) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // ANA KART YAPISI
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => CharacterDetailScreen(character: character))
                      );
                    },
                    child: Opacity(
                      opacity: opacity,
                      child: Card(
                        elevation: candidateData.isNotEmpty ? 10 : 6,
                        color: candidateData.isNotEmpty 
                            ? Colors.green[100] 
                            : (rejectedData.isNotEmpty ? Colors.red[50] : Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isWaitingTooLong ? Colors.red : Colors.transparent, 
                            width: 2
                          ),
                        ),
                        child: Container(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Konum Etiketi
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50], 
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[100]!),
                                ),
                                child: Text(
                                  character.location, 
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue), 
                                  overflow: TextOverflow.ellipsis
                                ),
                              ),
                              // Karakter Resmi
                              Expanded(
                                child: Hero(
                                  tag: character.id,
                                  child: character.imagePath.isNotEmpty
                                      ? Image.asset(character.imagePath, fit: BoxFit.contain)
                                      : Icon(Icons.person, size: 60, color: Colors.grey[400]),
                                ),
                              ),
                              // İsim & Aktivite Metni
                              Column(
                                children: [
                                  Text(character.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(
                                    character.activity, 
                                    textAlign: TextAlign.center, 
                                    style: TextStyle(fontSize: 10, color: Colors.orange[800], fontStyle: FontStyle.italic), 
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis
                                  ),
                                ],
                              ),
                              
                              // İLİŞKİ BARI (Sosyalleşirken Görünür)
                              if (isSocializing)
                                _buildRelationshipBar(),

                              const SizedBox(height: 5),
                              
                              // XP / Level Barı
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Lvl ${character.level}", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                                  const SizedBox(height: 2),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (character.currentXp / character.requiredXp).clamp(0.0, 1.0),
                                      backgroundColor: Colors.grey[200], 
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange), 
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // SOSYALLİK DAİRESİ (Sürükle-Bırak)
                if (character.isPresent)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: _buildSocialDraggable(ref),
                  ),

                // SAĞ ÜST: SİPARİŞ BULUTU
                if (character.activeOrder != null && character.isPresent)
                  Positioned(
                    right: 0, 
                    top: 0,
                    child: Draggable<GameItem>(
                      data: character.activeOrder,
                      feedback: _buildBubble(character.activeOrder!, isDragging: true),
                      childWhenDragging: Opacity(opacity: 0.2, child: _buildBubble(character.activeOrder!)),
                      child: _buildBubble(character.activeOrder!),
                    ),
                  ),

                // SOL ÜST: AKTİVİTE BULUTU
                if (character.activeActivity != null && character.isPresent)
                  Positioned(
                    left: 0, 
                    top: 0,
                    child: Draggable<GameItem>(
                      data: character.activeActivity,
                      feedback: _buildBubble(character.activeActivity!, isDragging: true),
                      childWhenDragging: Opacity(opacity: 0.2, child: _buildBubble(character.activeActivity!)),
                      child: _buildBubble(character.activeActivity!),
                    ),
                  ),

                // GECİKME UYARISI
                if (isWaitingTooLong && character.isPresent)
                  Positioned(
                    left: 15,
                    bottom: 55,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.priority_high, color: Colors.white, size: 18),
                    ),
                  ),
              ],
            );
          },
        );
      }
    );
  }

  // --- YARDIMCI WIDGETLAR ---

  // Sosyallik Dairesi ve Drag-Drop Yönetimi
 // lib/widgets/character_card.dart içinde _buildSocialDraggable metodu:

Widget _buildSocialDraggable(WidgetRef ref) {
  // Eğer karakter zaten konuşuyorsa sürüklemeyi tamamen devre dışı bırakıyoruz (maxSimultaneousDrags: 0)
  return Draggable<String>(
    data: character.id,
    maxSimultaneousDrags: character.socializingWith == null ? 1 : 0, // Konuşuyorsa sürüklenemez
    feedback: _circleIcon(true),
    childWhenDragging: Opacity(opacity: 0.3, child: _circleIcon(false)),
    child: DragTarget<String>(
      onWillAccept: (incomingId) {
        // KONTROL 1: Kendisiyle konuşamaz
        // KONTROL 2: Kendisi zaten biriyle konuşuyorsa yeni birini kabul edemez
        return incomingId != character.id && character.socializingWith == null;
      },
      onAccept: (incomingId) => ref.read(gameProvider.notifier).startSocializing(incomingId, character.id),
      builder: (context, candidateData, _) {
        return _circleIcon(candidateData.isNotEmpty);
      },
    ),
  );
}
  // Sosyal Daire İkonu
  Widget _circleIcon(bool highlight) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: character.socializingWith != null ? Colors.pink[300] : (highlight ? Colors.green : Colors.blueAccent),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: const Icon(Icons.people, color: Colors.white, size: 20),
    );
  }

  // İlişki İlerleme Barı
  Widget _buildRelationshipBar() {
    String partnerId = character.socializingWith!;
    double relLevel = character.relationships[partnerId] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Text("Bağ: %${(relLevel * 100).toInt()}", style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.pink)),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: relLevel,
            backgroundColor: Colors.pink[50],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.pink[300]!),
            minHeight: 3,
          ),
        ],
      ),
    );
  }

  // Sipariş/Aktivite Baloncuğu
  Widget _buildBubble(GameItem item, {bool isDragging = false}) {
    Color color = Colors.white;
    if (item.orderStatus == OrderStatus.pending) color = Colors.yellow[100]!;
    if (item.orderStatus == OrderStatus.processing) color = Colors.blue[100]!;
    if (item.orderStatus == OrderStatus.preparing) color = Colors.grey[300]!;
    if (item.orderStatus == OrderStatus.ready) color = Colors.green[100]!;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color, 
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 2))],
          border: Border.all(color: Colors.brown, width: 1.5),
        ),
        child: Text(item.iconAsset, style: TextStyle(fontSize: isDragging ? 30 : 22)),
      ),
    );
  }
}