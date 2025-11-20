import 'package:localbasket_delivery_partner/data/dataSource/reports/reports_datasource.dart';
import 'package:localbasket_delivery_partner/data/model/reports/reports_model.dart';
import 'package:localbasket_delivery_partner/domain/repository/reports/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource remoteDataSource;

  ReportsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ReportsModel> getReports(
      String frequency, String from, String to, String format) async {
    return await remoteDataSource.reports(frequency, from, to, format);
  }

  @override
  Future<List<int>> downloadExcel(
      String frequency, String from, String to) async {
    return await remoteDataSource.downloadExcel(frequency, from, to);
  }
}
