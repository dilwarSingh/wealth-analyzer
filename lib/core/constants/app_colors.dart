import 'package:flutter/material.dart';

/// Central design system color palette for Wealth Analyzer.
/// Sleek Dark Mode with Glassmorphism, Crimson Red CTAs, and Luxe Gold accents.
class AppColors {
  // Canvas & Backgrounds
  static const Color canvas = Color(0xFF0B0F19); // Deep Dark Slate
  static const Color surface = Color(0xFF111827); // Dark Surface
  static const Color surfaceGlass = Color(0xCC111827); // 80% opacity dark glass
  static const Color surfaceCard = Color(0xFF151D30); // Elevated Card
  static const Color surfaceLight = Color(0xFF1E293B); // Input / Slate highlight

  // Brand Accents
  static const Color crimson = Color(0xFFEF4444); // Crimson Red Primary CTA
  static const Color crimsonHover = Color(0xFFDC2626);
  static const Color crimsonLight = Color(0xFFFCA5A5);
  static const Color crimsonGlow = Color(0x4DEF4444);

  static const Color gold = Color(0xFFF59E0B); // Luxe Gold
  static const Color goldDark = Color(0xFFD97706);
  static const Color goldLight = Color(0xFFFDE68A);
  static const Color goldGlow = Color(0x4DF59E0B);

  // Financial Indicators
  static const Color profit = Color(0xFF10B981); // Emerald Green
  static const Color profitLight = Color(0xFF6EE7B7);
  static const Color profitGlow = Color(0x3310B981);

  static const Color loss = Color(0xFFF43F5E); // Rose / Loss
  static const Color lossLight = Color(0xFFFDA4AF);

  // Decorative Accent Palettes
  static const Color info = Color(0xFF38BDF8); // Cyan / Info
  static const Color indigo = Color(0xFF6366F1); // Royal Indigo
  static const Color purple = Color(0xFFA855F7); // Violet

  // Neutral Text & Icons
  static const Color textPrimary = Color(0xFFF8FAFC); // High emphasis white
  static const Color textSecondary = Color(0xFF94A3B8); // Medium emphasis slate
  static const Color textMuted = Color(0xFF64748B); // Low emphasis slate
  static const Color textDisabled = Color(0xFF475569);

  // Borders & Dividers
  static const Color border = Color(0xFF1E293B);
  static const Color borderSubtle = Color(0xFF334155);
  static const Color borderGlass = Color(0x3394A3B8);
  static const Color borderGold = Color(0x66F59E0B);
  static const Color borderCrimson = Color(0x66EF4444);

  // Category Color Map for Visualizations (distinct 8-color palette)
  static const Color catEquities = Color(0xFF38BDF8); // Sky Blue (#38BDF8)
  static const Color catMutualFunds = Color(0xFF818CF8); // Indigo / Violet (#818CF8)
  static const Color catRealEstate = Color(0xFFF97316); // Warm Terracotta / Orange (#F97316)
  static const Color catCrypto = Color(0xFFA855F7); // Vibrant Purple (#A855F7)
  static const Color catFixedDeposit = Color(0xFF06B6D4); // Cyan / Deep Teal (#06B6D4)
  static const Color catCashSavings = Color(0xFF10B981); // Emerald Green (#10B981)
  static const Color catGoldPrecious = Color(0xFFEAB308); // Luxe Gold / Yellow (#EAB308)
  static const Color catOther = Color(0xFF94A3B8); // Slate / Silver (#94A3B8)
}
