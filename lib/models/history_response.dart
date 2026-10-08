

import 'analysis_result.dart';

class HistoryResponse {
  final List<AnalysisResult> records;
  final int total;
  final int page;
  final int perPage;
  final int pages;

  const HistoryResponse({
    required this.records,
    required this.total,
    required this.page,
    required this.perPage,
    required this.pages,
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawList = (json['records'] as List<dynamic>? ?? []);
    return HistoryResponse(
      records: rawList
          .map((e) => AnalysisResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      total:   (json['total']    ?? 0)  as int,
      page:    (json['page']     ?? 1)  as int,
      perPage: (json['per_page'] ?? 20) as int,
      pages:   (json['pages']    ?? 1)  as int,
    );
  }
}