import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokeclase/models/pokemon_detail_response.dart';
import 'package:pokeclase/providers/poke_api_provider.dart';
import 'package:pokeclase/screens/ability_detail_screen.dart';
import 'package:pokeclase/screens/move_detail_screen.dart';
import 'package:pokeclase/widgets/detail_widgets.dart';
import 'package:provider/provider.dart';

class PokemonDetailScreen extends StatefulWidget {
  final int pokemonId;
  final String pokemonName;

  const new({super.key, required this.pokemonId, required this.pokemonName});

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  //Se guarda el future para no volver a pedir los datos en cada rebuild
  late final Future<http.Response> _pokemonFuture;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _pokemonFuture = Provider.of<PokeApiProvider>(context, listen: false).getPokemonDetail(widget.pokemonId);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playCry(String url) async {
    await _player.stop();
    await _player.play(UrlSource(url));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(formatApiName(widget.pokemonName)),
      ),
      body: FutureBuilder<http.Response>(
        future: _pokemonFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
            return const Center(child: Text('No se pudo cargar el Pokémon'));
          } else {
            final pokemon = PokemonDetailResponse.fromRawJson(snapshot.data!.body);
            final cryUrl = pokemon.cries.latest ?? pokemon.cries.legacy;
            final totalStats = pokemon.stats.fold<int>(0, (sum, s) => sum + s.baseStat);
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _HeaderCard(
                  pokemon: pokemon,
                  colorScheme: colorScheme,
                  onPlayCry: cryUrl == null ? null : () => _playCry(cryUrl),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Información',
                  colorScheme: colorScheme,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      //La altura viene en decimetros y el peso en hectogramos
                      InfoTile(label: 'Altura', value: '${(pokemon.height / 10).toStringAsFixed(1)} m', colorScheme: colorScheme),
                      InfoTile(label: 'Peso', value: '${(pokemon.weight / 10).toStringAsFixed(1)} kg', colorScheme: colorScheme),
                      InfoTile(label: 'Exp. base', value: '${pokemon.baseExperience}', colorScheme: colorScheme),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Habilidades',
                  colorScheme: colorScheme,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pokemon.pokemonAbilities
                        .map((a) => TagChip(
                              text: a.isHidden ? '${formatApiName(a.name)} (oculta)' : formatApiName(a.name),
                              color: colorScheme.primary,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AbilityDetailScreen(abilityId: a.id, abilityName: a.name),
                                  ),
                                );
                              },
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Estadísticas base',
                  colorScheme: colorScheme,
                  child: Column(
                    children: [
                      ...pokemon.stats.map((s) => _StatBar(stat: s, colorScheme: colorScheme)),
                      const Divider(),
                      Row(
                        children: [
                          const SizedBox(width: 80, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                          Text('$totalStats', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Movimientos (${pokemon.moves.length})',
                  colorScheme: colorScheme,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: pokemon.moves
                        .map((m) => TagChip(
                              text: formatApiName(m.name),
                              color: colorScheme.onSurface,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MoveDetailScreen(moveId: m.id, moveName: m.name),
                                  ),
                                );
                              },
                            ))
                        .toList(),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final PokemonDetailResponse pokemon;
  final ColorScheme colorScheme;
  final VoidCallback? onPlayCry;

  const _HeaderCard({
    required this.pokemon,
    required this.colorScheme,
    required this.onPlayCry,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = pokemon.sprite.officialArtwork ?? pokemon.sprite.frontDefault;
    final mainTypeColor = pokemon.types.isEmpty
        ? colorScheme.primary
        : typeColors[pokemon.types.first.name] ?? colorScheme.primary;

    return Material(
      color: colorScheme.onPrimary,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mainTypeColor.withValues(alpha: 0.2),
              ),
              child: imageUrl == null
                  ? Icon(Icons.catching_pokemon, size: 80, color: colorScheme.secondary)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.catching_pokemon, size: 80, color: colorScheme.secondary),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              '#${pokemon.id.toString().padLeft(3, '0')}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            Text(
              formatApiName(pokemon.name),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: pokemon.types.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColors[t.name] ?? colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    formatApiName(t.name),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onPlayCry,
              icon: const Icon(Icons.volume_up),
              label: const Text('Escuchar grito'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final PokemonStatItem stat;
  final ColorScheme colorScheme;

  const _StatBar({required this.stat, required this.colorScheme});

  //255 es el valor base maximo que puede tener una estadistica
  static const int _maxStat = 255;

  Color get _barColor {
    if (stat.baseStat < 50) return const Color(0xFFE57373);
    if (stat.baseStat < 90) return const Color(0xFFFFB74D);
    return const Color(0xFF81C784);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(statNames[stat.name] ?? formatApiName(stat.name))),
          SizedBox(
            width: 36,
            child: Text('${stat.baseStat}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stat.baseStat / _maxStat,
                minHeight: 8,
                color: _barColor,
                backgroundColor: colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
