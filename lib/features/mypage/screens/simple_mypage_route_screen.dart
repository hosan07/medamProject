import 'package:flutter/material.dart';

class SimpleMyPageRouteScreen extends StatelessWidget {
  const SimpleMyPageRouteScreen({
    required this.title,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            subtitle ?? '$title 화면은 다음 단계에서 상세 기능을 연결할게요.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
