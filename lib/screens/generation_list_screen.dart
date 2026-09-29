import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokeclase/models/generation_list_response.dart';
import 'package:pokeclase/providers/poke_api_provider.dart';
import 'package:pokeclase/screens/generation_detail_screen.dart';
import 'package:pokeclase/widgets/detail_widgets.dart';
import 'package:provider/provider.dart';

//Datos fijos de cada generacion que no vienen en /generation (son solo 9 y no cambian)
class _GenerationInfo {
  final String region;
  final int firstId;
  final int lastId;
  final List<int> starterIds;

  const _GenerationInfo(this.region, this.firstId, this.lastId, this.starterIds);
}

const Map<int, _GenerationInfo> _generationInfo = {
  1: _GenerationInfo('Kanto', 1, 151, [1, 4, 7]),
  2: _GenerationInfo('Johto', 152, 251, [152, 155, 158]),
  3: _GenerationInfo('Hoenn', 252, 386, [252, 255, 258]),
  4: _GenerationInfo('Sinnoh', 387, 493, [387, 390, 393]),
  5: _GenerationInfo('Teselia', 494, 649, [495, 498, 501]),
  6: _GenerationInfo('Kalos', 650, 721, [650, 653, 656]),
  7: _GenerationInfo('Alola', 722, 809, [722, 725, 728]),
  8: _GenerationInfo('Galar', 810, 905, [810, 813, 816]),
  9: _GenerationInfo('Paldea', 906, 1025, [906, 909, 912]),
};

class GenerationListScreen extends StatelessWidget {
  const GenerationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Generaciones'),
      ),
      body: FutureBuilder<http.Response>(
        future : Provider.of<PokeApiProvider>(context, listen: false).getGenerations(),
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator(),);
          } else if(snapshot.hasError){
            return Center(child: Text('Error: ${snapshot.error}'),);
          } else if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
            return const Center(child: Text('Failed to load generations'),);
          } else {
            final generationListResponse = GenerationListResponse.fromJson(json.decode(snapshot.data!.body));
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: generationListResponse.results.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12,),
              itemBuilder: (context, index) {
                final generation = generationListResponse.results[index];
                return _GenerationCard(
                  title: formatGeneration(generation.name),
                  info: _generationInfo[generation.id],
                  colorScheme: colorScheme,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GenerationDetailScreen(generationId: generation.id)
                      )
                    );
                  },
                );
              },
            );
          }
        },
      )
    );
  }
}

class _GenerationCard extends StatelessWidget {
  final String title;
  //Puede ser null si la API agrega una generacion nueva que no esta en el mapa
  final _GenerationInfo? info;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _GenerationCard({
    required this.title,
    required this.info,
    required this.colorScheme,
    required this.onTap,
  });

  String _spriteUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  String _padId(int id) => id.toString().padLeft(3, '0');

  @override
  Widget build(BuildContext context) {
    final info = this.info;
    return Material(
      color: colorScheme.onPrimary,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            //Pokebola decorativa de fondo
            Positioned(
              right: -30,
              top: -30,
              child: Icon(
                Icons.catching_pokemon,
                size: 150,
                color: colorScheme.primary.withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      if (info != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '#${_padId(info.firstId)} – #${_padId(info.lastId)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        info?.region ?? title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: colorScheme.primary),
                    ],
                  ),
                  if (info != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: info.starterIds.map((id) {
                        return Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surface.withValues(alpha: 0.5),
                          ),
                          child: Image.network(
                            _spriteUrl(id),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.catching_pokemon, color: colorScheme.secondary),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
