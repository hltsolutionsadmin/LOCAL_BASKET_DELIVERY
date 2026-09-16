import 'dart:async';
import 'package:flutter/services.dart';
import 'package:localbasket_delivery_partner/data/model/authentication/current_customer_model.dart';
import 'package:localbasket_delivery_partner/data/model/orders/FetchOrders/fetchOrders_model.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/authentication/currentcustomer/get/current_customer_state.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/orders/fetchOrders/fetchOrders_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/orders/fetchOrders/fetchOrders_state.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/orders/updateOrderStatus/updateOrderStatus_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/orders/updateOrderStatus/updateOrderStatus_state.dart';
import 'package:localbasket_delivery_partner/presentation/screens/dashboard/widgets/orderCard_widget.dart';
import 'package:localbasket_delivery_partner/presentation/screens/dashboard/widgets/orderCardShimmer_widget.dart';
import 'package:localbasket_delivery_partner/presentation/screens/profile/deliveryPartnerProfile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class DeliveryPartnerDashboard extends StatefulWidget {
  const DeliveryPartnerDashboard({super.key});

  @override
  State<DeliveryPartnerDashboard> createState() =>
      _DeliveryPartnerDashboardState();
}

class _DeliveryPartnerDashboardState extends State<DeliveryPartnerDashboard> {
  static const int _pageSize = 50;

  Timer? _timer;
  String? _partnerId;
  final ScrollController _scrollController = ScrollController();

  /// Accumulated orders across pages, keyed by id (keeps them de-duplicated
  /// as the 5s poll re-fetches the first page).
  final Map<String, Content> _ordersById = {};
  List<Content> _orders = [];

  int _page = 0;
  bool _isLastPage = false;
  bool _loadingMore = false;
  bool _initialLoading = true;

  /// Orders whose status update is in flight — their card button shows a
  /// spinner until the refreshed list actually reflects the new status.
  final Set<String> _updatingIds = {};

  /// orderId -> the status we just pushed, so we can tell a fresh list
  /// response apart from a stale poll response that was already in flight.
  final Map<String, String> _expectedStatus = {};
  bool _awaitingUpdateRefresh = false;
  int _updateRefreshAttempts = 0;

