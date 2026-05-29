import 'package:event_ticket_app/features/auth/screens/login_screen.dart';
import 'package:event_ticket_app/features/profile/screens/change_password_screen.dart';
import 'package:event_ticket_app/data/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:event_ticket_app/features/profile/screens/change_email_screen.dart';
import 'my_tickets_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>>? _futureProfile;
  final box = GetStorage();

  // Royal Amethyst Light & Slate Color System
  static const Color bgColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color primaryAmethyst = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF6D28D9);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final token = box.read("accessToken");

    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAll(() => const LoginScreen());
      });
    } else {
      setState(() {
        _futureProfile = ProfileService.getProfileMap();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_futureProfile == null) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primaryAmethyst)),
      );
    }
    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Top Header Gradient Banner
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryAmethyst, primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.elliptical(200, 40),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ),
                Positioned(
                  top: 120,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: primaryAmethyst.withValues(alpha: 0.25),
                              blurRadius: 16,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 52,
                          backgroundImage: AssetImage(
                            'assets/images/avatar/user.png',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // FutureBuilder user info
                      FutureBuilder<Map<String, dynamic>>(
                        future: _futureProfile,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 60,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text(
                              "Lỗi tải thông tin",
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 15,
                              ),
                            );
                          }
                          if (snapshot.hasData) {
                            final user = snapshot.data!;
                            return Column(
                              children: [
                                Text(
                                  user['username'] ?? 'Người dùng',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user['email'] ?? 'Không có email',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            );
                          }
                          return const Text("Không có dữ liệu", style: TextStyle(color: textSecondary));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 130),

            // Sleek Profile Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat("Sự kiện", "12"),
                    _buildStatDivider(),
                    _buildStat("Sắp diễn ra", "3"),
                    _buildStatDivider(),
                    _buildStat("Theo dõi", "120"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Profile Actions List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildProfileMenuItem(
                      icon: Icons.person_outline_rounded,
                      title: "Chỉnh sửa hồ sơ",
                      color: primaryAmethyst,
                      onTap: () {
                        Get.to(() => const ChangeEmailScreen());
                      },
                    ),
                    _buildDivider(),
                    _buildProfileMenuItem(
                      icon: Icons.lock_open_rounded,
                      title: "Thay đổi mật khẩu",
                      color: primaryDark,
                      onTap: () {
                        Get.to(() => const ChangePasswordScreen());
                      },
                    ),
                    _buildDivider(),
                    _buildProfileMenuItem(
                      icon: Icons.confirmation_number_outlined,
                      title: "Sự kiện của tôi",
                      color: accentTeal,
                      onTap: () {
                        Get.to(() => const MyTicketsScreen());
                      },
                    ),
                    _buildDivider(),
                    _buildProfileMenuItem(
                      icon: Icons.logout_rounded,
                      title: "Đăng xuất",
                      color: const Color(0xFFEF4444),
                      isLogout: true,
                      onTap: () {
                        box.remove("accessToken");
                        box.remove("userName");
                        box.remove("role");
                        Get.offAll(() => const LoginScreen());
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryAmethyst,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 13, color: textSecondary)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 30, width: 1.2, color: borderColor);
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: borderColor, indent: 56, endIndent: 16);
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600, 
          color: isLogout ? const Color(0xFFEF4444) : textPrimary,
          fontSize: 15,
        ),
      ),
      trailing: isLogout
          ? null
          : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textSecondary),
    );
  }
}
