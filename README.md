# Wealth Analyzer (Wealth Projector) 💎

> **An institutional-grade portfolio projection, systematic withdrawal planning (SWP), and stochastic risk modeling application built with Flutter & Riverpod.**

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Tests](https://img.shields.io/badge/Tests-127%20Passing%20(100%25)-10B981)](#-automated-testing--quality)
[![Platform](https://img.shields.io/badge/Platform-Windows%20Desktop%20%7C%20Web%20%7C%20Mobile-EF4444)](#-getting-started--build)
[![License](https://img.shields.io/badge/License-MIT-F59E0B)](#)

---

## 📸 Overview

**Wealth Analyzer** is designed for retail and FIRE (Financial Independence, Retire Early) investors to model wealth accumulation, post-retirement decumulation (SWP), calculate multi-FIRE target milestones, and stress-test portfolios against severe market volatility and historical crisis sequences.

The application adheres strictly to **Clean Architecture + MVVM**, featuring a sleek **Dark Glassmorphism UI** (`#0B0F19` canvas, `#EF4444` Crimson CTAs, `#F59E0B` Luxe Gold accents).

---

## ⚡ Core Features

### 1. 🔥 Comprehensive FIRE & Freedom Calculator
- **Multi-FIRE Target Numbers**:
  - 🟢 **Standard FIRE**: 100% of current living expenses ($25\times$ annual expenses at 4% SWR).
  - 🌿 **Lean FIRE**: 75% of expenses for frugal baseline independence.
  - 💎 **Fat FIRE**: 135% of expenses for abundant lifestyle, travel, and healthcare buffers.
  - ⛵ **Coast FIRE**: Identifies the exact invested corpus needed **today** so compound growth alone achieves full retirement independence without contributing another rupee.
  - ☕ **Barista FIRE**: Partial financial independence where part-time or passion work covers 40% of living expenses.
- **Freedom Countdown Ribbon**: Real-time progress bar, target FIRE number in today's currency, projected freedom age & year, and passive monthly cash flow.
- **Net Worth vs FIRE Target Crossover Chart**: Visualizes the exact intersection year where net worth permanently overtakes the inflation-adjusted FIRE Target Line.
- **Year-by-Year FIRE Schedule DataTable**: Age-by-age tracking of Net Worth, Expenses, Passive Income, and FIRE Coverage Ratio %.
- **Dual Data Sourcing**: Auto-syncs live portfolio net worth and monthly SIPs, with optional custom overrides.

### 2. 📈 Multi-Asset Portfolio Aggregator
- Aggregate one-time lump-sum assets and recurring monthly SIPs across 8 asset classes: **Stocks/Equities, Mutual Funds/ETFs, Real Estate, Crypto, Fixed Deposits, Gold, Cash/Savings, and Other**.
- Automatic calculation of Total Portfolio Net Worth, Invested Capital, Absolute Returns %, Total Monthly SIP Inflow, and Blended Weighted CAGR.
- **Interactive Sankey Cash Flow Diagram**: $100\%$ derived from real asset data visualizing monthly cash flow distribution from total income to individual asset categories.
- **Per-Holding Inclusion Checkbox**: Checkbox on every holding with master select-all toggle and persistent Hive storage to include or exclude assets dynamically from all calculations.

### 3. 🔮 3-Curve Wealth Projection Engine
- Simulates wealth accumulation from **Current Age** to **Target Retirement Age** with live slider controls.
- Displays three comparative trajectory curves:
  - 🟡 **Base Case Curve (Gold)**: Compounded portfolio growth applying asset CAGRs and annual step-up compounding.
  - 🟢 **Inflation-Adjusted Real Wealth (Cyan)**: Purchasing power adjusted for annual inflation.
  - 🔴 **Cash Drag Benchmark (Rose)**: Opportunity cost comparing against a standard 3.5% savings benchmark.
  - **Milestone Solver**: Automatically computes the exact age of crossing ₹1 Crore / $1 Million.

### 4. 🛡️ SWP Decumulation Simulator & Schedule Table
- **Today's Purchasing Power Mode (Auto-Inflation)**: Enter monthly living expenses in today's terms (e.g. ₹50,000 / mo), and the simulator automatically compounds it across the accumulation years to compute the starting retirement withdrawal (e.g. ₹2.14 L / mo at Age 50), with a live breakdown callout and a toggle for direct future amounts.
- **Dynamic Retirement Milestones & Lumpsum Outflows**: Plan customizable one-time retirement outflows (e.g., 🏥 Medical Reserve, 💍 Child Wedding, ✈️ World Tour) with 1-click presets, in-place edit modal dialog, checkboxes, auto-inflation to target age, and deduction from SWP schedules, Monte Carlo trials, and Crisis stress-tests.
- **Solvency & Minimum Recommended Starting Corpus Engine**: Whenever a plan depletes prematurely or falls below 80% Monte Carlo confidence, the simulator dynamically calculates and displays the exact minimum starting corpus required across:
  - 📊 **Standard SWP Solvency (100% Horizon)**
  - 🎲 **Monte Carlo Stochastic Solvency** (80% Moderate & 95% Bulletproof Targets)
  - ⚡ **Crisis Resilience Solvency** (2008 GFC Crash-Proof Survival)
- **Auto-Linked or Custom Starting Corpus**: Inherits final retirement net worth or allows custom lump-sum input.
- **Configurable Decumulation Controls**: Monthly Withdrawal amount, Post-Retirement CAGR %, Annual Withdrawal Inflation Step-Up %, and Target Life Expectancy Age.
- **Safe Withdrawal Rules Dropdown**: One-click application of **2% (Ultra-Safe / Early FIRE)**, **3% (Conservative)**, **4% (Standard Trinity Rule)**, and **5% (Aggressive)** rules.
- **Sustainability KPI Banner**: Identifies whether the plan achieves **Perpetuity / Sustainability** or detects exact **Corpus Depletion Age**.
- **Interactive Decumulation Chart & Year-by-Year Schedule Table**: Complete breakdown of Year/Age, Opening Corpus, Returns Generated, Amount Withdrawn / Outflows, Closing Corpus, and Health Status (`Healthy`, `Moderate`, `Critical`, `Depleted`).

### 5. 🎲 Monte Carlo Probabilistic Simulator (1,000 Stochastic Runs)
- Runs 1,000 Gaussian stochastic market trials using the **Box-Muller transformation**.
- Computes the statistical **Probabilistic Success Rate %** (e.g. `94.2% Very High Confidence`).
- **Percentile Fan Area Chart**: Multi-series area chart displaying **90th Percentile (Optimistic)**, **50th Percentile (Median Expected)**, and **10th Percentile (Pessimistic / 10% VaR)** trajectories.
- **Asset Allocation Volatility Engine**: Automatically computes blended portfolio standard deviation ($\sigma$) with a 5% to 25% custom override slider.

### 6. ⚡ Sequence-of-Returns Risk (SORR) & Crisis Stress-Testing
- Stress-tests the decumulation plan against historical market crashes striking in Year 1 of retirement:
  - 📉 **2008 Global Financial Crisis**: $-38.5\%$ shock in Year 1, $+26.5\%$ in Year 2, $+15.1\%$ in Year 3.
  - 💻 **2000 Dot-Com Tech Bubble**: $-9.1\%$ (Yr 1), $-11.9\%$ (Yr 2), $-22.1\%$ (Yr 3), $+28.7\%$ (Yr 4).
  - 🦠 **2020 COVID-19 Flash Crash**: $-19.6\%$ shock in Year 1, $+18.0\%$ in Year 2.
  - 🛢️ **1970s Stagflation**: $-14.7\%$ and $-26.5\%$ drawdowns with $+11.0\%$ inflation spike.
  - 🛠️ **Custom Year 1 Shock**: Slider from $-10\%$ to $-50\%$.
- **Comparative Overlay Line Chart**: Directly compares the Normal Baseline SWP curve against the Stressed Crisis curve.

### 7. 💱 Dual Currency & Persistent Storage
- **Dual Currency Support**: Instant 1-click toggle between **Indian Rupee (₹ Lakh / ₹ Cr)** and **US Dollar ($ K / $ M / $ B)**.
- **Local Persistence**: All portfolio assets, user settings, simulator parameters, SWP configurations, FIRE parameters, and currency preferences are saved locally to Hive boxes.
- **Presets & Backup**: One-click starter presets (Balanced Growth, High Equity, Conservative), JSON Export, and JSON Restore.

---

## 🏛️ Architecture & Project Structure

```
lib/
├── core/
│   ├── constants/              # AppColors, AppTypography, AppStrings
│   ├── theme/                  # Dark Glassmorphism Material3 Theme
│   ├── utils/
│   │   ├── currency_formatter.dart # ₹ Lakh/Cr & $ K/M/B compact & full formatters
│   │   └── financial_calculator.dart # Math engine (SIP, SWP, Monte Carlo, SORR)
│   └── widgets/                # GlassContainer, CustomFinancialSlider, CrimsonButton
└── features/portfolio/
    ├── domain/                 # Pure Business Logic (No Flutter UI)
    │   ├── entities/           # InvestmentAsset, SwpModels, RiskAnalysisModels
    │   ├── repositories/       # PortfolioRepository interface contract
    │   └── usecases/           # CalculateKPIs, GrowthProjection, SWP, MonteCarlo, StressTest
    ├── data/                   # Data Adapters & Hive Persistence
    │   ├── models/             # InvestmentAssetModel, UserSettingsModel
    │   ├── datasources/        # LocalPortfolioDataSource (Hive boxes)
    │   └── repositories/       # PortfolioRepositoryImpl
    └── presentation/           # MVVM State Management & Widgets
        ├── viewmodels/         # PortfolioViewModel, ProjectionViewModel, SwpViewModel, RiskViewModel
        ├── views/              # WealthDashboardScreen, DashboardDesktopView, DashboardMobileView
        └── widgets/            # KpiRibbon, NetWorthAreaChart, SwpSimulatorCard, SankeyCashFlow, etc.
```

---

## 🧪 Automated Testing & Quality

The codebase contains a **4-layer test suite** with **124 automated tests** passing at **100%**:

```bash
$ flutter test
00:10 +124: All tests passed!
```

### Test Coverage Layers:
1. **Layer 1: Core Mathematical Algorithms**: SIP compound interest, effective monthly rate ($i = (1+r)^{1/12}-1$), milestone solver, SWP decumulation, Box-Muller Gaussian RNG, 1,000-run Monte Carlo distribution, and crisis stress-test sequences.
2. **Layer 2: Domain Use Cases & Data Adapters**: KPI calculation use case, projection scenario use case, SWP use case, Monte Carlo use case, Stress Test use case, Hive model serialization, and repository implementation.
3. **Layer 3: ViewModels & State Management**: `PortfolioViewModel`, `ProjectionViewModel`, `CurrencyViewModel`, `SwpViewModel`, and `RiskAnalysisViewModel` verifying state transitions and Hive persistence.
4. **Layer 4: UI Components & Inter-Component Integration**: Widget tests for all cards/charts and end-to-end integration journeys simulating full user flows and app restarts across fresh `ProviderScope`s.

---

## 🚀 Getting Started & Build

### Prerequisites
- Flutter SDK `^3.13.1` (Flutter 3.47+ recommended)
- Dart SDK `^3.0.0`
- Windows C++ Build Tools (for Windows desktop target)

### Installation & Run

```bash
# 1. Clone the repository
git clone https://github.com/your-username/wealth_projector.git
cd wealth_projector_2

# 2. Install dependencies
flutter pub get

# 3. Run on Windows (Primary Platform Target)
flutter run -d windows

# 4. Build Windows Release Binary
flutter build windows
```

The release executable will be generated at:
`build\windows\x64\runner\Release\wealth_projector.exe`

---

## 📄 License

This project is licensed under the MIT License.
