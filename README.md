# Wealth Analyzer 💎

> **An institutional-grade wealth projection, systematic withdrawal planning (SWP), and stochastic risk modeling application built with Flutter & Riverpod.**

[![Release Build Matrix](https://github.com/dilwarSingh/wealth-analyzer/actions/workflows/release.yml/badge.svg)](https://github.com/dilwarSingh/wealth-analyzer/actions/workflows/release.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Tests](https://img.shields.io/badge/Tests-176%20Passing%20(100%25)-10B981)](#-automated-testing--quality)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Ubuntu%2022%2F24%20%7C%20Web-EF4444)](#-download--installation)
[![License](https://img.shields.io/badge/License-MIT-F59E0B)](LICENSE)

---

## 📸 Overview

**Wealth Analyzer** is designed for retail and FIRE (Financial Independence, Retire Early) investors to model wealth accumulation, plan post-retirement decumulation (SWP), calculate multi-FIRE target milestones, and stress-test portfolios against severe market volatility and historical crisis sequences.

The application operates completely offline with local persistence, adheres strictly to **Clean Architecture + MVVM**, and features a sleek **Dark Glassmorphism UI** (`#0B0F19` canvas, `#EF4444` Crimson CTAs, `#F59E0B` Luxe Gold accents) equipped with comprehensive financial tooltips across all metrics and controls.

---

## 📥 Download & Installation

Pre-built native installers and binaries are available on the [**GitHub Releases Page**](https://github.com/dilwarSingh/wealth-analyzer/releases).

### 🪟 Windows (Windows 10 / 11)
1. Download **`wealth-analyzer-windows-installer-x64.exe`** from the latest release.
2. Run the installer wizard to install Wealth Analyzer with Start Menu and Desktop shortcuts.
3. Launch **Wealth Analyzer** from your application menu.

---

### 🐧 Ubuntu / Debian Linux

Native `.deb` packages are compiled and packaged specifically for each LTS release:

#### For Ubuntu 24.04 LTS (Noble Numbat)
```bash
# 1. Download the package
wget https://github.com/dilwarSingh/wealth-analyzer/releases/latest/download/wealth-analyzer-ubuntu-24.04-amd64.deb

# 2. Install using APT (automatically resolves dependencies)
sudo apt update
sudo apt install ./wealth-analyzer-ubuntu-24.04-amd64.deb

# 3. Launch from terminal or application launcher
wealth_projector
```

#### For Ubuntu 22.04 LTS (Jammy Jellyfish)
```bash
# 1. Download the package
wget https://github.com/dilwarSingh/wealth-analyzer/releases/latest/download/wealth-analyzer-ubuntu-22.04-amd64.deb

# 2. Install using APT
sudo apt update
sudo apt install ./wealth-analyzer-ubuntu-22.04-amd64.deb

# 3. Launch from terminal or application launcher
wealth_projector
```

---

### 🍎 macOS (Apple Silicon & Intel)
1. Download **`wealth-analyzer-macos.dmg`** from the latest release.
2. Open the `.dmg` disk image.
3. Drag **`wealth_projector.app`** into your **`Applications`** folder.
4. Open **Wealth Analyzer** from your Applications or Spotlight search.

---

### 🌐 Web (Self-Hosted)
1. Download **`wealth-analyzer-web.zip`** from the latest release.
2. Extract the archive into your web server root (Nginx, Apache, or static hosting).
3. Alternatively, test locally with Python:
   ```bash
   unzip wealth-analyzer-web.zip -d wealth-analyzer-web
   cd wealth-analyzer-web
   python3 -m http.server 8080
   ```
4. Open `http://localhost:8080` in your web browser.

---

## ⚡ Core Features

### 1. 🔥 Comprehensive FIRE & Freedom Calculator
- **Multi-FIRE Target Numbers**:
  - 🟢 **Standard FIRE**: 100% of current living expenses ($25\times$ annual expenses at 4% SWR).
  - 🌿 **Lean FIRE**: 75% of expenses for frugal baseline independence.
  - 💎 **Fat FIRE**: 135% of expenses for abundant lifestyle, travel, and healthcare buffers.
  - ⛵ **Coast FIRE**: Identifies the exact invested corpus needed **today** so compound growth alone achieves full retirement independence without contributing another rupee.
  - ☕ **Barista FIRE**: Partial financial independence where part-time or passion work covers 40% of living expenses.
- **Pre-Retirement Capital Milestones**: Plan major life goals (home downpayment, child higher education) deducted prior to retirement, with live bi-directional sync to the SWP simulator.
- **Freedom Countdown Ribbon**: Real-time progress bar, target FIRE number in today's currency, projected freedom age & year, and passive monthly cash flow.
- **Net Worth vs FIRE Target Crossover Chart**: Visualizes the exact intersection year where net worth permanently overtakes the inflation-adjusted FIRE Target Line.
- **Year-by-Year FIRE Schedule DataTable**: Age-by-age tracking of Net Worth, Expenses, Passive Income, and FIRE Coverage Ratio %.

### 2. 📈 Multi-Asset Portfolio Aggregator & Smart Duration Controls
- Aggregate lump-sum assets and recurring monthly SIPs across 8 asset classes: **Stocks/Equities, Mutual Funds/ETFs, Real Estate, Crypto, Fixed Deposits, Gold, Cash/Savings, and Other**.
- **SIP Contribution Duration Selector**: Set SIPs to run until retirement or cap contribution horizons (e.g. 5, 10, 15 years) with automatic stopping age calculation and post-contribution compounding.
- **75/25 Split Holdings View**: Clean 75% Holdings Table / 25% Asset Allocation Donut desktop layout with streamlined metrics and duration badges (`⏳ 10 Yrs`).
- **Interactive Sankey Cash Flow Diagram**: $100\%$ derived from real asset data visualizing monthly cash flow distribution from total income to individual asset categories.
- **Per-Holding Inclusion Checkbox**: Checkbox on every holding with master select-all toggle and persistent Hive storage to include or exclude assets dynamically from all calculations.

### 3. 🔮 3-Curve Wealth Projection Engine
- Simulates wealth accumulation from **Current Age** to **Target Retirement Age** with live slider controls.
- Displays three comparative trajectory curves:
  - 🟡 **Base Case Curve (Gold)**: Compounded portfolio growth applying asset CAGRs and annual step-up compounding.
  - 🟢 **Inflation-Adjusted Real Wealth (Cyan)**: Purchasing power adjusted for annual inflation.
  - 🔴 **Cash Drag Benchmark (Rose)**: Opportunity cost comparing against a standard 3.5% savings benchmark.
- **Milestone Solver**: Automatically computes the exact age of crossing ₹1 Crore / $1 Million and ₹5 Crore / $5 Million.

### 4. 🛡️ SWP Decumulation Simulator & Solvency Recommendation
- **Today's Purchasing Power Mode (Auto-Inflation)**: Enter monthly living expenses in today's terms (e.g. ₹50,000 / mo), and the simulator automatically compounds it across accumulation years to compute starting retirement withdrawal with live breakdown callouts.
- **Dynamic Retirement Milestones & Lumpsum Outflows**: Plan customizable one-time retirement outflows (🏥 Medical Reserve, 💍 Child Wedding, ✈️ World Tour) with 1-click presets, in-place edit dialogs, and deduction from SWP schedules, Monte Carlo trials, and Crisis stress-tests.
- **Solvency & Minimum Recommended Starting Corpus Engine**: Context-specific solvency recommendations for:
  - 📊 **Standard Schedule Solvency** (100% Horizon)
  - 🎲 **Monte Carlo Stochastic Solvency** (80% Moderate & 95% Bulletproof Targets)
  - ⚡ **Crisis Resilience Solvency** (2008 GFC, 2000 Dot-com, and 2020 COVID Crash Survival)
- **Safe Withdrawal Rules**: One-click application of **2% (Ultra-Safe)**, **3% (Conservative)**, **4% (Standard Trinity Rule)**, and **5% (Aggressive)** rules.
- **Interactive Decumulation Chart & Year-by-Year Schedule Table**: Complete breakdown of Year/Age, Opening Corpus, Returns Generated, Amount Withdrawn, Closing Corpus, and Health Status (`Healthy`, `Moderate`, `Critical`, `Depleted`).

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
- **Comparative Overlay Line Chart**: Directly compares the Normal Baseline SWP curve against the Stressed Crisis curve with exact depletion age indicators.

### 7. 💡 Standardized App-Wide Tooltips & Natural Language Badges
- **Comprehensive Tooltip System**: Dark slate glass tooltips (`#1E293B`) with subtle gold/slate accent borders explaining financial metrics, formulas, and interaction controls across all screens.
- **Dynamic Amount Badges**: Live natural language currency display (e.g. `₹1.5 Cr`, `₹45 L`, `$2.5M`) adjacent to input fields for custom starting corpus and milestone amounts.
- **Dual Currency Support**: Instant 1-click toggle between **Indian Rupee (₹ Lakh / ₹ Cr)** and **US Dollar ($ K / $ M / $ B)**.
- **Local Persistence & Backup**: Local Hive storage, JSON Export, and JSON Restore.

---

## 🏛️ Architecture & Project Structure

The codebase strictly follows **Clean Architecture + MVVM** with clean separation between business logic, persistence adapters, and presentation layers:

```
lib/
├── core/
│   ├── constants/              # AppColors, AppTypography, AppStrings
│   ├── theme/                  # Dark Glassmorphism Material3 Theme
│   ├── utils/
│   │   ├── currency_formatter.dart # ₹ Lakh/Cr & $ K/M/B compact & full formatters
│   │   └── financial_calculator.dart # Math engine (SIP, SWP, Monte Carlo, SORR)
│   └── widgets/                # AppTooltip, GlassContainer, CustomFinancialSlider, CrimsonButton
└── features/portfolio/
    ├── domain/                 # Pure Business Logic (No Flutter UI)
    │   ├── entities/           # InvestmentAsset, SwpModels, RiskAnalysisModels, FireModels
    │   ├── repositories/       # PortfolioRepository interface contract
    │   └── usecases/           # CalculateKPIs, GrowthProjection, SWP, MonteCarlo, StressTest
    ├── data/                   # Data Adapters & Hive Persistence
    │   ├── models/             # InvestmentAssetModel, UserSettingsModel
    │   ├── datasources/        # LocalPortfolioDataSource (Hive boxes)
    │   └── repositories/       # PortfolioRepositoryImpl
    └── presentation/           # MVVM State Management & Widgets
        ├── viewmodels/         # PortfolioViewModel, ProjectionViewModel, SwpViewModel, FireViewModel
        ├── views/              # WealthDashboardScreen, DashboardDesktopView, DashboardMobileView
        └── widgets/            # KpiRibbon, NetWorthAreaChart, SwpSimulatorCard, SankeyCashFlow, etc.
```

---

## 🧪 Automated Testing & Quality

The codebase contains a **4-layer test suite** with **176 automated tests** passing at **100%**:

```bash
$ flutter test
00:16 +176: All tests passed!
```

### Test Coverage Hierarchy:
1. **Layer 1: Mathematical & Algorithmic Engines**: SIP compound interest with duration limits (`maxDurationYears`), milestone solvers, SWP decumulation, Box-Muller Gaussian RNG, 1,000-run Monte Carlo distribution, and crisis stress-test sequences.
2. **Layer 2: Domain Use Cases & Data Adapters**: KPI calculation, projection scenarios, SWP decumulation, Monte Carlo stochastic engine, Stress testing, Hive serialization, and repository contracts.
3. **Layer 3: ViewModels & State Management**: `PortfolioViewModel`, `ProjectionViewModel`, `CurrencyViewModel`, `SwpViewModel`, `FireViewModel`, and `RiskAnalysisViewModel` validating state transitions and persistent Hive storage.
4. **Layer 4: UI Widgets & End-to-End Integration**: Widget tests for all cards, dialogs, charts, `AppTooltip`, and end-to-end integration journeys simulating full user flows across fresh `ProviderScope`s.

---

## 🛠️ Developer Setup & Build from Source

### Prerequisites
- **Flutter SDK**: `^3.13.1` (Flutter 3.24+ / 3.47+ recommended)
- **Dart SDK**: `^3.0.0`
- **Platform Build Tools**:
  - **Windows**: Visual Studio 2022 with *Desktop development with C++* workload
  - **Linux**: `sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev`
  - **macOS**: Xcode with Command Line Tools
  - **Web**: Google Chrome or Chromium

### 1. Clone & Setup
```bash
git clone https://github.com/dilwarSingh/wealth-analyzer.git
cd wealth-analyzer

# Install Flutter dependencies
flutter pub get
```

### 2. Run Tests & Linter
```bash
# Run code analysis
flutter analyze

# Run complete 176-test suite
flutter test
```

### 3. Run Locally in Debug Mode
```bash
# Windows Desktop
flutter run -d windows

# Linux Desktop
flutter run -d linux

# macOS Desktop
flutter run -d macos

# Web (Chrome)
flutter run -d chrome
```

### 4. Build Release Packages Locally
```bash
# Windows Release (Generates build/windows/x64/runner/Release/wealth_projector.exe)
flutter build windows --release

# Linux Release (Generates build/linux/x64/release/bundle/)
flutter build linux --release

# macOS Release (Generates build/macos/Build/Products/Release/wealth_projector.app)
flutter build macos --release

# Web Release (Generates build/web/)
flutter build web --release --base-href "/"
```

---

## 📄 License

This project is licensed under the MIT License.
