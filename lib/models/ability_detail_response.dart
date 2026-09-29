import 'dart:convert';

import 'package:pokeclase/models/shared_models.dart';

class AbilityDetailResponse {
  final int id;
  final String name;
  final bool isMainSeries;
  final String generationName;
  final String generationUrl;
  final List<LocalizedName> names;
  final List<EffectEntry> effectEntries;
  final List<EffectChange> effectChanges;
  final List<FlavorText> flavorTextEntries;
  final List<AbilityPokemonItem> pokemon;

  new({
    required this.id,
    required this.name,
    required this.isMainSeries,
    required this.generationName,
    required this.generationUrl,
    required this.names,
    required this.effectEntries,
    required this.effectChanges,
    required this.flavorTextEntries,
    required this.pokemon});

  //Metodo para recibir directamente el response
  factory AbilityDetailResponse.fromRawJson(String str) => AbilityDetailResponse.fromJson(json.decode(str));

  //Metodo para recibir el Map ya decodificado
  factory AbilityDetailResponse.fromJson(Map<String, dynamic> json) {
    var names = json['names'] as List? ?? [];
    var effectEntries = json['effect_entries'] as List? ?? [];
    var effectChanges = json['effect_changes'] as List? ?? [];
    var flavorTextEntries = json['flavor_text_entries'] as List? ?? [];
    var pokemon = json['pokemon'] as List? ?? [];
    final generation = json['generation'] ?? {};

    return AbilityDetailResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isMainSeries: json['is_main_series'] ?? false,
      generationName: generation['name'] ?? '',
      generationUrl: generation['url'] ?? '',
      names: names.map((i) => LocalizedName.fromJson(i)).toList(),
      effectEntries: effectEntries.map((i) => EffectEntry.fromJson(i)).toList(),
      effectChanges: effectChanges.map((i) => EffectChange.fromJson(i)).toList(),
      flavorTextEntries: flavorTextEntries.map((i) => FlavorText.fromJson(i)).toList(),
      pokemon: pokemon.map((i) => AbilityPokemonItem.fromJson(i)).toList()
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'is_main_series': isMainSeries,
    'generation': {'name': generationName, 'url': generationUrl},
    'names': names.map((x) => x.toJson()).toList(),
    'effect_entries': effectEntries.map((x) => x.toJson()).toList(),
    'effect_changes': effectChanges.map((x) => x.toJson()).toList(),
    'flavor_text_entries': flavorTextEntries.map((x) => x.toJson()).toList(),
    'pokemon': pokemon.map((x) => x.toJson()).toList()
  };

  String? localizedName(String language) => findLocalizedName(names, language);

  EffectEntry? effect(String language) => findEffect(effectEntries, language);

  String? flavorText(String language) => findFlavorText(flavorTextEntries, language);
}

//La API regresa {"is_hidden", "slot", "pokemon": {"name", "url"}}
class AbilityPokemonItem {
  final String name;
  final String url;
  final bool isHidden;
  final int slot;

  new({
    required this.name,
    required this.url,
    required this.isHidden,
    required this.slot
  });

  factory AbilityPokemonItem.fromJson(Map<String, dynamic> json) {
    final pokemon = json['pokemon'] ?? {};
    return AbilityPokemonItem(
      name: pokemon['name'] ?? '',
      url: pokemon['url'] ?? '',
      isHidden: json['is_hidden'] ?? false,
      slot: json['slot'] ?? 0
    );
  }

  Map<String, dynamic> toJson() => {
    'is_hidden': isHidden,
    'slot': slot,
    'pokemon': {'name': name, 'url': url}
  };

  //Extraer el ID del pokemon desde la url
  int get id {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return int.parse(segments.last);
  }
}
