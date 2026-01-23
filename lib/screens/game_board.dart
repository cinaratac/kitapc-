import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../widgets/character_card.dart';
import '../widgets/item_card.dart'; 
import '../widgets/day_summary_overlay.dart';
import '../models/game_item.dart';
import '../models/character.dart';
import '../data/activity_items_data.dart'; // Aktivite verilerini içeren dosya

// --- SOSYAL BAĞLANTI ÇİZGİLERİNİ ÇİZEN RESSAM ---
class SocialLinePainter extends CustomPainter {
  final List<List<Offset>> connections;
  SocialLinePainter(this.connections);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pink.withOpacity(0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var connection in connections) {
      if (connection.length < 2) continue;
      
      final path = Path();
      path.moveTo(connection[0].dx, connection[0].dy);
      
      final controlX = (connection[0].dx + connection[1].dx) / 2;
      final controlY = ((connection[0].dy + connection[1].dy) / 2) - 100;
      
      path.quadraticBezierTo(controlX, controlY, connection[1].dx, connection[1].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GameBoard extends ConsumerStatefulWidget {
  @override
  ConsumerState<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends ConsumerState<GameBoard> {
  final PageController _pageController = PageController();
  final Map<String, GlobalKey> _cardKeys = {};

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final presentCharacters = gameState.characters.where((c) => c.isPresent).toList();

    // Karakterleri sayfalara böl (Her sayfada 4 karakter)
    List<List<Character>> characterPages = [];
    for (int i = 0; i < presentCharacters.length; i += 4) {
      characterPages.add(presentCharacters.sublist(
        i, (i + 4) > presentCharacters.length ? presentCharacters.length : i + 4));
    }
    if (characterPages.isEmpty) characterPages.add([]);

    String timeStr = "${gameState.gameTime.hour.toString().padLeft(2, '0')}:${gameState.gameTime.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // --- ÜST PANEL ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("KİTAPÇI SİMÜLASYONU", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                          Row(
                            children: [
                              Text(gameState.isShopOpen ? "🟢 AÇIK" : "🔴 KAPALI", 
                                style: const TextStyle(fontSize: 10)),
                              const SizedBox(width: 10),
                              // PARA GÖSTERGESİ (Yeni Eklendi)
                              Text("💰 ${gameState.totalBalance} TL", 
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                      Text(timeStr, 
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.brown)),
                    ],
                  ),
                ),

                // --- ANA OYUN ALANI ---
                Expanded(
                  flex: 4,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: characterPages.length,
                        itemBuilder: (context, pageIndex) {
                          final pageChars = characterPages[pageIndex];
                          
                          return Stack(
                            children: [
                              // KATMAN: Karakter Kartları Izgarası
                              GridView.builder(
                                padding: const EdgeInsets.fromLTRB(45, 80, 45, 20),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, 
                                  childAspectRatio: 0.65, 
                                  crossAxisSpacing: 15, 
                                  mainAxisSpacing: 15,
                                ),
                                itemCount: pageChars.length,
                                itemBuilder: (context, index) {
                                  final char = pageChars[index];
                                  _cardKeys[char.id] ??= GlobalKey(); 
                                  
                                  return CharacterCard(
                                    key: _cardKeys[char.id],
                                    character: char
                                  );
                                },
                              ),
                              
                              // KATMAN: Sosyal Çizgiler
                              IgnorePointer(
                                child: FutureBuilder(
                                  future: Future.delayed(Duration.zero),
                                  builder: (context, snapshot) {
                                    List<List<Offset>> connections = [];
                                    for (var char in pageChars) {
                                      if (char.socializingWith != null) {
                                        final partnerId = char.socializingWith!;
                                        if (pageChars.any((c) => c.id == partnerId)) {
                                          final startPos = _getWidgetPosition(char.id, context);
                                          final endPos = _getWidgetPosition(partnerId, context);
                                          if (startPos != null && endPos != null) {
                                            if (!connections.any((pair) => 
                                              pair.contains(startPos) && pair.contains(endPos))) {
                                              connections.add([startPos, endPos]);
                                            }
                                          }
                                        }
                                      }
                                    }
                                    return CustomPaint(
                                      size: Size.infinite,
                                      painter: SocialLinePainter(connections),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      
                      // SAYFA DEĞİŞTİRME TETİKLEYİCİLERİ
                      _buildPageTrigger(left: true, pageCount: characterPages.length),
                      _buildPageTrigger(left: false, pageCount: characterPages.length),
                    ],
                  ),
                ),

                // --- ALT MENÜ (Dinamik Eşya Listesi) ---
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.brown[100],
                    border: const Border(top: BorderSide(color: Colors.brown, width: 2)),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: allActivityItems.length, // data/activity_items_data.dart içindeki tüm eşyalar
                    itemBuilder: (context, index) {
                      final activity = allActivityItems[index];
                      
                      // Eşya satın alınmış mı kontrol et
                      final bool isUnlocked = gameState.unlockedActivityItems.contains(activity.type);
                      
                      // Gösterilecek GameItem objesini oluştur
                      final displayItem = GameItem(
                        id: 'item_${activity.type.name}',
                        name: activity.name,
                        type: activity.type,
                      );

                      return ItemCard(
                        item: displayItem, 
                        isLocked: !isUnlocked, // Satın alınmamışsa kilitli olarak gönder
                      );
                    },
                  ),
                ),
              ],
            ),

            // GÜN SONU ÖZETİ
            if (gameState.showDaySummary)
              const DaySummaryOverlay(),
          ],
        ),
      ),
    );
  }

  Offset? _getWidgetPosition(String id, BuildContext context) {
    final key = _cardKeys[id];
    if (key == null || key.currentContext == null) return null;
    final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
    final parentBox = context.findRenderObject() as RenderBox;
    return box.localToGlobal(
      Offset(box.size.width / 2, 19), 
      ancestor: parentBox
    );
  }

  Widget _buildPageTrigger({required bool left, required int pageCount}) {
    return Positioned(
      left: left ? 0 : null,
      right: left ? null : 0,
      top: 100,
      bottom: 120,
      width: 35, 
      child: DragTarget<Object>(
        onWillAccept: (data) {
          if (left && _pageController.page! > 0) {
            _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
          } else if (!left && _pageController.page! < pageCount - 1) {
            _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
          }
          return false; 
        },
        builder: (context, candidateData, _) {
          return Container(color: Colors.transparent);
        },
      ),
    );
  }
}