// lib/widgets/character_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../models/game_item.dart';
import '../providers/game_provider.dart';
import '../screens/character_detail.dart';
import '../data/activity_items_data.dart'; // Aktivite listesini kullanmak için eklendi

class CharacterCard extends ConsumerWidget {
  final Character character;

  const CharacterCard({Key? key, required this.character}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    double opacity = character.isPresent ? 1.0 : 0.4;
    bool isSocializing = character.socializingWith != null;

    // 20 DAKİKALIK BEKLEME KONTROLÜ (Kırmızı Kenarlık)
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
        return DragTarget<GameItem>(
          onWillAccept: (incomingItem) {
            if (!character.isPresent || incomingItem == null) return false;
            
            // 1. Barista Sipariş Hazırlama Kontrolü
            if (character.isBarista) {
              if (incomingItem.orderStatus == OrderStatus.pending) {
                return character.activeOrder == null;
              }
            }

            // 2. Müşteri Hazır Siparişi Teslim Alma Kontrolü
            if (!character.isBarista && incomingItem.relatedCustomerId == character.id) {
              if (incomingItem.orderStatus == OrderStatus.ready) return true;
            }

            // 3. --- GÜNCELLENEN KISIM: TÜM AKTİVİTE EŞYALARI ---
            // Sürüklenen eşya bir aktivite eşyası mı? (Gitar, Laptop, Kitap, Resim Seti vb.)
           final bool isActivityItem = allActivityItems.any((a) => a.type == incomingItem.type);
            
            if (isActivityItem) {
      return character.activeActivity == null && character.socializingWith == null;
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
                // --- ANA KART ---
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
                            ? Colors.green[50] 
                            : (rejectedData.isNotEmpty ? Colors.red[50] : Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isWaitingTooLong ? Colors.red : Colors.transparent, 
                            width: 2
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.only(top: 25, left: 10, right: 10, bottom: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Konum Etiketi
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50], 
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  character.location, 
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue), 
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
                              // İsim & Aktivite
                              Column(
                                children: [
                                  Text(character.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(
                                    character.activity, 
                                    textAlign: TextAlign.center, 
                                    style: TextStyle(fontSize: 10, color: Colors.orange[800], fontStyle: FontStyle.italic), 
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis
                                  ),
                                ],
                              ),
                              
                              if (isSocializing) _buildRelationshipBar(),
                              const SizedBox(height: 4),
                              _buildXpBar(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // --- SOSYALLİK DAİRESİ (Üst-Orta) ---
                if (character.isPresent)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildSocialDraggable(ref),
                    ),
                  ),

                // --- DÜŞÜNCE BULUTU ---
                if (character.activeThought != null && character.isPresent)
                  Positioned(
                    top: -45,
                    left: -10,
                    right: -10,
                    child: _buildThoughtBubble(),
                  ),

                // SAĞ ÜST: SİPARİŞ BULUTU
                if (character.activeOrder != null && character.isPresent)
                  Positioned(
                    right: 0, 
                    top: 5,
                    child: Draggable<GameItem>(
                      data: character.activeOrder,
                      feedback: _buildBubble(character.activeOrder!, isDragging: true),
                      child: _buildBubble(character.activeOrder!),
                    ),
                  ),

                // SOL ÜST: AKTİVİTE BULUTU
                if (character.activeActivity != null && character.isPresent)
                  Positioned(
                    left: 0, 
                    top: 5,
                    child: Draggable<GameItem>(
                      data: character.activeActivity,
                      feedback: _buildBubble(character.activeActivity!, isDragging: true),
                      child: _buildBubble(character.activeActivity!),
                    ),
                  ),
              ],
            );
          },
        );
      }
    );
  }

  // --- BULONCUK TASARIMI ---
  Widget _buildBubble(GameItem item, {bool isDragging = false}) {
    Color bubbleColor = Colors.white;
    
    if (item.orderStatus == OrderStatus.pending) {
      bubbleColor = Colors.yellow[100]!;
    } 
    else if (item.orderStatus == OrderStatus.preparing || 
             item.orderStatus == OrderStatus.processing) {
      bubbleColor = Colors.blue[100]!;
    } 
    else if (item.orderStatus == OrderStatus.ready) {
      bubbleColor = Colors.green[100]!;
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bubbleColor, 
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
          border: Border.all(color: Colors.brown[300]!, width: 1.5),
        ),
        child: Text(item.iconAsset, style: TextStyle(fontSize: isDragging ? 28 : 20)),
      ),
    );
  }

  Widget _buildThoughtBubble() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: const BoxConstraints(maxWidth: 140),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              border: Border.all(color: Colors.brown[100]!, width: 1),
            ),
            child: Text(
              character.activeThought!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.black87),
            ),
          ),
          CustomPaint(
            size: const Size(15, 10),
            painter: TrianglePainter(color: Colors.white, borderColor: Colors.brown[100]!),
          ),
        ],
      ),
    );
  }

  Widget _buildXpBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Lvl ${character.level}", style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (character.currentXp / character.requiredXp).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200], 
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange), 
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialDraggable(WidgetRef ref) {
    return Draggable<String>(
      data: character.id,
      maxSimultaneousDrags: character.socializingWith == null ? 1 : 0,
      feedback: _circleIcon(true),
      childWhenDragging: Opacity(opacity: 0.3, child: _circleIcon(false)),
      child: DragTarget<String>(
        onWillAccept: (incomingId) => incomingId != character.id && character.socializingWith == null,
        onAccept: (incomingId) => ref.read(gameProvider.notifier).startSocializing(incomingId, character.id),
        builder: (context, candidateData, _) => _circleIcon(candidateData.isNotEmpty),
      ),
    );
  }

  Widget _circleIcon(bool highlight) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: character.socializingWith != null ? Colors.pink[300] : (highlight ? Colors.green : Colors.blueAccent),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: const Icon(Icons.people, color: Colors.white, size: 18),
    );
  }

  Widget _buildRelationshipBar() {
    final partnerId = character.socializingWith!;
    double relLevel = character.relationships[partnerId] ?? 0.0;
    return Column(
      children: [
        Text("Bağ: %${(relLevel * 100).toInt()}", style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.pink)),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: relLevel,
            backgroundColor: Colors.pink[50],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.pink[300]!),
            minHeight: 3,
          ),
        ),
      ],
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  TrianglePainter({required this.color, required this.borderColor});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = color;
    var path = Path();
    path.moveTo(0, 0); path.lineTo(size.width / 2, size.height); path.lineTo(size.width, 0); path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 1);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}