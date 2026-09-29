import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokeclase/models/move_detail_response.dart';
import 'package:pokeclase/providers/poke_api_provider.dart';
import 'package:pokeclase/screens/pokemon_detail_screen.dart';
import 'package:pokeclase/widgets/detail_widgets.dart';
import 'package:provider/provider.dart';

//Clase de daño: nombre en español y color
const Map<String, String> _damageClassNames = {
  'physical': 'Físico',
  'special': 'Especial',
  'status': 'Estado',
};

const Map<String, Color> _damageClassColors = {
  'physical': Color(0xFFC92112),
  'special': Color(0xFF4F5870),
  'status': Color(0xFF8C888C),
};

const Map<String, String> _targetNames = {
  'specific-move': 'Un movimiento específico',
  'selected-pokemon-me-first': 'Un Pokémon elegido',
  'ally': 'Un aliado',
  'users-field': 'Lado del usuario',
  'user-or-ally': 'El usuario o un aliado',
  'opponents-field': 'Lado del rival',
  'user': 'El usuario',
  'random-opponent': 'Un rival al azar',
  'all-other-pokemon': 'Todos los demás Pokémon',
  'selected-pokemon': 'Un Pokémon elegido',
  'all-opponents': 'Todos los rivales',
  'entire-field': 'Todo el campo',
  'user-and-allies': 'El usuario y sus aliados',
  'all-pokemon': 'Todos los Pokémon',
  'all-allies': 'Todos los aliados',
  'fainting-pokemon': 'Pokémon debilitado',
};

const Map<String, String> _ailmentNames = {
  'paralysis': 'parálisis',
  'sleep': 'sueño',
  'freeze': 'congelación',
  'burn': 'quemadura',
  'poison': 'envenenamiento',
  'confusion': 'confusión',
  'infatuation': 'enamoramiento',
  'trap': 'atrapamiento',
  'nightmare': 'pesadilla',
  'torment': 'tormento',
  'disable': 'anulación',
  'yawn': 'bostezo',
  'heal-block': 'anticura',
  'leech-seed': 'drenadoras',
  'embargo': 'embargo',
  'perish-song': 'canto mortal',
  'ingrain': 'arraigo',
};

class MoveDetailScreen extends StatelessWidget {
  final int moveId;
  final String moveName;

  const MoveDetailScreen({super.key, required this.moveId, required this.moveName});

  //Los efectos viejos traen "$effect_chance" en el texto, lo cambiamos por el valor real
  String _fillEffectChance(String text, int? effectChance) =>
      effectChance == null ? text : text.replaceAll('\$effect_chance', '$effectChance');

  //Arma la lista de efectos secundarios a partir de meta, solo los que aplican
  List<String> _sideEffects(MoveDetailResponse move) {
    final meta = move.meta;
    if (meta == null) return [];
    final effects = <String>[];
    if (meta.ailment != 'none' && meta.ailment != 'unknown') {
      final ailment = _ailmentNames[meta.ailment] ?? formatApiName(meta.ailment).toLowerCase();
      effects.add(meta.ailmentChance > 0
          ? 'Puede causar $ailment (${meta.ailmentChance}%)'
          : 'Causa $ailment');
    }
    if (meta.flinchChance > 0) effects.add('Puede hacer retroceder al rival (${meta.flinchChance}%)');
    if (meta.critRate > 0) effects.add('Índice de golpe crítico aumentado (+${meta.critRate})');
    if (meta.drain > 0) effects.add('Recupera el ${meta.drain}% del daño causado');
    if (meta.drain < 0) effects.add('Recibe el ${-meta.drain}% del daño como retroceso');
    if (meta.healing > 0) effects.add('Recupera el ${meta.healing}% de sus PS máximos');
    if (meta.healing < 0) effects.add('Pierde el ${-meta.healing}% de sus PS máximos');
    if (meta.minHits != null && meta.maxHits != null) {
      effects.add(meta.minHits == meta.maxHits
          ? 'Golpea ${meta.minHits} veces'
          : 'Golpea de ${meta.minHits} a ${meta.maxHits} veces');
    }
    if (meta.minTurns != null && meta.maxTurns != null) {
      effects.add(meta.minTurns == meta.maxTurns
          ? 'Dura ${meta.minTurns} turnos'
          : 'Dura de ${meta.minTurns} a ${meta.maxTurns} turnos');
    }
    if (meta.statChance > 0) effects.add('Probabilidad de cambiar estadísticas: ${meta.statChance}%');
    return effects;
  }

