import '../../domain/entities/asset_category.dart';
import '../../domain/entities/investment_asset.dart';

class InvestmentAssetModel {
  final String id;
  final String name;
  final String category;
  final String? subCategory;
  final String type;
  final double investedAmount;
  final double currentValue;
  final String startDate;
  final double expectedCAGR;
  final double stepUpRate;
  final int? sipDurationYears;
  final bool isIncluded;

  const InvestmentAssetModel({
    required this.id,
    required this.name,
    required this.category,
    this.subCategory,
    required this.type,
    required this.investedAmount,
    required this.currentValue,
    required this.startDate,
    required this.expectedCAGR,
    this.stepUpRate = 0.0,
    this.sipDurationYears,
    this.isIncluded = true,
  });

  factory InvestmentAssetModel.fromEntity(InvestmentAsset entity) {
    return InvestmentAssetModel(
      id: entity.id,
      name: entity.name,
      category: entity.category.name,
      subCategory: entity.subCategory,
      type: entity.type.code,
      investedAmount: entity.investedAmount,
      currentValue: entity.currentValue,
      startDate: entity.startDate.toIso8601String(),
      expectedCAGR: entity.expectedCAGR,
      stepUpRate: entity.stepUpRate,
      sipDurationYears: entity.sipDurationYears,
      isIncluded: entity.isIncluded,
    );
  }

  InvestmentAsset toEntity() {
    return InvestmentAsset(
      id: id,
      name: name,
      category: AssetCategory.fromString(category),
      subCategory: subCategory,
      type: InvestmentType.fromString(type),
      investedAmount: investedAmount,
      currentValue: currentValue,
      startDate: DateTime.tryParse(startDate) ?? DateTime.now(),
      expectedCAGR: expectedCAGR,
      stepUpRate: stepUpRate,
      sipDurationYears: sipDurationYears,
      isIncluded: isIncluded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      if (subCategory != null) 'subCategory': subCategory,
      'type': type,
      'investedAmount': investedAmount,
      'currentValue': currentValue,
      'startDate': startDate,
      'expectedCAGR': expectedCAGR,
      'stepUpRate': stepUpRate,
      if (sipDurationYears != null) 'sipDurationYears': sipDurationYears,
      'isIncluded': isIncluded,
    };
  }

  factory InvestmentAssetModel.fromJson(Map<dynamic, dynamic> json) {
    return InvestmentAssetModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      subCategory: json['subCategory'] as String?,
      type: json['type'] as String? ?? 'ONE_TIME',
      investedAmount: (json['investedAmount'] as num?)?.toDouble() ?? 0.0,
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      startDate: json['startDate'] as String? ?? DateTime.now().toIso8601String(),
      expectedCAGR: (json['expectedCAGR'] as num?)?.toDouble() ?? 10.0,
      stepUpRate: (json['stepUpRate'] as num?)?.toDouble() ?? 0.0,
      sipDurationYears: json['sipDurationYears'] as int?,
      isIncluded: json['isIncluded'] as bool? ?? true,
    );
  }
}
