import 'package:flutter/material.dart';

/// À passer à MaterialApp(navigatorKey: rootNavigatorKey). Permet de pousser
/// un écran depuis un endroit qui n'a pas de BuildContext — typiquement la
/// gestion des notifications, déclenchée en dehors de l'arbre de widgets.
final rootNavigatorKey = GlobalKey<NavigatorState>();
