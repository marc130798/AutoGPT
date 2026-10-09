import 'package:flutter/material.dart';

/// Kleiner Ladekreis für Knöpfe, während eine Anfrage läuft.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) =>
      const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3));
}
