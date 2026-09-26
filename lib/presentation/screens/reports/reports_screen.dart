import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:localbasket_delivery_partner/core/injection.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/authentication/currentcustomer/get/current_customer_state.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/orders/ordersSummary/orders_summary_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/orders/ordersSummary/orders_summary_state.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersSummaryCubit>(
      create: (_) => sl<OrdersSummaryCubit>(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatefulWidget {
  const _ReportsView();

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  String _quickRange = 'daily';

  DateTime? _fromDate;
  DateTime? _toDate;

  final _df = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _applyQuickRange();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onGetSummary());
  }

  // Quick-select preset ranges.
  void _applyQuickRange() {
    final today = DateTime.now();

    if (_quickRange == "daily") {
      _fromDate = today;
      _toDate = today;
    } else if (_quickRange == "weekly") {
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      _fromDate = weekStart;
      _toDate = weekStart.add(const Duration(days: 6));
    } else if (_quickRange == "monthly") {
      _fromDate = DateTime(today.year, today.month, 1);
      _toDate = DateTime(today.year, today.month + 1, 0);
    }

    setState(() {});
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = (isFrom ? _fromDate : _toDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = picked;
      } else {
        _toDate = picked;
        if (_fromDate != null && _fromDate!.isAfter(picked)) _fromDate = picked;
      }
    });
    _onGetSummary();
  }

  String? get _partnerId {
    final state = context.read<CurrentCustomerCubit>().state;
    return state is CurrentCustomerLoaded
        ? state.currentCustomerModel.id
        : null;
  }

  void _onGetSummary() {
    final partnerId = _partnerId;
    if (partnerId == null || partnerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to load partner details.")),
      );
      return;
    }
    context.read<OrdersSummaryCubit>().loadSummary(
          partnerId: partnerId,
          from: _fromDate!,
          to: _toDate!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FC),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff4C5DFB), Color(0xff6A7CFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Revenue",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 GLASS FILTER CARD
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Filters",
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Colors.indigo)),

                        const SizedBox(height: 18),

                        _buildPremiumDropdown(
                          title: "Quick range",
                          value: _quickRange,
                          items: const [
                            DropdownMenuItem(
                                value: "daily", child: Text("Today")),
                            DropdownMenuItem(
                                value: "weekly", child: Text("This week")),
                            DropdownMenuItem(
                                value: "monthly", child: Text("This month")),
                          ],
                          onChanged: (v) {
                            _quickRange = v!;
                            _applyQuickRange();
                            _onGetSummary();
                          },
                        ),

                        const SizedBox(height: 18),

                        // 🔵 Editable date range
                        Row(
                          children: [
                            Expanded(
                              child: _dateField(
                                label: "From",
                                value: _fromDate,
                                onTap: () => _pickDate(isFrom: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dateField(
                                label: "To",
                                value: _toDate,
                                onTap: () => _pickDate(isFrom: false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 💰 DELIVERED + REVENUE SUMMARY
              _buildSummarySection(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DELIVERED + REVENUE SUMMARY
  // ---------------------------------------------------------------------------

  Widget _buildSummarySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xff1E2A78), Color(0xff4C5DFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Delivered & Revenue",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            _fromDate != null && _toDate != null
                ? "${_df.format(_fromDate!)}  →  ${_df.format(_toDate!)}"
                : "Pick a date range",
            style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
          const SizedBox(height: 16),
          BlocBuilder<OrdersSummaryCubit, OrdersSummaryState>(
            builder: (context, state) {
              if (state is OrdersSummaryLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                );
              }

              if (state is OrdersSummaryError) {
                return Text(
                  state.message,
                  style: const TextStyle(color: Colors.white),
                );
              }

              if (state is OrdersSummaryLoaded) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _summaryTile(
                            "Delivered Orders",
                            "${state.deliveredCount}",
                            Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summaryTile(
                            "Revenue",
                            "₹${state.revenue.toStringAsFixed(2)}",
                            Icons.currency_rupee,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _summaryTile(
                        "Delivered Order Value",
                        "₹${state.orderValue.toStringAsFixed(2)}",
                        Icons.receipt_long,
                      ),
                    ),
                  ],
                );
              }

              return Text(
                "Delivered orders and delivery-charge revenue for the selected range.",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 13),
              );
            },
          ),
          const SizedBox(height: 16),
          BlocBuilder<OrdersSummaryCubit, OrdersSummaryState>(
            builder: (context, state) {
              final busy = state is OrdersSummaryLoading;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (busy || _fromDate == null) ? null : _onGetSummary,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    busy ? "Loading…" : "Refresh",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  value != null ? _df.format(value) : "--",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// PREMIUM DROPDOWN WIDGET
  Widget _buildPremiumDropdown({
    required String title,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            isExpanded: true,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
