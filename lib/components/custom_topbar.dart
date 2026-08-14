import 'package:localbasket_delivery_partner/core/constants/colors.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final bool orangeTheme;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.showBackButton = true,
    this.orangeTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = orangeTheme ? Colors.white : AppColor.black;
    return Material(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.15),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: orangeTheme
              ? const LinearGradient(
                  colors: [Color(0xFFFFA726), Color(0xFFFF6F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    AppColor.white.withOpacity(0.95),
                    AppColor.white.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Container(
            height: preferredSize.height - 30,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (showBackButton)
                  IconButton(
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                    color: foregroundColor,
                    onPressed: onBackPressed ?? () => Navigator.pop(context),
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(80); // increased height to include SafeArea
}
