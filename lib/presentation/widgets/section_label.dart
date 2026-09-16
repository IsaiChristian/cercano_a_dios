import 'package:flutter/material.dart';

import 'package:cercano_a_dios/ui/core/theme.dart';

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 24),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
  );
}
