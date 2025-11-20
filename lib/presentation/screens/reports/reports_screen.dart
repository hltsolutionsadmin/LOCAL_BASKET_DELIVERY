import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/reports/reports_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/reports/reports_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _format = 'json';
  String _frequency = 'daily';

  DateTime? _fromDate;
  DateTime? _toDate;

  final _df = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _applyAutoDates(); // default auto-set for Daily
  }

  // AUTO DATE SELECTOR
  void _applyAutoDates() {
    final today = DateTime.now();

    if (_frequency == "daily") {
      _fromDate = today;
      _toDate = today;
    }

    if (_frequency == "weekly") {
      final weekStart =
          today.subtract(Duration(days: today.weekday - 1)); // Monday
      final weekEnd = weekStart.add(const Duration(days: 6)); // Sunday
      _fromDate = weekStart;
      _toDate = weekEnd;
    }

    if (_frequency == "monthly") {
      final monthStart = DateTime(today.year, today.month, 1);
      final nextMonth = DateTime(today.year, today.month + 1, 1);
      final monthEnd = nextMonth.subtract(const Duration(days: 1));
      _fromDate = monthStart;
      _toDate = monthEnd;
    }

    setState(() {});
  }

  // Save Excel
  Future<void> _saveExcel(List<int> bytes) async {
    try {
      String fileName = "report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      if (Platform.isAndroid) {
        // Request manage permission
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Storage permission required")),
          );
          return;
        }

        // Use MediaStore API (Shows in Files → Downloads)
        final directory = await getExternalStorageDirectory();
        final downloadsPath = "/storage/emulated/0/Download";

        final file = File("$downloadsPath/$fileName");
        await file.writeAsBytes(bytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Excel saved to Downloads:\n${file.path}"),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // ---------------- iOS ------------------
      else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/$fileName");
        await file.writeAsBytes(bytes);
        print(file.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Excel saved to Files app:\n${file.path}"),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save file: $e")),
      );
    }
  }

  // Submit
  void _onSubmit() {
    final from = _df.format(_fromDate!);
    final to = _df.format(_toDate!);

    if (_format == 'excel') {
      context.read<ReportsCubit>().downloadExcel(_frequency, from, to);
    } else {
      context.read<ReportsCubit>().fetchReports(_frequency, from, to, _format);
    }
  }

  @override
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
          "Reports",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocConsumer<ReportsCubit, ReportsState>(
          listener: (context, state) async {
            if (state is ReportsExcelSuccess) await _saveExcel(state.bytes);
            if (state is ReportsFailure) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final loading = state is ReportsLoading;

            return Column(
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
                            title: "Format",
                            value: _format,
                            items: const [
                              DropdownMenuItem(
                                  value: "json", child: Text("JSON")),
                              DropdownMenuItem(
                                  value: "excel", child: Text("Excel")),
                            ],
                            onChanged: loading
                                ? null
                                : (v) => setState(() => _format = v!),
                          ),

                          const SizedBox(height: 16),

                          _buildPremiumDropdown(
                            title: "Frequency",
                            value: _frequency,
                            items: const [
                              DropdownMenuItem(
                                  value: "daily", child: Text("Daily")),
                              DropdownMenuItem(
                                  value: "weekly", child: Text("Weekly")),
                              DropdownMenuItem(
                                  value: "monthly", child: Text("Monthly")),
                            ],
                            onChanged: loading
                                ? null
                                : (v) {
                                    _frequency = v!;
                                    _applyAutoDates();
                                  },
                          ),

                          const SizedBox(height: 18),

                          // 🔵 Auto Date Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Auto-selected Date Range",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.indigo.shade700)),
                                const SizedBox(height: 10),
                                Text("From: ${_df.format(_fromDate!)}"),
                                Text("To:     ${_df.format(_toDate!)}"),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // SUBMIT BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: loading ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                backgroundColor: Colors.indigo,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      _format == "excel"
                                          ? "Download Excel"
                                          : "Fetch JSON",
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // RESULTS
                if (state is ReportsSuccess)
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.model.data.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, i) {
                        final d = state.model.data[i];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // LEFT COLUMN
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.periodLabel != null
                                        ? _df.format(d.periodLabel!)
                                        : "N/A",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17),
                                  ),
                                  const SizedBox(height: 6),
                                  Text("Assigned: ${d.assignedCount ?? 0}",
                                      style: const TextStyle(fontSize: 14)),
                                  Text("Delivered: ${d.deliveredCount ?? 0}",
                                      style: const TextStyle(
                                          color: Colors.green, fontSize: 14)),
                                  Text("Pending: ${d.pendingCount ?? 0}",
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 14)),
                                ],
                              ),

                              // RIGHT PRICE
                              Text(
                                "₹${d.totalAmount ?? 0}",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
              ],
            );
          },
        ),
      ),
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

  // DROPDOWN BUILDER
  Widget _buildDropDown({
    required String title,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300)),
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
