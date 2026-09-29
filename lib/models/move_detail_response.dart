import 'dart:convert';

import 'package:pokeclase/models/shared_models.dart';

class MoveDetailResponse {
  final int id;
  final String name;
  //Los movimientos de estado no tienen potencia ni precision, vienen en null
  final int? accuracy;
  final int? effectChance;
  final int? pp;
  final int priority;
  final int? power;
  final String damageClass;
  final String type;
  final String target;
  final String generationName;
  final List<LocalizedName> names;
  final List<EffectEntry> effectEntries;
  final List<EffectChange> effectChanges;
  final List<FlavorText> flavorTextEntries;
  final List<MovePokemonItem> learnedByPokemon;
  final MoveMeta? meta;
  final List<MoveStatChange> statChanges;
  final List<MovePastValues> pastValues;

  new({
    required this.id,
    required this.name,
    this.accuracy,
    this.effectChance,
    this.pp,
    required this.priority,
    this.power,
    required this.damageClass,
    required this.type,
    required this.target,
    required this.generationName,
    required this.names,
    required this.effectEntries,
    required this.effectChanges,
    required this.flavorTextEntries,
    required this.learnedByPokemon,
    this.meta,
    required this.statChanges,
    required this.pastValues});

  //Metodo para recibir directamente el response
  factory MoveDetailResponse.fromRawJson(String str) => MoveDetailResponse.fromJson(json.decode(str));

  //Metodo para recibir el Map ya decodificado
  factory MoveDetailResponse.fromJson(Map<String, dynamic> json) {
    var names = json['names'] as List? ?? [];
    var effectEntries = json['effect_entries'] as List? ?? [];
    var effectChanges = json['effect_changes'] as List? ?? [];
    var flavorTextEntries = json['flavor_text_entries'] as List? ?? [];
    var learnedByPokemon = json['learned_by_pokemon'] as List? ?? [];
    var statChanges = json['stat_changes'] as List? ?? [];
    var pastValues = json['past_values'] as List? ?? [];

    return MoveDetailResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      accuracy: json['accuracy'],
      effectChance: json['effect_chance'],
      pp: json['pp'],
      priority: json['priority'] ?? 0,
      power: json['power'],
      damageClass: json['damage_class']?['name'] ?? '',
      type: json['type']?['name'] ?? '',
      target: json['target']?['name'] ?? '',
      generationName: json['generation']?['name'] ?? '',
      names: names.map((i) => LocalizedName.fromJson(i)).toList(),
      effectEntries: effectEntries.map((i) => EffectEntry.fromJson(i)).toList(),
      effectChanges: effectChanges.map((i) => EffectChange.fromJson(i)).toList(),
      flavorTextEntries: flavorTextEntries.map((i) => FlavorText.fromJson(i)).toList(),
      learnedByPokemon: learnedByPokemon.map((i) => MovePokemonItem.fromJson(i)).toList(),
      meta: json['meta'] == null ? null : MoveMeta.fromJson(json['meta']),
      statChanges: statChanges.map((i) => MoveStatChange.fromJson(i)).toList(),
      pastValues: pastValues.map((i) => MovePastValues.fromJson(i)).toList()
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'accuracy': accuracy,
    'effect_chance': effectChance,
    'pp': pp,
    'priority': priority,
    'power': power,
    'damage_class': {'name': damageClass},
    'type': {'name': type},
    'target': {'name': target},
    'generation': {'name': generationName},
    'names': names.map((x) => x.toJson()).toList(),
    'effect_entries': effectEntries.map((x) => x.toJson()).toList(),
    'effect_changes': effectChanges.map((x) => x.toJson()).toList(),
    'flavor_text_entries': flavorTextEntries.map((x) => x.toJson()).toList(),
    'learned_by_pokemon': learnedByPokemon.map((x) => x.toJson()).toList(),
    'meta': meta?.toJson(),
    'stat_changes': statChanges.map((x) => x.toJson()).toList(),
    'past_values': pastValues.map((x) => x.toJson()).toList()
  };

  String? localizedName(String language) => findLocalizedName(names, language);

  EffectEntry? effect(String language) => findEffect(effectEntries, language);

