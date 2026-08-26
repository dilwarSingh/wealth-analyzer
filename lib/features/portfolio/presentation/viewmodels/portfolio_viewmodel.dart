import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/local_portfolio_datasource.dart';
import '../../data/repositories/portfolio_repository_impl.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/cash_flow_node.dart';
import '../../domain/entities/investment_asset.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../../domain/usecases/calculate_portfolio_kpis.dart';
import '../../domain/usecases/manage_assets_usecase.dart';

// --- Dependency Injection Providers ---
final localDataSourceProvider = Provider<LocalPortfolioDataSource>((ref) {
  return HiveLocalPortfolioDataSource();
});

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  final ds = ref.watch(localDataSourceProvider);
  return PortfolioRepositoryImpl(localDataSource: ds);
});

final calculateKpisUseCaseProvider = Provider<CalculatePortfolioKPIsUseCase>((ref) {
  return CalculatePortfolioKPIsUseCase();
});

final manageAssetsUseCaseProvider = Provider<ManageAssetsUseCase>((ref) {
  final repo = ref.watch(portfolioRepositoryProvider);
  return ManageAssetsUseCase(repo);
});

// --- State Model ---
class PortfolioState {
  final List<InvestmentAsset> assets;
  final PortfolioSummary summary;
  final SankeyCashFlowData sankeyData;
  final bool isLoading;
  final String? errorMessage;
  final String? selectedFilterCategory;

  const PortfolioState({
    required this.assets,
    required this.summary,
    required this.sankeyData,
    this.isLoading = false,
    this.errorMessage,
    this.selectedFilterCategory,
  });

  factory PortfolioState.initial() {
    return PortfolioState(
      assets: [],
      summary: PortfolioSummary.empty(),
      sankeyData: SankeyCashFlowData.empty(),
      isLoading: true,
      errorMessage: null,
      selectedFilterCategory: null,
    );
  }

  PortfolioState copyWith({
    List<InvestmentAsset>? assets,
    PortfolioSummary? summary,
    SankeyCashFlowData? sankeyData,
    bool? isLoading,
    String? errorMessage,
    String? selectedFilterCategory,
  }) {
    return PortfolioState(
      assets: assets ?? this.assets,
      summary: summary ?? this.summary,
      sankeyData: sankeyData ?? this.sankeyData,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedFilterCategory: selectedFilterCategory ?? this.selectedFilterCategory,
    );
  }
}

// --- ViewModel Notifier ---
final portfolioProvider =
    StateNotifierProvider<PortfolioViewModel, PortfolioState>((ref) {
  final manageUseCase = ref.watch(manageAssetsUseCaseProvider);
  final kpiUseCase = ref.watch(calculateKpisUseCaseProvider);
  return PortfolioViewModel(manageUseCase, kpiUseCase);
});

class PortfolioViewModel extends StateNotifier<PortfolioState> {
  final ManageAssetsUseCase _manageAssetsUseCase;
  final CalculatePortfolioKPIsUseCase _calculateKpisUseCase;

  PortfolioViewModel(
    this._manageAssetsUseCase,
    this._calculateKpisUseCase,
  ) : super(PortfolioState.initial()) {
    loadPortfolio();
  }

  Future<void> loadPortfolio() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final assets = await _manageAssetsUseCase.getAssets();
      _updateStateWithAssets(assets);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void _updateStateWithAssets(List<InvestmentAsset> assets) {
    final summary = _calculateKpisUseCase.execute(assets);
    final sankeyData = _generateSankeyData(assets, summary);
    state = state.copyWith(
      assets: assets,
      summary: summary,
      sankeyData: sankeyData,
      isLoading: false,
      errorMessage: null,
    );
  }

