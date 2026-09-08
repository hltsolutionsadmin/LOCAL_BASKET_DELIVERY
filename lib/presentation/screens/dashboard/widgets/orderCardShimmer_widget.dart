import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton placeholder shaped like [OrderCardWidget], shown while the
/// orders list is loading for the first time.
class OrderCardShimmer extends StatelessWidget {
  const OrderCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _block(width: 110, height: 14),
                      const SizedBox(height: 8),
                      _block(width: 70, height: 20, radius: 8),
                    ],
                  ),
                ),
                _block(width: 50, height: 14),
              ],
            ),
            const SizedBox(height: 16),
            _block(width: double.infinity, height: 8, radius: 6),
            const SizedBox(height: 18),
            _block(width: double.infinity, height: 14),
            const SizedBox(height: 10),
            _block(width: double.infinity, height: 14),
            const SizedBox(height: 18),
            _block(width: double.infinity, height: 44, radius: 14),
          ],
        ),
      ),
    );
  }

  Widget _block({required double width, required double height, double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A scroll-free list of a few shimmer cards, for the initial loading state.
class OrderListShimmer extends StatelessWidget {
  final int count;

  const OrderListShimmer({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: count,
      itemBuilder: (context, index) => const OrderCardShimmer(),
    );
  }
}
