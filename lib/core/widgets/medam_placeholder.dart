import 'package:flutter/material.dart';

class MedamPlaceholder extends StatelessWidget {
  const MedamPlaceholder({
    this.height = 18,
    this.width,
    this.borderRadius = 16,
    super.key,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class MedamListPlaceholder extends StatelessWidget {
  const MedamListPlaceholder({this.itemCount = 4, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemBuilder: (context, index) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MedamPlaceholder(height: 120, borderRadius: 24),
          SizedBox(height: 12),
          MedamPlaceholder(width: 180),
          SizedBox(height: 8),
          MedamPlaceholder(width: 260),
        ],
      ),
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemCount: itemCount,
    );
  }
}
