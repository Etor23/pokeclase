import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokeclase/models/generation_detail_response.dart';
import 'package:pokeclase/providers/poke_api_provider.dart';
import 'package:pokeclase/screens/pokemon_detail_screen.dart';
import 'package:provider/provider.dart';

class GenerationDetailScreen extends StatefulWidget {
  final int generationId;

  const GenerationDetailScreen({super.key, required this.generationId});

  @override
  State<GenerationDetailScreen> createState() => _GenerationDetailScreenState();
}

class _GenerationDetailScreenState extends State<GenerationDetailScreen> {
  //Se guarda el future para que al escribir en el buscador no se vuelva a pedir a la API
  late final Future<http.Response> _generationFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _generationFuture = Provider.of<PokeApiProvider>(context, listen: false).getGenerationDetail(widget.generationId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _spriteUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  //Filtra por nombre o por numero ("char", "25", "#025")
  bool _matches(PokemonSpeciesItem species) {
    final query = _query.trim().toLowerCase().replaceFirst('#', '');
    if (query.isEmpty) return true;
    final number = int.tryParse(query);
    if (number != null) return species.id == number;
    return species.name.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Generación ${widget.generationId}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: _SearchField(
              controller: _searchController,
              colorScheme: colorScheme,
              onChanged: (value) => setState(() => _query = value),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<http.Response>(
              future: _generationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
                  return const Center(child: Text('No data available'));
                } else {
                  final generationDetailResponse = GenerationDetailResponse.fromRawJson(snapshot.data!.body);
                  final speciesList = generationDetailResponse.pokemonSpecies.where(_matches).toList()
                    ..sort((a, b) => a.id.compareTo(b.id));
                  if (speciesList.isEmpty) {
                    return Center(
                      child: Text(
                        'No se encontró ningún Pokémon',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    //Oculta el teclado al hacer scroll en la cuadricula
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: speciesList.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, index) {
                      final species = speciesList[index];
                      return _PokemonCard(
                        id: species.id,
                        name: species.name,
                        imageUrl: _spriteUrl(species.id),
                        colorScheme: colorScheme,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PokemonDetailScreen(pokemonId: species.id, pokemonName: species.name),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colorScheme;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.colorScheme,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      cursorColor: colorScheme.primary,
      //El tema es oscuro, asi que forzamos texto oscuro sobre el campo blanco
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o número',
        hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
        prefixIcon: Icon(Icons.search, color: colorScheme.primary),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurface),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: colorScheme.onPrimary,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}

class _PokemonCard extends StatelessWidget {
  final int id;
  final String name;
  final String imageUrl;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _PokemonCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.onPrimary,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#${id.toString().padLeft(3, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name[0].toUpperCase() + name.substring(1),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.catching_pokemon, color: colorScheme.secondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}