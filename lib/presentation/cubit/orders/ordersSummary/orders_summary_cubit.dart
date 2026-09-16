import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localbasket_delivery_partner/domain/usecase/orders/fetchOrders/fetchOrders_usecase.dart';

import 'orders_summary_state.dart';

/// Builds a delivered-orders + delivery-charge-revenue summary for a custom
/// date range by paging through the partner orders API and filtering by
/// `createdDate` on the client.
///
/// The orders endpoint returns pages sorted by `createdDate` descending, so we
/// can stop early once a page's oldest order falls before the selected window.
class OrdersSummaryCubit extends Cubit<OrdersSummaryState> {
  final FetchOrdersUseCase _fetchOrdersUseCase;

  OrdersSummaryCubit(this._fetchOrdersUseCase) : super(OrdersSummaryInitial());

  static const int _pageSize = 100;
  static const int _maxPages = 50; // hard safety cap (~5000 orders)

  Future<void> loadSummary({
    required String partnerId,
    required DateTime from,
    required DateTime to,
  }) async {
    emit(OrdersSummaryLoading());

    try {
      final start = DateTime(from.year, from.month, from.day);
      final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

      var deliveredCount = 0;
      var revenue = 0.0;
      var totalInRange = 0;
      var page = 0;
      var last = false;

      while (!last && page < _maxPages) {
        final result = await _fetchOrdersUseCase.call({
          'partnerId': partnerId,
          'page': page,
          'size': _pageSize,
        });

        final data = result.data;
        final content = data?.content ?? const [];

        for (final order in content) {
          final created = order.createdDate?.toLocal();
          if (created == null) continue;
          if (created.isBefore(start) || created.isAfter(end)) continue;

          totalInRange++;
          if ((order.status ?? '').toUpperCase() == 'DELIVERED') {
            deliveredCount++;
            revenue += order.deliveryCharge ?? 0;
          }
        }

        last = data?.last ?? true;

        // Early-out: results are newest-first, so once the oldest order on this
        // page predates the window there is nothing left to collect.
        if (content.isNotEmpty) {
          final oldest = content.last.createdDate?.toLocal();
          if (oldest != null && oldest.isBefore(start)) last = true;
        }

        page++;
      }

      emit(OrdersSummaryLoaded(
        deliveredCount: deliveredCount,
        revenue: revenue,
        totalOrdersInRange: totalInRange,
        from: start,
        to: to,
      ));
    } catch (e) {
      emit(OrdersSummaryError(e.toString()));
    }
  }
}
