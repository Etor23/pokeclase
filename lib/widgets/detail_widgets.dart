import 'package:flutter/material.dart';

//Widgets compartidos por las pantallas de detalle (pokemon, habilidad, movimiento)

//Colores oficiales de cada tipo
const Map<String, Color> typeColors = {
  'normal': Color(0xFFA8A77A),
  'fire': Color(0xFFEE8130),
  'water': Color(0xFF6390F0),
  'electric': Color(0xFFF7D02C),
  'grass': Color(0xFF7AC74C),
  'ice': Color(0xFF96D9D6),
  'fighting': Color(0xFFC22E28),
  'poison': Color(0xFFA33EA1),
  'ground': Color(0xFFE2BF65),
  'flying': Color(0xFFA98FF3),
  'psychic': Color(0xFFF95587),
  'bug': Color(0xFFA6B91A),
  'rock': Color(0xFFB6A136),
  'ghost': Color(0xFF735797),
  'dragon': Color(0xFF6F35FC),
  'dark': Color(0xFF705746),
  'steel': Color(0xFFB7B7CE),
  'fairy': Color(0xFFD685AD),
};

const Map<String, String> statNames = {
  'hp': 'PS',
  'attack': 'Ataque',
  'defense': 'Defensa',
  'special-attack': 'At. Esp.',
  'special-defense': 'Def. Esp.',
  'speed': 'Velocidad',
  //Solo aparecen en movimientos que las modifican
  'accuracy': 'Precisión',
  'evasion': 'Evasión',
};

//"special-attack" -> "Special Attack"
String formatApiName(String name) => name
    .split('-')
    .where((s) => s.isNotEmpty)
    .map((s) => s[0].toUpperCase() + s.substring(1))
    .join(' ');

//"generation-iii" -> "Generación III"
String formatGeneration(String generation) =>
    'Generación ${generation.replaceFirst('generation-', '').toUpperCase()}';

class SectionCard extends StatelessWidget {
  final String title;
  final ColorScheme colorScheme;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    required this.colorScheme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.onPrimary,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        //El tema es oscuro, asi que forzamos texto oscuro sobre la tarjeta blanca
        child: DefaultTextStyle.merge(
          style: TextStyle(color: colorScheme.onSurface),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

//Etiqueta redondeada, si recibe onTap se puede presionar y muestra una flecha
class TagChip extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const TagChip({super.key, required this.text, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20);
    return Material(
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(left: 10, right: onTap == null ? 10 : 4, top: 4, bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              if (onTap != null) Icon(Icons.chevron_right, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

//Valor grande con una etiqueta chica debajo (ej. "1.7 m" / "Altura")
class InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const InfoTile({
    super.key,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}
