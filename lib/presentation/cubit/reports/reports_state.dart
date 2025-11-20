import 'package:localbasket_delivery_partner/data/model/reports/reports_model.dart';

abstract class ReportsState {}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsSuccess extends ReportsState {
  final ReportsModel model;

  ReportsSuccess(this.model);
}

class ReportsExcelSuccess extends ReportsState {
  final List<int> bytes;

  ReportsExcelSuccess(this.bytes);
}

class ReportsFailure extends ReportsState {
  final String message;

  ReportsFailure(this.message);
}
