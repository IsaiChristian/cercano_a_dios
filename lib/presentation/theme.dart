import 'package:flutter/material.dart';

const ink = Color(0xFF243F36);
const sage = Color(0xFFDAE5D9);
const cream = Color(0xFFF8F6EF);

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: cream,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ink,
    primary: ink,
    surface: cream,
  ),
  appBarTheme: const AppBarTheme(backgroundColor: cream, centerTitle: false),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontFamily: 'serif',
      fontSize: 38,
      height: 1.15,
      color: ink,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'serif',
      fontSize: 30,
      height: 1.2,
      color: ink,
    ),
    titleLarge: TextStyle(fontFamily: 'serif', fontSize: 24, color: ink),
    bodyLarge: TextStyle(fontSize: 17, height: 1.5, color: ink),
    bodyMedium: TextStyle(fontSize: 15, height: 1.4, color: ink),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
);
