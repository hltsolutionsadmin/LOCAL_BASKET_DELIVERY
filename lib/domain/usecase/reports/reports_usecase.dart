import 'package:localbasket_delivery_partner/data/model/reports/reports_model.dart';
import 'package:localbasket_delivery_partner/domain/repository/reports/reports_repository.dart';

class ReportsUseCase {
  final ReportsRepository repository;

  ReportsUseCase({required this.repository});

  Future<ReportsModel> call(
      String frequency, String from, String to, String format) async {
    return await repository.getReports(frequency, from, to, format);
  }

  Future<List<int>> downloadExcel(
      String frequency, String from, String to) async {
    return await repository.downloadExcel(frequency, from, to);
  }
}
