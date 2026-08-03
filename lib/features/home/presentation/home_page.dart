import 'package:flutter/material.dart';

import 'widgets/circle_hero.dart';

/// THIRTY's product entry screen: the Circle Hero, the first true
/// emotional experience of the product (Playbook Ch.1 §3 — "The Circle is
/// not the app icon... it is the thing THIRTY is").
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: CircleHero()));
  }
}
