import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:localbasket_delivery_partner/core/injection.dart';
import 'package:localbasket_delivery_partner/core/utils/distance_calculator.dart';
import 'package:localbasket_delivery_partner/data/model/orders/FetchOrders/fetchOrders_model.dart';
import 'package:localbasket_delivery_partner/domain/usecase/orders/fetchOrders/fetchOrders_usecase.dart';
import 'package:localbasket_delivery_partner/presentation/screens/dashboard/widgets/dashboard_widgets.dart';

/// Expanded order details shown once the partner has accepted an order.
///
/// Loads the order from the order details API (`api/orders/{id}`) and shows
/// the customer (with a call button on `shippingAddressId.mobileNumber`), the
/// store (`storeId` lat/lng) and delivery (`shippingAddressId` lat/lng)
/// locations with navigation and the items. Falls back to the list
/// data in [order] while loading or if the details call fails.
class OrderDetailsSection extends StatefulWidget {
  final Content order;

  const OrderDetailsSection({super.key, required this.order});

  @override
  State<OrderDetailsSection> createState() => _OrderDetailsSectionState();
}

class _OrderDetailsSectionState extends State<OrderDetailsSection> {
  late Future<Content> _details;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final id = widget.order.id;
    _details = id == null
        ? Future.value(widget.order)
        : sl<FetchOrderDetailsUseCase>().call(id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Content>(
      future: _details,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final o = snapshot.data ?? widget.order;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            if (loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Center(child: CupertinoActivityIndicator()),
              ),
            if (snapshot.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(_load),
                  child: Text(
                    "Couldn't load order details. Tap to retry.",
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.red.shade400),
                  ),
                ),
              ),
            _customerRow(o),
            const SizedBox(height: 12),
            _locationRow(
              title: "Pickup",
              subtitle: _pickupText(o),
              icon: Icons.store,
              color: Colors.orange.shade400,
              latitude: o.store?.latitude,
              longitude: o.store?.longitude,
            ),
            const SizedBox(height: 12),
            _locationRow(
              title: "Delivery",
              subtitle: o.shippingAddress?.fullAddress ?? "Address not shared",
              icon: Icons.delivery_dining,
              color: Colors.teal.shade400,
              latitude: o.shippingAddress?.latitude,
              longitude: o.shippingAddress?.longitude,
            ),
            if (_distanceText(o) != null) ...[
              const SizedBox(height: 8),
              Text(
                _distanceText(o)!,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
            if (o.lineItems.isNotEmpty) ...[
              const Divider(height: 24),
              _sectionTitle("Items"),
              const SizedBox(height: 6),
              ...o.lineItems.map(_itemRow),
            ],
          ],
        );
      },
    );
  }

  Widget _customerRow(Content o) {
    final phone = o.shippingAddress?.mobileNumber ?? o.mobileNumber;
    return Row(
      children: [
        Expanded(
          child: infoRow(
            icon: Icons.person,
            color: Colors.blue.shade400,
            title: "Customer${phone != null ? " · $phone" : ""}",
            subtitle: o.customerName ?? "Customer",
          ),
        ),
        IconButton(
          icon: Icon(Icons.phone,
              color: phone == null ? Colors.grey : Colors.green),
          onPressed:
              phone == null ? null : () => launchUrl(Uri.parse("tel:$phone")),
        ),
      ],
    );
  }

  Widget _locationRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    double? latitude,
    double? longitude,
  }) {
    final hasCoords = latitude != null && longitude != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              infoRow(
                icon: icon,
                color: color,
                title: title,
                subtitle: subtitle,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 2),
                child: Text(
                  hasCoords
                      ? "${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}"
                      : "Location not shared",
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.navigation, color: color),
          onPressed: () =>
              _openMap(subtitle, latitude: latitude, longitude: longitude),
        ),
      ],
    );
  }

  Widget _itemRow(LineItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        "${item.productName ?? "Item"} × ${item.quantity ?? 1}",
        style: GoogleFonts.poppins(fontSize: 13),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
      );

  String _pickupText(Content o) {
    final address = o.store?.address?.trim();
    final parts = [
      o.storeName,
      if (address != null && address.isNotEmpty) address,
    ].whereType<String>();
    return parts.isEmpty ? "N/A" : parts.join(", ");
  }

  /// Store → customer straight-line distance, only when the customer shared
  /// real coordinates (never the sample fallback).
  String? _distanceText(Content o) {
    final km = tryCalculateDistanceKm(
      o.store?.latitude,
      o.store?.longitude,
      o.shippingAddress?.latitude,
      o.shippingAddress?.longitude,
    );
    return km == null ? null : "Distance: ${km.toStringAsFixed(2)} km";
  }

  void _openMap(String address, {double? latitude, double? longitude}) async {
    final destination = (latitude != null && longitude != null)
        ? '$latitude,$longitude'
        : Uri.encodeComponent(address);
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$destination';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
