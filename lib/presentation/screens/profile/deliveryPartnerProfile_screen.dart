import 'package:localbasket_delivery_partner/components/custom_topbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:localbasket_delivery_partner/components/custom_snackbar.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/authentication/currentcustomer/get/current_customer_state.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/authentication/deleteAccount/deleteAccount_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/authentication/deleteAccount/deleteAccount_state.dart';
import 'package:localbasket_delivery_partner/presentation/screens/authentication/login_screen.dart';
import 'package:localbasket_delivery_partner/presentation/screens/profile/logout.dart';
import 'package:localbasket_delivery_partner/presentation/screens/reports/reports_screen.dart';

class DeliveryPartnerProfileScreen extends StatefulWidget {
  const DeliveryPartnerProfileScreen({super.key});

  @override
  State<DeliveryPartnerProfileScreen> createState() =>
      _DeliveryPartnerProfileScreenState();
}

class _DeliveryPartnerProfileScreenState
    extends State<DeliveryPartnerProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _avatarController;

  @override
  void initState() {
    super.initState();
    context.read<CurrentCustomerCubit>().GetCurrentCustomer(context);
    _avatarController =
        AnimationController(duration: const Duration(seconds: 1), vsync: this)
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: const CustomAppBar(title: "Profile", orangeTheme: true),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: BlocBuilder<CurrentCustomerCubit, CurrentCustomerState>(
                  builder: (context, state) {
                    if (state is CurrentCustomerLoaded) {
                      final user = state.currentCustomerModel;

                      String getInitials(String? fullName) {
                        if (fullName == null || fullName.trim().isEmpty) {
                          return 'NA';
                        }
                        final parts = fullName.trim().split(' ');
                        if (parts.length == 1) return parts[0][0].toUpperCase();
                        return (parts[0][0] + parts.last[0]).toUpperCase();
                      }

                      final initials = getInitials(user.fullName);

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFA726), Color(0xFFFF6F00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
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
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white.withOpacity(0.9),
                              child: Text(
                                initials,
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFF6F00),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName ?? 'No Name',
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone,
                                          size: 15, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        user.mobile ?? 'No Contact',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (state is CurrentCustomerLoading) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: CupertinoActivityIndicator(),
                      );
                    } else if (state is CurrentCustomerError) {
                      return const Text("N/A");
                    }
                    return const SizedBox();
                  },
                ),
              ),

              const SizedBox(height: 40),

              /// Logout & Delete buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _optionTile(
                      title: "Reports",
                      icon: Icons.assessment_outlined,
                      color: const Color(0xFFFF6F00),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReportsScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _optionTile(
                      title: "Logout",
                      icon: Icons.logout,
                      color: const Color(0xFFFF6F00),
                      onTap: () {
                        _showBottomSheet(const LogOutCnfrmBottomSheet());
                      },
                    ),
                    const SizedBox(height: 16),
                    _optionTile(
                      title: "Delete Account",
                      icon: Icons.delete_forever,
                      color: Colors.red,
                      onTap: _showDeleteConfirmationSheet,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(Widget child) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => child,
    );
  }

  void _showDeleteConfirmationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return BlocProvider.value(
          value: context.read<DeleteAccountCubit>(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
              listener: (context, state) async {
                if (state is DeleteAccountSuccess) {
                  Navigator.pop(context);
                  CustomSnackbars.showSuccessSnack(
                    context: context,
                    title: "Deleted",
                    message: "Account deleted successfully",
                  );
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                } else if (state is DeleteAccountFailure) {
                  CustomSnackbars.showErrorSnack(
                    context: context,
                    title: "Failed",
                    message: "Couldn't delete your account",
                  );
                }
              },
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.redAccent, size: 50),
                    const SizedBox(height: 16),
                    const Text("Confirm Delete",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent)),
                    const SizedBox(height: 8),
                    const Text(
                      "This action will remove your account permanently.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent),
                            onPressed: state is DeleteAccountLoading
                                ? null
                                : () {
                                    context
                                        .read<DeleteAccountCubit>()
                                        .deleteAccount();
                                  },
                            child: state is DeleteAccountLoading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text("Delete"),
                          ),
                        ),
                      ],
                    )
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
