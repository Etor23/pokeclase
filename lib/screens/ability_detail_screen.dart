import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokeclase/models/ability_detail_response.dart';
import 'package:pokeclase/providers/poke_api_provider.dart';
import 'package:pokeclase/screens/pokemon_detail_screen.dart';
import 'package:pokeclase/widgets/detail_widgets.dart';
import 'package:provider/provider.dart';

class AbilityDetailScreen extends StatelessWidget {
  final int abilityId;
  final String abilityName;

  const AbilityDetailScreen({super.key, required this.abilityId, required this.abilityName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(formatApiName(abilityName)),
      ),
      body: FutureBuilder<http.Response>(
        future: Provider.of<PokeApiProvider>(context, listen: false).getAbilityDetail(abilityId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
            return const Center(child: Text('No se pudo cargar la habilidad'));
          } else {
            final ability = AbilityDetailResponse.fromRawJson(snapshot.data!.body);
            final spanishName = ability.localizedName('es') ?? formatApiName(ability.name);
            final englishName = ability.localizedName('en') ?? formatApiName(ability.name);
            final description = ability.flavorText('es') ?? ability.flavorText('en');
            //Casi ninguna habilidad tiene el efecto en español, si no existe usamos el de ingles
            final spanishEffect = ability.effect('es');
            final effect = spanishEffect ?? ability.effect('en');

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _HeaderCard(
                  spanishName: spanishName,
                  englishName: englishName,
                  generation: formatGeneration(ability.generationName),
                  isMainSeries: ability.isMainSeries,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Descripción',
                  colorScheme: colorScheme,
                  child: Text(
                    description ?? 'Sin descripción disponible',
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Efecto',
                  colorScheme: colorScheme,
                  child: effect == null
                      ? const Text('Sin efecto disponible')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (effect.shortEffect != null) ...[
                              Text(effect.shortEffect!, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                            ],
                            Text(effect.effect, style: const TextStyle(height: 1.4)),
                            if (spanishEffect == null) ...[
                              const SizedBox(height: 8),
                              
                            ],
                          ],
                        ),
                ),
                if (ability.effectChanges.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Cambios en versiones anteriores',
                    colorScheme: colorScheme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: ability.effectChanges.map((change) {
                        final changeEffect = change.effect('es') ?? change.effect('en');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Antes de ${formatApiName(change.versionGroup)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(changeEffect?.effect ?? 'Sin detalle disponible'),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Pokémon con esta habilidad (${ability.pokemon.length})',
                  colorScheme: colorScheme,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ability.pokemon.map((p) {
                      return TagChip(
                        text: p.isHidden ? '${formatApiName(p.name)} (oculta)' : formatApiName(p.name),
                        color: p.isHidden ? colorScheme.onSurface : colorScheme.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PokemonDetailScreen(pokemonId: p.id, pokemonName: p.name),
                            ),
                          );
                        },
                      );
                    }).toList(),
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
  final String spanishName;
  final String englishName;
  final String generation;
  final bool isMainSeries;
  final ColorScheme colorScheme;

  const _HeaderCard({
    required this.spanishName,
    required this.englishName,
    required this.generation,
    required this.isMainSeries,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.onPrimary,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.auto_awesome, size: 48, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              spanishName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            if (englishName != spanishName)
              Text(
                englishName,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                TagChip(text: generation, color: colorScheme.primary),
                if (isMainSeries) TagChip(text: 'Serie principal', color: colorScheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
