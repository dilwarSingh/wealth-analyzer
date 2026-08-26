import 'package:flutter/material.dart';
import 'asset_category.dart';

class SankeyNode {
  final String id;
  final String label;
  final double value;
  final Color color;
  final IconData? icon;
  final bool isSource;

  const SankeyNode({
    required this.id,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.isSource = false,
  });
}

class SankeyLink {
  final String sourceId;
  final String targetId;
  final double value;
  final Color color;
  final String targetLabel;

  const SankeyLink({
    required this.sourceId,
    required this.targetId,
    required this.value,
    required this.color,
    required this.targetLabel,
  });
}

class SankeyCashFlowData {
  final double totalMonthlyInflow;
  final List<SankeyNode> sourceNodes;
  final List<SankeyNode> targetNodes;
  final List<SankeyLink> links;

  const SankeyCashFlowData({
    required this.totalMonthlyInflow,
    required this.sourceNodes,
    required this.targetNodes,
    required this.links,
  });

  factory SankeyCashFlowData.empty() {
    return const SankeyCashFlowData(
      totalMonthlyInflow: 0.0,
      sourceNodes: [],
      targetNodes: [],
      links: [],
    );
  }
}