  //Cambios de potencia, precision, etc. antes de un grupo de versiones
  String _pastValuesText(MovePastValues past) {
    final parts = <String>[
      if (past.power != null) 'Potencia ${past.power}',
      if (past.accuracy != null) 'Precisión ${past.accuracy}%',
      if (past.pp != null) 'PP ${past.pp}',
      if (past.effectChance != null) 'Prob. de efecto ${past.effectChance}%',
      if (past.type != null) 'Tipo ${formatApiName(past.type!)}',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(formatApiName(moveName)),
      ),
      body: FutureBuilder<http.Response>(
        future: Provider.of<PokeApiProvider>(context, listen: false).getMoveDetail(moveId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
            return const Center(child: Text('No se pudo cargar el movimiento'));
          } else {
            final move = MoveDetailResponse.fromRawJson(snapshot.data!.body);
            final spanishName = move.localizedName('es') ?? formatApiName(move.name);
            final englishName = move.localizedName('en') ?? formatApiName(move.name);
            final description = move.flavorText('es') ?? move.flavorText('en');
            //Casi ningun movimiento tiene el efecto en español, si no existe usamos el de ingles
            final spanishEffect = move.effect('es');
            final effect = spanishEffect ?? move.effect('en');
            final sideEffects = _sideEffects(move);
            final hasChanges = move.effectChanges.isNotEmpty || move.pastValues.isNotEmpty;
            final subtleText = TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6));

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _HeaderCard(
                  spanishName: spanishName,
                  englishName: englishName,
                  type: move.type,
                  damageClass: move.damageClass,
                  generation: formatGeneration(move.generationName),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Datos',
                  colorScheme: colorScheme,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          //Los movimientos de estado no tienen potencia ni precision
                          Expanded(child: InfoTile(label: 'Potencia', value: move.power?.toString() ?? '—', colorScheme: colorScheme)),
                          Expanded(child: InfoTile(label: 'Precisión', value: move.accuracy == null ? '—' : '${move.accuracy}%', colorScheme: colorScheme)),
                          Expanded(child: InfoTile(label: 'PP', value: move.pp?.toString() ?? '—', colorScheme: colorScheme)),
                          Expanded(child: InfoTile(label: 'Prioridad', value: move.priority > 0 ? '+${move.priority}' : '${move.priority}', colorScheme: colorScheme)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(Icons.gps_fixed, size: 18, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Objetivo: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(child: Text(_targetNames[move.target] ?? formatApiName(move.target))),
                        ],
                      ),
                    ],
                  ),
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
                              Text(
                                _fillEffectChance(effect.shortEffect!, move.effectChance),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(_fillEffectChance(effect.effect, move.effectChance), style: const TextStyle(height: 1.4)),
                            if (move.effectChance != null) ...[
                              const SizedBox(height: 8),
                              Text('Probabilidad de efecto: ${move.effectChance}%', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                            if (spanishEffect == null) ...[
                              const SizedBox(height: 8),
                              Text('Texto disponible solo en inglés', style: subtleText.copyWith(fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                ),
                if (move.statChanges.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Cambios en estadísticas',
                    colorScheme: colorScheme,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: move.statChanges.map((change) {
                        final isRaise = change.change > 0;
                        return TagChip(
                          text: '${statNames[change.stat] ?? formatApiName(change.stat)} ${isRaise ? '+' : ''}${change.change}',
                          color: isRaise ? const Color(0xFF388E3C) : const Color(0xFFD32F2F),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (sideEffects.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Efectos secundarios',
                    colorScheme: colorScheme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sideEffects.map((text) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.bolt, size: 18, color: colorScheme.primary),
                              const SizedBox(width: 6),
                              Expanded(child: Text(text)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (hasChanges) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Cambios en versiones anteriores',
                    colorScheme: colorScheme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...move.pastValues.map((past) {
                          final pastEffect = (past.effect('es') ?? past.effect('en'))?.effect;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Antes de ${formatApiName(past.versionGroup)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (_pastValuesText(past).isNotEmpty) Text(_pastValuesText(past)),
                                if (pastEffect != null) Text(pastEffect),
                              ],
                            ),
                          );
                        }),
                        ...move.effectChanges.map((change) {
                          final changeEffect = change.effect('es') ?? change.effect('en');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Antes de ${formatApiName(change.versionGroup)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(changeEffect?.effect ?? 'Sin detalle disponible'),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Pokémon que lo aprenden (${move.learnedByPokemon.length})',
                  colorScheme: colorScheme,
                  child: move.learnedByPokemon.isEmpty
                      ? const Text('Ningún Pokémon aprende este movimiento')
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: move.learnedByPokemon.map((p) {
                            return TagChip(
                              text: formatApiName(p.name),
                              color: colorScheme.primary,
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
  final String type;
  final String damageClass;
  final String generation;
  final ColorScheme colorScheme;

  const _HeaderCard({
    required this.spanishName,
    required this.englishName,
    required this.type,
    required this.damageClass,
    required this.generation,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = typeColors[type] ?? colorScheme.primary;
    return Material(
      color: colorScheme.onPrimary,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: typeColor.withValues(alpha: 0.2),
              ),
              child: Icon(Icons.flash_on, size: 40, color: typeColor),
            ),
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
                _Badge(text: formatApiName(type), color: typeColor),
                if (damageClass.isNotEmpty)
                  _Badge(
                    text: _damageClassNames[damageClass] ?? formatApiName(damageClass),
                    color: _damageClassColors[damageClass] ?? colorScheme.primary,
                  ),
                TagChip(text: generation, color: colorScheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//Etiqueta solida con texto blanco (tipo y clase de daño)
class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