  /// orderId -> delivery step: 0 = needs accept, 1 = picked up,
  /// 2 = in delivery, 3 = done. Drives the card's linear button flow; all
  /// active orders start at 0 ("Accept") and advance locally on each tap.
  final Map<String, int> _steps = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<CurrentCustomerCubit>().state;
      if (state is CurrentCustomerLoaded) {
        _partnerId = state.currentCustomerModel.id;
        _fetchOrders(page: 0);
        _resumePolling();
      }
    });
  }

  void _resumePolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchOrders(page: 0);
    });
  }

  void _pausePolling() {
    _timer?.cancel();
    _timer = null;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final nearBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200;
    if (nearBottom && !_loadingMore && !_isLastPage && !_initialLoading) {
      setState(() {
        _loadingMore = true;
        _page += 1;
      });
      _fetchOrders(page: _page);
    }
  }

  void _fetchOrders({required int page}) {
    if (_partnerId == null || _partnerId!.isEmpty) return;
    context.read<FetchOrdersCubit>().fetchOrders({
      'partnerId': _partnerId,
      'page': page,
      'size': _pageSize,
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _ordersById.clear();
      _orders = [];
      _page = 0;
      _isLastPage = false;
      _loadingMore = false;
    });
    _fetchOrders(page: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<CurrentCustomerCubit, CurrentCustomerModel?>(
      (cubit) => cubit.state is CurrentCustomerLoaded
          ? (cubit.state as CurrentCustomerLoaded).currentCustomerModel
          : null,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: MultiBlocListener(
          listeners: [
            BlocListener<UpdateOrderStatusCubit, UpdateOrderStatusState>(
              listener: (context, state) {
                if (state is UpdateOrderStatusLoading) {
                  // Stop the 5s poll so a stale in-flight response can't
                  // overwrite the order we're about to change.
                  _pausePolling();
                  setState(() {
                    _updatingIds.add(state.orderId);
                    _expectedStatus[state.orderId] = state.status.toUpperCase();
                    final current = _steps[state.orderId] ?? 0;
                    _steps[state.orderId] = current < 3 ? current + 1 : current;
                  });
                } else if (state is UpdateOrderStatusSuccess) {
                  // Server accepted it — now pull one fresh list and keep the
                  // button spinning until that list reflects the new status.
                  _awaitingUpdateRefresh = true;
                  _updateRefreshAttempts = 0;
                  _fetchOrders(page: 0);
                } else if (state is UpdateOrderStatusFailure) {
                  setState(() {
                    _updatingIds.remove(state.orderId);
                    _expectedStatus.remove(state.orderId);
                    final current = _steps[state.orderId] ?? 1;
                    _steps[state.orderId] = current > 0 ? current - 1 : 0;
                  });
                  _resumePolling();
                }
              },
            ),
            BlocListener<FetchOrdersCubit, FetchOrdersState>(
              listener: (context, state) {
                if (state is FetchOrdersSuccess) {
                  final data = state.orders.data;
                  final pageNo = (data?.number ?? 0).toInt();
                  final content = data?.content ?? const <Content>[];

                  // A status update is settling.
                  if (_updatingIds.isNotEmpty) {
                    if (!_awaitingUpdateRefresh) {
                      // Update still running; ignore any poll noise.
                      return;
                    }
                    if (!_responseReflectsUpdate(content) &&
                        _updateRefreshAttempts < 5) {
                      // Stale response — server hasn't caught up. Retry.
                      _updateRefreshAttempts++;
                      Future.delayed(const Duration(milliseconds: 600), () {
                        if (mounted && _awaitingUpdateRefresh) {
                          _fetchOrders(page: 0);
                        }
                      });
                      return;
                    }
                  }

                  setState(() {
                    // First page while not paginated: the first page is the
                    // whole view, so replace outright to drop orders that
                    // moved away.
                    if (pageNo == 0 && _page == 0) {
                      _ordersById.clear();
                    }
                    for (final o in content) {
                      if (o.id != null) {
                        _ordersById[o.id!] = o;
                        _steps.putIfAbsent(
                          o.id!,
                          () => (o.status ?? '').toUpperCase() == 'DELIVERED'
                              ? 3
                              : 0,
                        );
                      }
                    }
                    // Drop finished steps once their order leaves the list.
                    _steps.removeWhere(
                        (id, step) => step >= 3 && !_ordersById.containsKey(id));
                    if (pageNo >= _page) {
                      _isLastPage = data?.last ?? true;
                    }
                    _loadingMore = false;
                    _initialLoading = false;
                    if (_awaitingUpdateRefresh) {
                      _updatingIds.clear();
                      _expectedStatus.clear();
                      _awaitingUpdateRefresh = false;
                      _updateRefreshAttempts = 0;
                      _resumePolling();
                    }
                    _orders = _sortByNewest(
                        _filterTodayActiveOrders(_ordersById.values.toList()));
                  });
                } else if (state is FetchOrdersFailure) {
                  setState(() {
                    _loadingMore = false;
                    _initialLoading = false;
                  });
                }
              },
            ),
          ],
          child: Column(
            children: [
              buildHeader(context, user),
              const SizedBox(height: 10),
              Expanded(child: _buildOrders()),
            ],
          ),
        ),
      ),
    );
  }

  /// `true` once the fetched list shows every just-updated order at its new
  /// status (or gone from the page, e.g. delivered).
  bool _responseReflectsUpdate(List<Content> content) {
    return _expectedStatus.entries.every((entry) {
      final matches = content.where((o) => o.id == entry.key);
      if (matches.isEmpty) return true;
      return (matches.first.status ?? '').toUpperCase() == entry.value;
    });
  }

  /// Only today's orders that still need action — delivered orders live in
  /// the "Completed Orders" list under Profile instead.
  List<Content> _filterTodayActiveOrders(List<Content> orders) {
    final now = DateTime.now();
    return orders.where((order) {
      final created = order.createdDate?.toLocal();
      final isToday = created != null &&
          created.year == now.year &&
          created.month == now.month &&
          created.day == now.day;
      final status = (order.status ?? '').toUpperCase();
      final step = order.id == null ? 0 : (_steps[order.id] ?? 0);
      return isToday && status != 'DELIVERED' && step < 3;
    }).toList();
  }

  List<Content> _sortByNewest(List<Content> orders) {
    final sorted = [...orders];
    sorted.sort((a, b) => (b.createdDate ?? DateTime(1970))
        .compareTo(a.createdDate ?? DateTime(1970)));
    return sorted;
  }

  Widget _buildOrders() {
    if (_initialLoading) {
      return const OrderListShimmer();
    }

    if (_orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Text(
                  "No orders yet",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _orders.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _orders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final order = _orders[index];
          return OrderCardWidget(
            key: ValueKey(order.id),
            order: order,
            step: order.id == null ? null : _steps[order.id],
            isUpdating: order.id != null && _updatingIds.contains(order.id),
          );
        },
      ),
    );
  }

  Widget buildHeader(BuildContext context, CurrentCustomerModel? user) {
    final initials = _getInitials(user?.fullName);

    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFFF6F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeliveryPartnerProfileScreen(),
                ),
              );
            },
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.9),
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF6F00),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Local Basket HD",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user?.fullName ?? 'Partner',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        user?.mobile ?? 'No Contact',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 9, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  "Active",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'NA';
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }
}
