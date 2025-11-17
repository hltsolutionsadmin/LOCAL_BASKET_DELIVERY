import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localbasket_delivery_partner/domain/usecase/reports/reports_usecase.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final ReportsUseCase useCase;

  ReportsCubit({required this.useCase}) : super(ReportsInitial());

  Future<void> fetchReports(
      String frequency, String from, String to, String format) async {
    emit(ReportsLoading());

    try {
      final result = await useCase(frequency, from, to, format);
      emit(ReportsSuccess(result));
    } catch (e) {
      emit(ReportsFailure(e.toString()));
    }
  }

  Future<void> downloadExcel(
      String frequency, String from, String to) async {
    emit(ReportsLoading());
    try {
      final bytes = await useCase.downloadExcel(frequency, from, to);
      emit(ReportsExcelSuccess(bytes));
    } catch (e) {
      emit(ReportsFailure(e.toString()));
    }
  }
}
