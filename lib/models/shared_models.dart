//Clases que se repiten en varias respuestas de la API (habilidades, movimientos)

//Nombre traducido: {"name", "language": {"name", "url"}}
class LocalizedName {
  final String name;
  final String language;

  new({
    required this.name,
    required this.language
  });

  factory LocalizedName.fromJson(Map<String, dynamic> json) {
    return LocalizedName(
      name: json['name'] ?? '',
      language: json['language']?['name'] ?? ''
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'language': {'name': language}
  };
}

//short_effect no viene en los effect_changes, por eso es opcional
class EffectEntry {
  final String effect;
  final String? shortEffect;
  final String language;

  new({
    required this.effect,
    this.shortEffect,
    required this.language
  });

  factory EffectEntry.fromJson(Map<String, dynamic> json) {
    return EffectEntry(
      effect: json['effect'] ?? '',
      shortEffect: json['short_effect'],
      language: json['language']?['name'] ?? ''
    );
  }

  Map<String, dynamic> toJson() => {
    'effect': effect,
    'short_effect': shortEffect,
    'language': {'name': language}
  };
}

//Efecto que tenia antes de cierto grupo de versiones
class EffectChange {
  final String versionGroup;
  final List<EffectEntry> effectEntries;

  new({
    required this.versionGroup,
    required this.effectEntries
  });

  factory EffectChange.fromJson(Map<String, dynamic> json) {
    var entries = json['effect_entries'] as List? ?? [];
    return EffectChange(
      versionGroup: json['version_group']?['name'] ?? '',
      effectEntries: entries.map((i) => EffectEntry.fromJson(i)).toList()
    );
  }

  Map<String, dynamic> toJson() => {
    'version_group': {'name': versionGroup},
    'effect_entries': effectEntries.map((x) => x.toJson()).toList()
  };

  EffectEntry? effect(String language) => findEffect(effectEntries, language);
}

class FlavorText {
  final String flavorText;
  final String language;
  final String versionGroup;

  new({
    required this.flavorText,
    required this.language,
    required this.versionGroup
  });

  factory FlavorText.fromJson(Map<String, dynamic> json) {
    return FlavorText(
      //El texto viene con saltos de linea del juego (\n, \f), los cambiamos por espacios
      flavorText: (json['flavor_text'] ?? '').replaceAll(RegExp(r'\s+'), ' '),
      language: json['language']?['name'] ?? '',
      versionGroup: json['version_group']?['name'] ?? ''
    );
  }

  Map<String, dynamic> toJson() => {
    'flavor_text': flavorText,
    'language': {'name': language},
    'version_group': {'name': versionGroup}
  };
}

//Nombre en el idioma pedido ('es', 'en', ...), si no existe regresa null
String? findLocalizedName(List<LocalizedName> names, String language) {
  for (final n in names) {
    if (n.language == language) return n.name;
  }
  return null;
}

//Efecto en el idioma pedido, si no existe regresa null
EffectEntry? findEffect(List<EffectEntry> entries, String language) {
  for (final e in entries) {
    if (e.language == language) return e;
  }
  return null;
}

//Descripcion del juego mas reciente en el idioma pedido (la ultima de la lista)
String? findFlavorText(List<FlavorText> entries, String language) {
  final matches = entries.where((f) => f.language == language);
  return matches.isEmpty ? null : matches.last.flavorText;
}
