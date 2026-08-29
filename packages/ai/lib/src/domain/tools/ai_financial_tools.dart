/// Definitions of tools exposed to LLMs for deterministic calculations, portfolio actions, and Generative UI
class AIFinancialToolDefinitions {
  static const String toolRunMonteCarlo = 'run_monte_carlo';
  static const String toolRunStressTest = 'run_stress_test';
  static const String toolCalculateFire = 'calculate_fire';
  static const String toolCalculateSwp = 'calculate_swp';
  static const String toolRecommendGoalRebalance = 'recommend_goal_rebalance';
  static const String toolProposeAddAsset = 'propose_add_asset';
  static const String toolProposeBatchImport = 'propose_batch_import';
  static const String toolRenderKpiCard = 'render_kpi_card';
  static const String toolRenderAllocationChart = 'render_allocation_chart';
  static const String toolRenderProjectionChart = 'render_projection_chart';
  static const String toolRenderScenarioSimulator = 'render_scenario_simulator';
  static const String toolGenerateAuditReport = 'generate_audit_report';

  /// Schema descriptions for all tools formatted as standard JSON Schemas
  static List<Map<String, dynamic>> getAllToolSchemas() {
    return [
      {
        'name': toolRunMonteCarlo,
        'description': 'Run a deterministic 1,000-trial Monte Carlo stochastic simulation to compute 10th, 50th, 90th percentile wealth curves and probability of financial goal success.',
        'parameters': {
          'type': 'object',
          'properties': {
            'currentPortfolio': {'type': 'number', 'description': 'Initial starting portfolio value'},
            'annualSavings': {'type': 'number', 'description': 'Annual additional contributions / SIP'},
            'expectedReturn': {'type': 'number', 'description': 'Expected nominal annualized CAGR in percent, e.g. 12.0'},
            'volatility': {'type': 'number', 'description': 'Annual standard deviation volatility in percent, e.g. 15.0'},
            'years': {'type': 'integer', 'description': 'Projection horizon in years (5 to 40)'},
            'simulations': {'type': 'integer', 'description': 'Number of trials (default 1000)'},
          },
          'required': ['currentPortfolio', 'annualSavings'],
        },
      },
      {
        'name': toolRunStressTest,
        'description': 'Stress-test current portfolio against historical market crashes (2008 Global Financial Crisis, 2020 Covid Crash, High Inflation Stagflation) to calculate drawdown and resilience score.',
        'parameters': {
          'type': 'object',
          'properties': {
            'totalEquity': {'type': 'number', 'description': 'Total value held in equities and equity mutual funds'},
            'totalDebt': {'type': 'number', 'description': 'Total value in debt, fixed income, bonds, and PPF/EPF'},
            'totalGold': {'type': 'number', 'description': 'Total value in gold and precious metals'},
            'totalCrypto': {'type': 'number', 'description': 'Total value in crypto / volatile digital assets'},
          },
          'required': ['totalEquity', 'totalDebt'],
        },
      },
      {
        'name': toolCalculateFire,
        'description': 'Calculate exact Lean FIRE, Standard FIRE, Fat FIRE, and Coast FIRE targets, annual expenses multiplier, and years to financial independence.',
        'parameters': {
          'type': 'object',
          'properties': {
            'annualExpenses': {'type': 'number', 'description': 'Annual living expenses'},
            'currentNetWorth': {'type': 'number', 'description': 'Current accumulated net worth'},
            'annualSavings': {'type': 'number', 'description': 'Annual ongoing savings / SIP'},
            'expectedReturn': {'type': 'number', 'description': 'Expected portfolio return percent, e.g. 12.0'},
            'inflationRate': {'type': 'number', 'description': 'Expected inflation percent, e.g. 6.0'},
            'safeWithdrawalRate': {'type': 'number', 'description': 'Safe withdrawal rate percent (default 3.5 to 4.0)'},
          },
          'required': ['annualExpenses', 'currentNetWorth'],
        },
      },
      {
        'name': toolCalculateSwp,
        'description': 'Simulate a Systematic Withdrawal Plan (SWP) post-retirement to calculate depletion year and perpetual sustainability.',
        'parameters': {
          'type': 'object',
          'properties': {
            'corpus': {'type': 'number', 'description': 'Retirement starting corpus'},
            'initialMonthlyWithdrawal': {'type': 'number', 'description': 'Monthly withdrawal in year 1'},
            'inflationRate': {'type': 'number', 'description': 'Annual inflation adjustment percent'},
            'expectedReturn': {'type': 'number', 'description': 'Annual portfolio return percent'},
            'years': {'type': 'integer', 'description': 'Retirement horizon in years (e.g. 30)'},
          },
          'required': ['corpus', 'initialMonthlyWithdrawal'],
        },
      },
      {
        'name': toolRecommendGoalRebalance,
        'description': 'Calculate asset allocation drift against user goal benchmarks and generate step-by-step rebalancing deltas and tax-efficient SIP inflow routing advice.',
        'parameters': {
          'type': 'object',
          'properties': {
            'goalName': {'type': 'string', 'description': 'Name of the goal, e.g. FIRE, Home Purchase'},
            'targetAmount': {'type': 'number', 'description': 'Target target corpus amount'},
            'targetYears': {'type': 'integer', 'description': 'Horizon in years'},
            'targetEquitiesPercent': {'type': 'number', 'description': 'Target equity percentage (0-100)'},
            'targetDebtPercent': {'type': 'number', 'description': 'Target debt percentage (0-100)'},
            'targetGoldPercent': {'type': 'number', 'description': 'Target gold percentage (0-100)'},
            'targetCashPercent': {'type': 'number', 'description': 'Target cash percentage (0-100)'},
            'monthlySipInflow': {'type': 'number', 'description': 'Ongoing monthly investment capacity for inflow rebalancing'},
          },
          'required': ['goalName', 'targetEquitiesPercent', 'targetDebtPercent'],
        },
      },
      {
        'name': toolProposeAddAsset,
        'description': 'Propose adding a new investment asset or holding to the user portfolio. Renders a 1-tap confirmation card that writes to the local database upon user approval.',
        'parameters': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'description': 'Name of the asset (e.g. Nifty 50 Index Fund, Apple Inc, Sovereign Gold Bond)'},
            'category': {'type': 'string', 'description': 'Asset category: equities, mutualFunds, crypto, realEstate, debtAndFixedIncome, goldAndCommodities, cashAndLiquid'},
            'currentValue': {'type': 'number', 'description': 'Current value or amount to invest'},
            'investedAmount': {'type': 'number', 'description': 'Cost basis or purchase price'},
            'expectedReturnPercent': {'type': 'number', 'description': 'Expected return rate in percent'},
            'notes': {'type': 'string', 'description': 'Optional rationale or notes'},
          },
          'required': ['name', 'category', 'currentValue'],
        },
      },
      {
        'name': toolProposeBatchImport,
        'description': 'Propose batch-importing multiple parsed assets extracted from a broker statement, CAS summary, CSV, or holding screenshot.',
        'parameters': {
          'type': 'object',
          'properties': {
            'sourceDescription': {'type': 'string', 'description': 'Description of the statement, e.g. Zerodha Holdings (15 Assets)'},
            'assets': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                  'category': {'type': 'string'},
                  'currentValue': {'type': 'number'},
                  'investedAmount': {'type': 'number'},
                  'expectedReturnPercent': {'type': 'number'},
                },
                'required': ['name', 'category', 'currentValue'],
              },
            },
          },
          'required': ['sourceDescription', 'assets'],
        },
      },
      {
        'name': toolRenderKpiCard,
        'description': 'Render an interactive Glassmorphic KPI metric badge in the chat stream.',
        'parameters': {
          'type': 'object',
          'properties': {
            'title': {'type': 'string', 'description': 'Metric label, e.g. Net Worth, FIRE Runway, Savings Rate'},
            'value': {'type': 'string', 'description': 'Formatted display value, e.g. ₹1.25 Cr, 9.4 Years, 42%'},
            'subtitle': {'type': 'string', 'description': 'Brief explanatory context'},
            'changePercent': {'type': 'number', 'description': 'Percentage delta (+12.4% or -3.2%)'},
            'isPositive': {'type': 'boolean', 'description': 'Whether change is favorable'},
          },
          'required': ['title', 'value'],
        },
      },
      {
        'name': toolRenderAllocationChart,
        'description': 'Render an interactive glassmorphic Donut Chart visual of asset allocation breakdown in the chat stream.',
        'parameters': {
          'type': 'object',
          'properties': {
            'slices': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'category': {'type': 'string'},
                  'percentage': {'type': 'number'},
                  'amount': {'type': 'number'},
                },
                'required': ['category', 'percentage', 'amount'],
              },
            },
            'totalAmount': {'type': 'number'},
          },
          'required': ['slices', 'totalAmount'],
        },
      },
      {
        'name': toolRenderScenarioSimulator,
        'description': 'Render an interactive what-if scenario simulator card with live on-device sliders for returns, inflation, and years.',
        'parameters': {
          'type': 'object',
          'properties': {
            'initialNetWorth': {'type': 'number'},
            'defaultAnnualSavings': {'type': 'number'},
            'defaultExpectedReturn': {'type': 'number'},
            'defaultInflationRate': {'type': 'number'},
            'defaultYears': {'type': 'integer'},
          },
          'required': ['initialNetWorth', 'defaultAnnualSavings'],
        },
      },
      {
        'name': toolGenerateAuditReport,
        'description': 'Generate a full structured comprehensive wealth health diagnostic report with score, strengths, risks, and action plan.',
        'parameters': {
          'type': 'object',
          'properties': {
            'healthScore': {'type': 'number', 'description': 'Overall health score between 0 and 100'},
            'summary': {'type': 'string', 'description': 'Executive summary paragraph'},
            'strengths': {'type': 'array', 'items': {'type': 'string'}},
            'risks': {'type': 'array', 'items': {'type': 'string'}},
            'actionPlan': {'type': 'array', 'items': {'type': 'string'}},
            'rawMarkdown': {'type': 'string', 'description': 'Complete formatted report in Markdown for copying/exporting'},
          },
          'required': ['healthScore', 'summary', 'strengths', 'risks', 'actionPlan', 'rawMarkdown'],
        },
      },
    ];
  }
}
