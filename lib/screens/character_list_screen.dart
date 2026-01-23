import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../widgets/character_card.dart';

class CharacterListScreen extends ConsumerWidget {
  const CharacterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characters = ref.watch(gameProvider).characters;

    return Scaffold(
      appBar: AppBar(title: const Text("Tüm Müdavimler"), backgroundColor: Colors.brown),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, 
          childAspectRatio: 0.75,
          crossAxisSpacing: 10, 
          mainAxisSpacing: 10
        ),
        itemCount: characters.length,
        itemBuilder: (context, index) => CharacterCard(character: characters[index]),
      ),
    );
  }
}