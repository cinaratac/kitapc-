import 'package:flutter/material.dart';
import '../models/game_item.dart';

class ItemCard extends StatelessWidget {
  final GameItem item;

  const ItemCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Draggable: Sürüklenebilen nesne
    return Draggable<GameItem>(
      data: item, // Sürüklenen veri bu
      feedback: Material( // Sürüklenirken havada görünen hayalet
        color: Colors.transparent,
        child: Icon(Icons.coffee, size: 50, color: Colors.brown), // Resim gelince değişecek
      ),
      childWhenDragging: Opacity( // Sürüklenirken arkada kalan boşluk
        opacity: 0.5,
        child: _buildItemBox(), 
      ),
      child: _buildItemBox(), // Normal duruşu
    );
  }

  Widget _buildItemBox() {
    return Container(
      width: 80,
      height: 80,
      margin: EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.brown),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.coffee, size: 30), // Buraya item.iconPath gelecek
          Text(item.name, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}