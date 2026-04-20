// Import service mới và các thư viện cần thiết
import 'package:event_ticket_app/features/auth/screens/login_screen.dart';
import 'package:event_ticket_app/features/profile/screen/change_password_screen.dart';
import 'package:event_ticket_app/features/profile/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:event_ticket_app/features/profile/screen/change_email_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>>? _futureProfile;
  final box = GetStorage();

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
        _futureProfile = ProfileService.getProfile();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_futureProfile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.elliptical(200, 60),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ),
                Positioned(
                  top: 130,
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 52,
                          backgroundImage: AssetImage('assets/images/avatar/user.png'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Dùng FutureBuilder để xây dựng UI từ kết quả API
                      FutureBuilder<Map<String, dynamic>>(
                        future: _futureProfile,
                        builder: (context, snapshot) {
                          // Khi đang chờ dữ liệu
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Column(
                              children: [
                                Text("Đang tải...", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple),
                              ],
                            );
                          }
                          // Khi có lỗi xảy ra
                          if (snapshot.hasError) {
                            return Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.red, fontSize: 16));
                          }
                          // Khi có dữ liệu thành công
                          if (snapshot.hasData) {
                            final user = snapshot.data!;
                            return Column(
                              children: [
                                Text(
                                  user['username'] ?? 'Người dùng',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user['email'] ?? 'Không có email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            );
                          }
                          // Trạng thái mặc định
                          return const Text("Không có dữ liệu");
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 120),

            // --- STATS SECTION (Giữ nguyên) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            
            const SizedBox(height: 20),

            // --- MENU ACTIONS SECTION (Giữ nguyên) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildProfileMenuItem(
                      icon: Icons.edit_outlined,
                      title: "Chỉnh sửa hồ sơ",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChangeEmailScreen()),
                        );
                      },
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.edit_outlined,
                      title: "Thay đổi mật khẩu",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                        );
                      },
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.event_note_outlined,
                      title: "Sự kiện của tôi",
                      onTap: () {},
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.settings_outlined,
                      title: "Cài đặt",
                      onTap: () {},
                    ),
                    _buildProfileMenuItem(
                      icon: Icons.logout,
                      title: "Đăng xuất",
                      isLogout: true,
                      onTap: () {
                        // Xóa token và dữ liệu người dùng khi đăng xuất
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
            const SizedBox(height: 20),
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
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final color = isLogout ? Colors.redAccent : Colors.grey[700];

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      trailing: isLogout
          ? null
          : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
    );
  }
}