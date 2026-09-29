import 'dart:convert';

class PokemonDetailResponse {
  final int id;
  final String name;
  final int baseExperience;
  final int height;
  final int weight;
  final List<PokemonAbilitiesItem> pokemonAbilities;
  final String locationAreaEncounters;
  final List<PokemonMoveItem> moves;
  final PokemonSprites sprite;
  final List<PokemonStatItem> stats;
  final List<PokemonTypeItem> types;
  final PokemonCries cries;

  new({
    required this.id,
    required this.name,
    required this.baseExperience,
    required this.height,
    required this.weight,
    required this.pokemonAbilities,
    required this.locationAreaEncounters,
    required this.moves,
    required this.sprite,
    required this.stats,
    required this.types,
    required this.cries});

  //Metodo para recibir directamente el response
  factory PokemonDetailResponse.fromRawJson(String str) => PokemonDetailResponse.fromJson(json.decode(str));

  //Metodo para recibir el Map ya decodificado
  factory PokemonDetailResponse.fromJson(Map<String, dynamic> json) {
    var abilities = json['abilities'] as List? ?? [];
    var moves = json['moves'] as List? ?? [];
    var stats = json['stats'] as List? ?? [];
    var types = json['types'] as List? ?? [];

    return PokemonDetailResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      baseExperience: json['base_experience'] ?? 0,
      height: json['height'] ?? 0,
      weight: json['weight'] ?? 0,
      pokemonAbilities: abilities.map((i) => PokemonAbilitiesItem.fromJson(i)).toList(),
      locationAreaEncounters: json['location_area_encounters'] ?? '',
      moves: moves.map((i) => PokemonMoveItem.fromJson(i)).toList(),
      sprite: PokemonSprites.fromJson(json['sprites'] ?? {}),
      stats: stats.map((i) => PokemonStatItem.fromJson(i)).toList(),
      types: types.map((i) => PokemonTypeItem.fromJson(i)).toList(),
      cries: PokemonCries.fromJson(json['cries'] ?? {})
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'base_experience': baseExperience,
    'height': height,
    'weight': weight,
    'abilities': pokemonAbilities.map((x) => x.toJson()).toList(),
    'location_area_encounters': locationAreaEncounters,
    'moves': moves.map((x) => x.toJson()).toList(),
    'sprites': sprite.toJson(),
    'stats': stats.map((x) => x.toJson()).toList(),
    'types': types.map((x) => x.toJson()).toList(),
    'cries': cries.toJson()
  };
}

//La API regresa {"ability": {"name", "url"}, "is_hidden", "slot"}
class PokemonAbilitiesItem {
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

  factory PokemonAbilitiesItem.fromJson(Map<String, dynamic> json) {
    final ability = json['ability'] ?? {};
    return PokemonAbilitiesItem(
      name: ability['name'] ?? '',
      url: ability['url'] ?? '',
      isHidden: json['is_hidden'] ?? false,
      slot: json['slot'] ?? 0
    );
  }

  Map<String, dynamic> toJson() => {
    'ability': {'name': name, 'url': url},
    'is_hidden': isHidden,
    'slot': slot
  };

  //Extraer el ID de la habilidad desde la url
  int get id {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return int.parse(segments.last);
  }
}

//La API regresa {"move": {"name", "url"}, "version_group_details": [...]}, solo guardamos el movimiento
class PokemonMoveItem {
  final String name;
  final String url;

  new({
    required this.name,
    required this.url
  });

  factory PokemonMoveItem.fromJson(Map<String, dynamic> json) {
    final move = json['move'] ?? {};
    return PokemonMoveItem(
      name: move['name'] ?? '',
      url: move['url'] ?? ''
    );
  }

  Map<String, dynamic> toJson() => {
    'move': {'name': name, 'url': url}
  };

  //Extraer el ID del movimiento desde la url
  int get id {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return int.parse(segments.last);
  }
}

//Los sprites pueden venir en null, por eso todos son opcionales
class PokemonSprites {
  final String? frontDefault;
  final String? frontShiny;
  final String? backDefault;
  final String? backShiny;
  final String? officialArtwork;
  final String? officialArtworkShiny;

  new({
    this.frontDefault,
    this.frontShiny,
    this.backDefault,
    this.backShiny,
    this.officialArtwork,
    this.officialArtworkShiny
  });

  factory PokemonSprites.fromJson(Map<String, dynamic> json) {
    final artwork = json['other']?['official-artwork'] ?? {};
    return PokemonSprites(
      frontDefault: json['front_default'],
      frontShiny: json['front_shiny'],
      backDefault: json['back_default'],
      backShiny: json['back_shiny'],
      officialArtwork: artwork['front_default'],
      officialArtworkShiny: artwork['front_shiny']
    );
  }

  Map<String, dynamic> toJson() => {
    'front_default': frontDefault,
    'front_shiny': frontShiny,
    'back_default': backDefault,
    'back_shiny': backShiny,
    'other': {
      'official-artwork': {
        'front_default': officialArtwork,
        'front_shiny': officialArtworkShiny
      }
    }
  };
}

//La API regresa {"base_stat", "effort", "stat": {"name", "url"}}
class PokemonStatItem {
  final String name;
  final String url;
  final int baseStat;
  final int effort;

  new({
    required this.name,
    required this.url,
    required this.baseStat,
    required this.effort
  });

  factory PokemonStatItem.fromJson(Map<String, dynamic> json) {
    final stat = json['stat'] ?? {};
    return PokemonStatItem(
      name: stat['name'] ?? '',
      url: stat['url'] ?? '',
      baseStat: json['base_stat'] ?? 0,
      effort: json['effort'] ?? 0
    );
  }

  Map<String, dynamic> toJson() => {
    'base_stat': baseStat,
    'effort': effort,
    'stat': {'name': name, 'url': url}
  };
}

//La API regresa {"slot", "type": {"name", "url"}}
class PokemonTypeItem {
  final String name;
  final String url;
  final int slot;

  new({
    required this.name,
    required this.url,
    required this.slot
  });

  factory PokemonTypeItem.fromJson(Map<String, dynamic> json) {
    final type = json['type'] ?? {};
    return PokemonTypeItem(
      name: type['name'] ?? '',
      url: type['url'] ?? '',
      slot: json['slot'] ?? 0
    );
  }

  Map<String, dynamic> toJson() => {
    'slot': slot,
    'type': {'name': name, 'url': url}
  };
}

//Urls de los archivos de audio (.ogg) con el grito del pokemon
class PokemonCries {
  final String? latest;
  final String? legacy;

  new({
    this.latest,
    this.legacy
  });

  factory PokemonCries.fromJson(Map<String, dynamic> json) {
    return PokemonCries(
      latest: json['latest'],
      legacy: json['legacy']
    );
  }

  Map<String, dynamic> toJson() => {
    'latest': latest,
    'legacy': legacy
  };
}
