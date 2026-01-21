enum ItemType { coffee, book, laptop, catFood }

class GameItem {
  final String name;
  final ItemType type;
  final int xpValue; // Bu eşya kaç XP kazandırır?
  final String iconPath;

  GameItem({required this.name, required this.type, required this.xpValue, required this.iconPath});
}