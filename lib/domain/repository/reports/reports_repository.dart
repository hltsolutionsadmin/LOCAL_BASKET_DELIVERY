import 'package:localbasket_delivery_partner/data/model/reports/reports_model.dart';

abstract class ReportsRepository {
  Future<ReportsModel> getReports(
      String frequency, String from, String to, String format);
  Future<List<int>> downloadExcel(
      String frequency, String from, String to);
}