  String? flavorText(String language) => findFlavorText(flavorTextEntries, language);
}

//La API regresa {"name", "url"} directamente
class MovePokemonItem {
  final String name;
  final String url;

  new({
    required this.name,
    required this.url
  });

  factory MovePokemonItem.fromJson(Map<String, dynamic> json) {
    return MovePokemonItem(
      name: json['name'] ?? '',
      url: json['url'] ?? ''
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url
  };

  //Extraer el ID del pokemon desde la url
  int get id {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return int.parse(segments.last);
  }
}

//Detalles extra del movimiento: estado que causa, golpes, drenaje, criticos...
class MoveMeta {
  final String ailment;
  final String category;
  final int? minHits;
  final int? maxHits;
  final int? minTurns;
  final int? maxTurns;
  final int drain;
  final int healing;
  final int critRate;
  final int ailmentChance;
  final int flinchChance;
  final int statChance;

  new({
    required this.ailment,
    required this.category,
    this.minHits,
    this.maxHits,
    this.minTurns,
    this.maxTurns,
    required this.drain,
    required this.healing,
    required this.critRate,
    required this.ailmentChance,
    required this.flinchChance,
    required this.statChance
  });

  factory MoveMeta.fromJson(Map<String, dynamic> json) {
    return MoveMeta(
      ailment: json['ailment']?['name'] ?? 'none',
      category: json['category']?['name'] ?? '',
      minHits: json['min_hits'],
      maxHits: json['max_hits'],
      minTurns: json['min_turns'],
      maxTurns: json['max_turns'],
      drain: json['drain'] ?? 0,
      healing: json['healing'] ?? 0,
      critRate: json['crit_rate'] ?? 0,
      ailmentChance: json['ailment_chance'] ?? 0,
      flinchChance: json['flinch_chance'] ?? 0,
      statChance: json['stat_chance'] ?? 0
    );
  }

  Map<String, dynamic> toJson() => {
    'ailment': {'name': ailment},
    'category': {'name': category},
    'min_hits': minHits,
    'max_hits': maxHits,
    'min_turns': minTurns,
    'max_turns': maxTurns,
    'drain': drain,
    'healing': healing,
    'crit_rate': critRate,
    'ailment_chance': ailmentChance,
    'flinch_chance': flinchChance,
    'stat_chance': statChance
  };
}

//La API regresa {"change", "stat": {"name", "url"}}, change es positivo si sube y negativo si baja
class MoveStatChange {
  final String stat;
  final int change;

  new({
    required this.stat,
    required this.change
  });

  factory MoveStatChange.fromJson(Map<String, dynamic> json) {
    return MoveStatChange(
      stat: json['stat']?['name'] ?? '',
      change: json['change'] ?? 0
    );
  }

  Map<String, dynamic> toJson() => {
    'change': change,
    'stat': {'name': stat}
  };
}

//Valores que tenia el movimiento antes de cierto grupo de versiones (null = no cambio)
class MovePastValues {
  final int? accuracy;
  final int? effectChance;
  final int? power;
  final int? pp;
  final String? type;
  final String versionGroup;
  final List<EffectEntry> effectEntries;

  new({
    this.accuracy,
    this.effectChance,
    this.power,
    this.pp,
    this.type,
    required this.versionGroup,
    required this.effectEntries
  });

  factory MovePastValues.fromJson(Map<String, dynamic> json) {
    var entries = json['effect_entries'] as List? ?? [];
    return MovePastValues(
      accuracy: json['accuracy'],
      effectChance: json['effect_chance'],
      power: json['power'],
      pp: json['pp'],
      type: json['type']?['name'],
      versionGroup: json['version_group']?['name'] ?? '',
      effectEntries: entries.map((i) => EffectEntry.fromJson(i)).toList()
    );
  }

  Map<String, dynamic> toJson() => {
    'accuracy': accuracy,
    'effect_chance': effectChance,
    'power': power,
    'pp': pp,
    'type': type == null ? null : {'name': type},
    'version_group': {'name': versionGroup},
    'effect_entries': effectEntries.map((x) => x.toJson()).toList()
  };

  EffectEntry? effect(String language) => findEffect(effectEntries, language);
}
