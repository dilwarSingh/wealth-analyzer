# AGENT.md - Wealth Analyzer Engineering & Operating Handbook

Welcome to the **Wealth Analyzer** codebase. This document serves as the primary technical specification, architectural blueprint, mathematical reference, and operational guide for AI coding agents and human engineers contributing to this repository.

---

## 1. Project Overview & Mission

- **Application Name**: Wealth Analyzer
- **Target Audience**: Retail investors, wealth planners, and FIRE (Financial Independence, Retire Early) practitioners.
- **Core Value Proposition**: Provides institutional-grade wealth projection, decumulation planning (SWP), 1,000-trial Monte Carlo stochastic modeling, and historical crisis stress-testing (Sequence-of-Returns Risk).
- **Design Aesthetic**: Sleek Dark Mode Glassmorphism (`BackdropFilter` blur), Crimson Red (`#EF4444`) CTAs, and Luxe Gold (`#F59E0B`) accents on a Deep Dark Slate (`#0B0F19`) canvas.

---

## 2. Clean Architecture & Directory Blueprint

The codebase strictly follows **Clean Architecture + MVVM** with strong enforcement of the **Single Responsibility Principle (SRP)**. UI widgets contain zero financial math or direct storage logic.

```
wealth_projector_2/
├── pubspec.yaml
├── README.md                           # Public documentation & user guide
├── AGENT.md                            # AI Agent Operating Handbook & Reference
├── walkthrough.md                      # Feature walkthrough & verification log
├── lib/
│   ├── main.dart                       # App entrypoint (Hive init & ProviderScope)
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart         # Slate, Crimson, Gold, and category colors
│   │   │   ├── app_typography.dart     # Outfit and Inter typography hierarchies
│   │   │   └── app_strings.dart        # User-facing string constants
│   │   ├── theme/
│   │   │   └── glassmorphism_theme.dart# Material3 Dark Theme with glass tokens
│   │   ├── utils/
│   │   │   ├── currency_formatter.dart # Dual currency (₹ Lakh/Cr & $ K/M/B) formatters
│   │   │   └── financial_calculator.dart# Compound math, SWP, Monte Carlo, SORR engine
│   │   └── widgets/
│   │       ├── glass_container.dart    # BackdropFilter glass container widget
│   │       ├── crimson_button.dart     # Glowing Crimson Red CTA button
│   │       ├── custom_slider.dart      # Responsive financial slider widget
│   │       └── responsive_builder.dart # Breakpoint detector (Desktop vs Mobile)
│   └── features/portfolio/
│       ├── domain/                     # PURE BUSINESS LOGIC (No Flutter UI imports)
│       │   ├── entities/
│       │   │   ├── investment_asset.dart   # Asset entity (id, name, category, type, isIncluded, etc.)
│       │   │   ├── asset_category.dart     # Enum with 8 categories, colors, & icons
│       │   │   ├── portfolio_summary.dart  # Aggregated KPI state entity
│       │   │   ├── projection_scenario.dart# 3-curve projection points & milestones
│       │   │   ├── swp_models.dart         # SWP decumulation points & result models
│       │   │   ├── risk_analysis_models.dart# Monte Carlo & Crisis stress models
│       │   │   ├── fire_models.dart        # FIRE result, flavors, & yearly point models
│       │   │   └── cash_flow_node.dart     # Sankey cash flow node & link models
│       │   ├── repositories/
│       │   │   └── portfolio_repository.dart# Repository contract interface
│       │   └── usecases/
│       │       ├── calculate_portfolio_kpis.dart   # Aggregation & Blended CAGR
│       │       ├── calculate_growth_projection.dart# 3-curve multi-year forecasting
│       │       ├── manage_assets_usecase.dart      # Asset CRUD & sample presets
│       │       ├── calculate_swp.dart              # Systematic Withdrawal Plan usecase
│       │       ├── calculate_fire_projection.dart  # Multi-FIRE targets & timeline usecase
│       │       ├── run_monte_carlo.dart            # 1,000-trial stochastic simulator
│       │       └── run_stress_test.dart            # Crisis stress-test (SORR) usecase
│       ├── data/                       # PERSISTENCE & DATA ADAPTERS
│       │   ├── models/
│       │   │   ├── investment_asset_model.dart     # JSON & Hive map conversion
│       │   │   └── user_settings_model.dart        # User settings & SWP/FIRE parameters model
│       │   ├── datasources/
│       │   │   └── local_portfolio_datasource.dart # Hive box storage operations
│       │   └── repositories/
│       │       └── portfolio_repository_impl.dart  # Implements domain repository
│       └── presentation/               # MVVM UI LAYER (Riverpod ViewModels & Views)
│           ├── viewmodels/
│           │   ├── currency_viewmodel.dart         # Dual currency preference state
│           │   ├── portfolio_viewmodel.dart        # Portfolio assets & KPI state
│           │   ├── projection_viewmodel.dart       # Accumulation simulator & curves state
│           │   ├── swp_viewmodel.dart              # SWP decumulation state & rules
│           │   ├── fire_viewmodel.dart             # FIRE numbers, readiness & crossover state
│           │   └── risk_analysis_viewmodel.dart    # Monte Carlo & SORR stress state
│           ├── widgets/
│           │   ├── app_header.dart                 # Top navigation (Overview, Simulator, FIRE, Holdings, Sankey)
│           │   ├── kpi_ribbon.dart                 # Net worth, Invested, Gains, SIP, CAGR
│           │   ├── donut_allocation_chart.dart     # fl_chart donut with category legend
│           │   ├── net_worth_area_chart.dart       # fl_chart gold gradient area chart
│           │   ├── sankey_cash_flow_widget.dart    # CustomPainter Sankey diagram
│           │   ├── projection_simulator_card.dart  # 4-slider 3-curve accumulation card
│           │   ├── swp_simulator_card.dart         # SWP card + Monte Carlo & SORR sub-tabs
│           │   ├── fire_calculator_card.dart       # Multi-FIRE cards, crossover chart, schedule table
│           │   ├── asset_list_table.dart           # Holdings table & cards with inclusion checkboxes
│           │   ├── add_investment_dialog.dart      # Glassmorphic modal + 10Y preview
│           │   ├── empty_onboarding_card.dart      # Empty state with 1-click sample presets
│           │   └── portfolio_backup_modal.dart     # JSON import/export & presets
│           └── views/
│               ├── dashboard_desktop_view.dart     # 3-column responsive desktop layout
│               ├── dashboard_mobile_view.dart      # Single-column mobile layout + FAB
│               └── wealth_dashboard_screen.dart    # Main screen coordinator
└── test/
    ├── core/
    │   ├── currency_formatter_test.dart
    │   ├── financial_calculator_test.dart
    │   ├── monte_carlo_calculator_test.dart
    │   └── stress_test_calculator_test.dart
    ├── domain/
    │   ├── calculate_portfolio_kpis_test.dart
    │   ├── calculate_growth_projection_test.dart
    │   ├── calculate_swp_test.dart
    │   ├── investment_asset_test.dart
    │   ├── manage_assets_usecase_test.dart
    │   └── portfolio_models_test.dart
    ├── data/
    │   ├── local_portfolio_datasource_test.dart
    │   └── portfolio_repository_impl_test.dart
    ├── presentation/
    │   ├── viewmodels/
    │   │   ├── currency_viewmodel_test.dart
    │   │   ├── portfolio_viewmodel_test.dart
    │   │   ├── projection_viewmodel_test.dart
    │   │   ├── swp_viewmodel_test.dart
    │   │   └── risk_analysis_viewmodel_test.dart
    │   └── widgets/
    │       ├── add_investment_dialog_test.dart
    │       ├── app_header_test.dart
    │       ├── asset_list_table_test.dart
    │       ├── donut_allocation_chart_test.dart
    │       ├── empty_onboarding_card_test.dart
    │       ├── kpi_ribbon_test.dart
    │       ├── net_worth_area_chart_test.dart
    │       ├── portfolio_backup_modal_test.dart
    │       ├── projection_simulator_card_test.dart
    │       ├── sankey_cash_flow_widget_test.dart
    │       └── swp_simulator_card_test.dart
    └── integration/
        └── portfolio_workflow_integration_test.dart
```

