// lib/utils/constants.dart
import 'package:flutter/material.dart';

// ── SortLab palette: midnight laboratory + glowing chemical orbs ────────
const Color kBg          = Color(0xFF0A1014);
const Color kSurface     = Color(0xFF131F28);
const Color kBorder      = Color(0xFF26394A);
const Color kAccent      = Color(0xFF1DE9B6); // lab teal
const Color kGlass       = Color(0x40FFFFFF);
const Color kGlassEdge   = Color(0x80B7D9E8);
const Color kTextPrimary = Color(0xFFEAF6F2);
const Color kTextDim     = Color(0xFF7E99A8);

const Color kStarOn  = Color(0xFFFFD54F);
const Color kStarOff = Color(0xFF22323E);

const Color kEasyColor   = Color(0xFF1DE9B6);
const Color kMediumColor = Color(0xFF4FC3F7);
const Color kHardColor   = Color(0xFFFF7043);

/// Orb colors, indexed by color id
const List<Color> kBallColors = [
  Color(0xFFFF5252), // red
  Color(0xFFFFA726), // orange
  Color(0xFFFFEE58), // yellow
  Color(0xFF66BB6A), // green
  Color(0xFF1DE9B6), // teal
  Color(0xFF29B6F6), // blue
  Color(0xFF7C4DFF), // violet
  Color(0xFFFF4081), // pink
  Color(0xFFB2FF59), // lime
  Color(0xFFA1887F), // taupe
];

const int kTotalLevels = 150;
const int kTubeCapacity = 4;

TextStyle techno(double size,
        {Color color = kTextPrimary,
        FontWeight weight = FontWeight.bold,
        double letterSpacing = 1.5}) =>
    TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing);