  SankeyCashFlowData _generateSankeyData(
      List<InvestmentAsset> assets, PortfolioSummary summary) {
    if (assets.isEmpty) {
      return SankeyCashFlowData.empty();
    }

    final double totalInflow = summary.totalMonthlySipInflow;
    if (totalInflow <= 0) {
      return SankeyCashFlowData.empty();
    }

    final sourceNode = SankeyNode(
      id: 'monthly_inflow',
      label: 'Total Monthly Inflow',
      value: totalInflow,
      color: AppColors.gold,
      icon: null,
      isSource: true,
    );

    final List<SankeyNode> targetNodes = [];
    final List<SankeyLink> links = [];

    // Target categories for active SIPs
    summary.categoryMonthlySip.forEach((category, amount) {
      if (amount > 0) {
        final targetId = 'target_${category.name}';
        targetNodes.add(SankeyNode(
          id: targetId,
          label: '${category.label} SIP',
          value: amount,
          color: category.color,
          icon: category.icon,
        ));

        links.add(SankeyLink(
          sourceId: sourceNode.id,
          targetId: targetId,
          value: amount,
          color: category.color,
          targetLabel: category.label,
        ));
      }
    });

    return SankeyCashFlowData(
      totalMonthlyInflow: totalInflow,
      sourceNodes: [sourceNode],
      targetNodes: targetNodes,
      links: links,
    );
  }

  Future<bool> saveAsset(InvestmentAsset asset) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _manageAssetsUseCase.addOrUpdateAsset(asset);
      final updatedAssets = await _manageAssetsUseCase.getAssets();
      _updateStateWithAssets(updatedAssets);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteAsset(String id) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _manageAssetsUseCase.deleteAsset(id);
      final updatedAssets = await _manageAssetsUseCase.getAssets();
      _updateStateWithAssets(updatedAssets);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> loadSamplePreset(String presetType) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _manageAssetsUseCase.loadSamplePortfolio(presetType);
      final updatedAssets = await _manageAssetsUseCase.getAssets();
      _updateStateWithAssets(updatedAssets);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> clearAll() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _manageAssetsUseCase.clearAll();
      _updateStateWithAssets([]);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> toggleAssetInclusion(String id, bool isIncluded) async {
    try {
      final index = state.assets.indexWhere((a) => a.id == id);
      if (index >= 0) {
        final updatedAsset = state.assets[index].copyWith(isIncluded: isIncluded);
        await _manageAssetsUseCase.addOrUpdateAsset(updatedAsset);
        final updatedAssets = await _manageAssetsUseCase.getAssets();
        _updateStateWithAssets(updatedAssets);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> toggleAllAssetsInclusion(bool isIncluded) async {
    try {
      final updatedList = state.assets.map((a) => a.copyWith(isIncluded: isIncluded)).toList();
      await _manageAssetsUseCase.repository.setAssets(updatedList);
      final updatedAssets = await _manageAssetsUseCase.getAssets();
      _updateStateWithAssets(updatedAssets);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  String exportPortfolioAsJson() {
    final list = state.assets
        .map((a) => {
              'id': a.id,
              'name': a.name,
              'category': a.category.name,
              'type': a.type.code,
              'investedAmount': a.investedAmount,
              'currentValue': a.currentValue,
              'startDate': a.startDate.toIso8601String(),
              'expectedCAGR': a.expectedCAGR,
              'stepUpRate': a.stepUpRate,
              'isIncluded': a.isIncluded,
            })
        .toList();
    return jsonEncode(list);
  }

  Future<bool> importPortfolioFromJson(String jsonString) async {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is List) {
        final List<InvestmentAsset> imported = [];
        for (final item in decoded) {
          if (item is Map) {
            imported.add(InvestmentAsset(
              id: item['id']?.toString() ?? '',
              name: item['name']?.toString() ?? 'Asset',
              category: AssetCategory.fromString(item['category']?.toString() ?? 'other'),
              type: InvestmentType.fromString(item['type']?.toString() ?? 'ONE_TIME'),
              investedAmount: (item['investedAmount'] as num?)?.toDouble() ?? 0.0,
              currentValue: (item['currentValue'] as num?)?.toDouble() ?? 0.0,
              startDate: DateTime.tryParse(item['startDate']?.toString() ?? '') ?? DateTime.now(),
              expectedCAGR: (item['expectedCAGR'] as num?)?.toDouble() ?? 10.0,
              stepUpRate: (item['stepUpRate'] as num?)?.toDouble() ?? 0.0,
              isIncluded: item['isIncluded'] as bool? ?? true,
            ));
          }
        }
        await _manageAssetsUseCase.repository.setAssets(imported);
        _updateStateWithAssets(imported);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Invalid JSON format: $e');
      return false;
    }
  }
}
