import 'package:flutter/material.dart';

const profileIconLabels = {
  'leaf': '잎',
  'heart': '하트',
  'spark': '별',
  'run': '운동',
};

const backgroundLabels = {
  'green': '그린',
  'mint': '민트',
  'black': '블랙',
  'coral': '코랄',
};

IconData profileIconData(String value) {
  return switch (value) {
    'heart' => Icons.favorite_rounded,
    'spark' => Icons.auto_awesome_rounded,
    'run' => Icons.directions_run_rounded,
    _ => Icons.eco_rounded,
  };
}

LinearGradient profileBackgroundGradient(String value) {
  return switch (value) {
    'mint' => const LinearGradient(
      colors: [Color(0xFFB8F3DD), Color(0xFF76D8C4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'black' => const LinearGradient(
      colors: [Color(0xFF25282D), Color(0xFF111315)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'coral' => const LinearGradient(
      colors: [Color(0xFFFFB2A2), Color(0xFFFF7F6E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    _ => const LinearGradient(
      colors: [Color(0xFF4CAF82), Color(0xFF8AD7A8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  };
}

class PresetAvatar extends StatelessWidget {
  const PresetAvatar({required this.icon, this.size = 76, super.key});

  final String icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 4,
        ),
      ),
      child: Icon(
        profileIconData(icon),
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        size: size * 0.42,
      ),
    );
  }
}
