import 'package:flutter/material.dart';

enum InsightSeverity {
  positive,
  info,
  improvement,
  priority
}

class InsightModel {
  final String type;
  final String title;
  final String detail;
  final String action;
  final InsightSeverity severity;
  final IconData icon;

  const InsightModel({
    required this.type,
    required this.title,
    required this.detail,
    required this.action,
    required this.severity,
    required this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'detail': detail,
      'action': action,
      'severity': severity.name,
    };
  }

  factory InsightModel.fromJson(Map<String, dynamic> json) {
    InsightSeverity parseSeverity(String name) {
      return InsightSeverity.values.firstWhere(
        (e) => e.name == name,
        orElse: () => InsightSeverity.info,
      );
    }

    return InsightModel(
      type: json['type'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      action: json['action'] as String,
      severity: parseSeverity(json['severity'] as String),
      icon: Icons.insights, // Default placeholder
    );
  }
}
