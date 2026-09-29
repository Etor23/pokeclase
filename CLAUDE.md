# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`pokeclase` is a Flutter class project (Móviles 2) that browses the public PokeAPI (`https://pokeapi.co/api/v2`): list of generations → grid of Pokémon species in a generation → Pokémon detail. UI strings and code comments are in Spanish; keep that convention. Dart SDK `^3.13`, Material 3. Only the `android/` platform folder exists.

## Commands

```bash
flutter pub get                 # install dependencies
flutter run                     # run on a connected device/emulator
flutter analyze                 # lints (flutter_lints via analysis_options.yaml)
flutter test                    # run all tests
flutter test test/widget_test.dart            # run one test file
flutter test --plain-name "<test name>"       # run a single test by name
```

`test/widget_test.dart` is still the default counter template and does not match this app, so it fails until rewritten.

## Architecture

- **Entry / theming** — [lib/main.dart](lib/main.dart): `AppState` wraps the app in a `MultiProvider` that registers `PokeApiProvider` (non-lazy); `MyApp` holds the whole `ThemeData` (custom dark `ColorScheme` built from the `_K*` color constants). Screens pull colors from `Theme.of(context).colorScheme` rather than hardcoding.
- **Data access** — [lib/providers/poke_api_provider.dart](lib/providers/poke_api_provider.dart): a `ChangeNotifier` with methods that build `Uri.https('pokeapi.co', '/api/v2/...')` and return the raw `http.Response`. It holds no state; parsing happens in the screens.
- **Models** — `lib/models/*_response.dart`: hand-written classes with `fromRawJson(String)` (decode + delegate) and `fromJson(Map)` factories plus `toJson()`. List items (`GenerationItem`, `PokemonSpeciesItem`) derive their numeric `id` from the last path segment of the resource `url`. Follow this same pattern for new models. Per-language pieces that repeat across endpoints (`LocalizedName`, `EffectEntry`, `EffectChange`, `FlavorText` and the `find*` lookup helpers) live in [lib/models/shared_models.dart](lib/models/shared_models.dart) and are reused by the ability and move models.
- **Screens** — `lib/screens/`: each screen gets `PokeApiProvider` via `Provider.of<PokeApiProvider>(context, listen: false)` and uses a `FutureBuilder<http.Response>` with the waiting / error / no-data / data branches, parsing the body into a model in the data branch. Navigation is plain `Navigator.push(MaterialPageRoute(...))`, passing ids as constructor args.
  - Pokémon images come from the PokeAPI sprites repo (`official-artwork/<id>.png`) via `Image.network`, not from an API call.
  - Screens that need local state (`GenerationDetailScreen` search box, `PokemonDetailScreen` audio player) are `StatefulWidget`s that create the future once in `initState` so `setState` doesn't refetch; the rest are `StatelessWidget`s calling the provider inside `build`.
  - `GenerationListScreen` keeps a hardcoded `_generationInfo` map (region, national-dex range, starter ids) per generation id, since `/generation` only returns names/urls.
  - Pokémon detail links to ability and move detail (tap an ability/move chip → `AbilityDetailScreen` / `MoveDetailScreen`), and both link back (tap a Pokémon in their lists → `PokemonDetailScreen`).
- **Shared widgets** — [lib/widgets/detail_widgets.dart](lib/widgets/detail_widgets.dart): `SectionCard` (white card with title), `TagChip` (rounded tag, tappable when given `onTap`), `InfoTile` (big value + small label), the `typeColors` / `statNames` maps, `formatApiName` (`"special-attack"` → `"Special Attack"`) and `formatGeneration` (`"generation-iii"` → `"Generación III"`).
- **Localized API text** — PokeAPI returns `names` / `flavor_text_entries` / `effect_entries` per language. Models expose helpers like `localizedName('es')`, `flavorText('es')`, `effect('es')` returning `null` when missing; screens fall back to `'en'` (ability/move `effect_entries` almost never have Spanish). Move `power`/`accuracy`/`effect_chance`/`pp` can be `null` (status moves) and are shown as `—`.

## Current state / gotchas

- `PokemonDetailScreen` owns an `AudioPlayer` (audioplayers) that plays the Pokémon's cry (`.ogg` URL from the API), disposed in `dispose`.
- The app theme is `ColorScheme.dark`, so default text is light — widgets on white cards/fields must set `colorScheme.onSurface` explicitly (`SectionCard` does it via `DefaultTextStyle.merge`; the generation search `TextField` sets `style`).
- The `INTERNET` permission is only declared in the debug/profile Android manifests, not `android/app/src/main/AndroidManifest.xml`, so release builds can't reach the API.
- Constructors in newer files use the Dart primary-constructor-style `new(...)` declaration syntax (e.g. `const new({...})`); this is valid for the SDK version in use.
- The `.github/modernize/` folder is tooling output (Java-upgrade hooks), unrelated to the app.