---

## 3. Tech Stack & Dependencies

- **Framework**: Flutter SDK ^3.13.1 (Flutter 3.47+ compatible)
- **Language**: Dart 3 (Null-safe, records, patterns)
- **State Management**: `flutter_riverpod: ^2.6.1` (`StateNotifierProvider`, `Provider`)
- **Local Storage**: `hive: ^2.2.3`, `hive_flutter: ^1.1.0`
- **Charts & Visualizations**: `fl_chart: ^1.2.0` + Custom `CustomPainter` (Sankey Diagram)
- **Typography & Formatting**: `google_fonts: ^8.2.1` (Outfit & Inter), `intl: ^0.20.3`
- **Utilities**: `uuid: ^4.6.0`, `flutter_animate: ^4.5.2`, `path_provider: ^2.1.6`

---

## 4. Precision Financial Math & Domain Formulas

All mathematical logic is encapsulated in [`FinancialCalculator`](file:///d:/softwares/programming/wealth_projector_2/lib/core/utils/financial_calculator.dart) and use cases.

### 4.1 Monthly SIP with Annual Step-Up
For an initial installment $M_0$, annual step-up rate $s$, annual return $r$:
$$\text{Effective Monthly Compounding Rate } i = (1 + r)^{1/12} - 1$$
$$\text{For month } m \in [0, 12t - 1]: \quad M_y = M_0 \times (1 + s)^{\lfloor m / 12 \rfloor}$$
$$\text{Compounded Future Value } FV = \sum_{m=0}^{12t-1} M_y \times (1 + i)^{12t - m}$$

### 4.2 Systematic Withdrawal Plan (SWP) Decumulation & Milestone Outflows
For starting retirement corpus $C_0$, living expense in today's terms $W_{\text{today}}$, inflation rate $f$, accumulation duration $t_{\text{acc}} = \text{Age}_{\text{retire}} - \text{Age}_{\text{current}}$:
$$\text{Starting Monthly Withdrawal at Retirement } W_0 = W_{\text{today}} \times (1 + f)^{t_{\text{acc}}}$$
$$\text{Monthly Growth Rate } i_w = (1 + r_{\text{post}})^{1/12} - 1$$
$$\text{For month } m \text{ in retirement year } y: \quad W_m = W_0 \times (1 + s_w)^{y-1}$$
$$\text{Annual Milestone Lumpsum Outflows } M_y = \sum_{k} \text{Amount}_k \times (1 + f)^{\text{Age}_y - \text{Age}_{\text{current}}}$$
$$\text{Monthly Step: } \quad C_{m+1} = \max\left(0, \; C_m \times (1 + i_w) - W_m - (\text{if } m = 1 \text{ then } M_y \text{ else } 0)\right)$$
- If $C_m = 0$, exact fractional depletion age $A_{\text{deplete}}$ is recorded.

### 4.3 Box-Muller Gaussian Stochastic Generator (Monte Carlo)
Standard normal random variable $Z \sim \mathcal{N}(0, 1)$ generated from uniform $U_1, U_2 \in (0, 1)$:
$$Z = \sqrt{-2 \ln(U_1)} \cos(2\pi U_2)$$
Annual stochastic market return:
$$R_{\text{stochastic}} = \text{clamp}\left(\mu + \sigma Z, \; -0.90, \; 1.50\right)$$

### 4.4 Monte Carlo 1,000-Trial Percentile Fan Trajectories
For $N = 1,000$ independent decumulation paths:
$$\text{Success Rate \%} = \frac{\sum_{t=1}^{N} \mathbb{I}(C_{\text{end}, t} > 0)}{N} \times 100$$
For each year $y$, sorted balances across all 1,000 runs yield:
- **P10 (Worst-case / 10% VaR)**: $\text{Rank } 100$
- **P50 (Median Expected Outcome)**: $\text{Rank } 500$
- **P90 (Optimistic Outcome)**: $\text{Rank } 900$

### 4.5 Sequence-of-Returns Risk (SORR) Historical Crisis Sequences
Applies historical shocks in early retirement years when the portfolio is most vulnerable:
- **2008 GFC**: Year 1: $-38.5\%$, Year 2: $+26.5\%$, Year 3: $+15.1\%$
- **2000 Dot-Com**: Year 1: $-9.1\%$, Year 2: $-11.9\%$, Year 3: $-22.1\%$, Year 4: $+28.7\%$
- **2020 Flash Crash**: Year 1: $-19.6\%$, Year 2: $+18.0\%$
- **1970s Stagflation**: Year 1: $-14.7\%$ ($+11\%$ inflation), Year 2: $-26.5\%$ ($+9\%$ inflation)
- **Custom Crash**: Year 1: Custom percentage ($-10\%$ to $-50\%$).

---

## 5. State Management & Data Flow (Riverpod + Hive)

### 5.1 Riverpod Providers
- `currencyProvider`: Controls dual currency formatting (`CurrencyType.inr` vs `CurrencyType.usd`).
- `portfolioProvider`: Manages active asset holdings, computes KPIs, and generates real Sankey cash flow data.
- `projectionProvider`: Manages accumulation simulation parameters (Age, Retirement, Inflation, Step-Up) and 3-curve trajectories.
- `swpProvider`: Manages decumulation withdrawals, post-retirement CAGR, withdrawal step-up, life expectancy, custom corpus, and 2%/3%/4%/5% rules.
- `riskAnalysisProvider`: Manages blended portfolio volatility $\sigma$, 1,000-run Monte Carlo simulations, and crisis stress-tests.

### 5.2 Persistence (Hive Boxes)
- `wealth_analyzer_assets`: Active `InvestmentAssetModel` records keyed by UUID.
- `wealth_analyzer_settings`: User simulator parameters, SWP configuration, and currency preferences (`UserSettingsModel`).

---

## 6. Verification & Runbook Commands

Always execute the following commands in order before completing any changes:

```bash
# 1. Build Windows release binary (Ensure compilation succeeds first)
flutter build windows

# 2. Run static analysis
flutter analyze

# 3. Run all 141+ automated tests (100% pass required)
flutter test

# 4. Run natively on Windows (Primary Platform Target)
flutter run -d windows
```

---

## 7. Mandatory Rules & Guardrails for AI Agents

1. **Windows Platform Primary Requirement**:
   - **Always build, analyze, and test the application on the Windows platform (`flutter build windows`, `flutter analyze`, `flutter test`, `flutter run -d windows`) instead of Web.**
2. **Real Data Integrity**:
   - Never inject synthetic buffers or artificial mock percentages into user data. Everything in Sankey, KPI cards, charts, and tables must be $100\%$ derived from actual assets and settings.
3. **Maintain Clean Architecture Separation**:
   - No Flutter UI imports (`package:flutter/...`) inside `domain/`.
   - No database or HTTP calls directly inside `presentation/widgets/`.
4. **Dual Currency Consistency**:
   - Never hardcode currency symbols. Always use `CurrencyFormatter.formatCompact` or `formatFull` with the active `currencyProvider`.
5. **No Layout Overflow**:
   - Always wrap dynamic rows and text in `Expanded`, `Flexible`, or `LayoutBuilder` to guarantee zero RenderFlex overflow across all window dimensions.
