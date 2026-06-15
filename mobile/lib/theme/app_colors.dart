import 'package:flutter/material.dart';

// ============================================================
//  Gradient — Card & Tombol
// ============================================================

// Gradient untuk Card (Ungu → Pink)
const LinearGradient cardGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
);

// Gradient untuk Tombol (Pink → Biru)
const LinearGradient buttonGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFEC4899), Color(0xFF60A5FA)],
);

// ============================================================
//  Mode Terang
// ============================================================

const Color lightBackground    = Color(0xFFF5F5F5); // abu sangat terang
const Color lightSurface       = Color(0xFFFFFFFF); // putih untuk card & container
const Color lightTextPrimary   = Color(0xFF111111); // hitam pekat untuk judul
const Color lightTextSecondary = Color(0xFF757575); // abu untuk teks sub/keterangan
const Color lightBorder        = Color(0xFFE0E0E0); // border netral
const Color lightIcon          = Color(0xFF424242); // ikon abu gelap

// ============================================================
//  Mode Gelap
// ============================================================

const Color darkBackground    = Color(0xFF121212); // standar Material dark
const Color darkSurface       = Color(0xFF1E1E1E); // surface card/container
const Color darkTextPrimary   = Color(0xFFEEEEEE); // putih lembut untuk judul
const Color darkTextSecondary = Color(0xFF9E9E9E); // abu untuk teks sub/keterangan
const Color darkBorder        = Color(0xFF2C2C2C); // border gelap
const Color darkIcon          = Color(0xFFBDBDBD); // ikon abu terang