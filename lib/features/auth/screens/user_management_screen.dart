import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../../../core/constants.dart';
import '../model/user_model.dart';
import '../../../core/app_routes.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final box = GetStorage();
  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
    searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchUsers() async {
    try {
      final token = box.read("accessToken");
      final url = Uri.parse(AppConstants.adminUsersEndpoint);

      print("Fetching users from: $url");
      print("Token: $token");

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        // Filter chỉ lấy những user có role = "user"
        final filteredList = jsonData
            .where((item) => (item['role'] as String?)?.toLowerCase() == 'user')
            .toList();

        setState(() {
          users = filteredList.map((item) => UserModel.fromJson(item)).toList();
          filteredUsers = users;
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          isLoading = false;
        });
        Get.snackbar("Lỗi", "Token không hợp lệ hoặc hết hạn");
      } else if (response.statusCode == 403) {
        setState(() {
          isLoading = false;
        });
        Get.snackbar("Lỗi", "Bạn không có quyền truy cập danh sách người dùng");
      } else {
        setState(() {
          isLoading = false;
        });
        Get.snackbar(
          "Lỗi",
          "Lỗi ${response.statusCode}: Không tải được danh sách người dùng",
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Exception: $e");
      Get.snackbar("Lỗi", "Có lỗi xảy ra: $e");
    }
  }

  void _filterUsers() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users
            .where(
              (user) =>
                  user.userName.toLowerCase().contains(query) ||
                  user.email.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  Future<void> _toggleUserLock(UserModel user) async {
    try {
      final token = box.read("accessToken");
      final url = Uri.parse(
        "${AppConstants.adminUsersEndpoint}/${user.userId}/toggle-lock",
      );

      final response = await http.patch(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          "Thành công",
          user.isLocked
              ? "Đã mở tài khoản người dùng"
              : "Đã khóa tài khoản người dùng",
        );
        fetchUsers();
      } else {
        Get.snackbar("Lỗi", "Không thể thay đổi trạng thái tài khoản");
      }
    } catch (e) {
      Get.snackbar("Lỗi", "Có lỗi xảy ra: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Quản lý người dùng",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm theo tên hoặc email...",
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // User count
                  Text(
                    "Tổng số người dùng: ${filteredUsers.length}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User list
                  if (filteredUsers.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          searchController.text.isEmpty
                              ? "Không có người dùng nào"
                              : "Không tìm thấy người dùng",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return _buildUserCard(user);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    user.userName.isNotEmpty
                        ? user.userName[0].toUpperCase()
                        : "U",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: user.role == "Organizer"
                        ? Colors.orange.shade100
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: user.role == "Organizer"
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.calendar_today,
                    label: "Đăng ký",
                    value: _formatDate(user.createdDate),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.login,
                    label: "Lần cuối",
                    value: user.lastLoginDate != null
                        ? _formatDate(user.lastLoginDate!)
                        : "Chưa đăng nhập",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.to(() => UserDetailScreen(user: user));
                    },
                    icon: const Icon(Icons.person),
                    label: const Text("Xem chi tiết"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showLockConfirmDialog(user);
                    },
                    icon: Icon(user.isLocked ? Icons.lock_open : Icons.lock),
                    label: Text(
                      user.isLocked ? "Mở tài khoản" : "Khóa tài khoản",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user.isLocked
                          ? Colors.green.shade500
                          : Colors.red.shade500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (user.isLocked)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "🔒 Tài khoản đang bị khóa",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showLockConfirmDialog(UserModel user) {
    Get.dialog(
      AlertDialog(
        title: Text(user.isLocked ? "Mở tài khoản?" : "Khóa tài khoản?"),
        content: Text(
          user.isLocked
              ? "Bạn có chắc chắn muốn mở tài khoản của ${user.userName}?"
              : "Bạn có chắc chắn muốn khóa tài khoản của ${user.userName}?",
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              Get.back();
              _toggleUserLock(user);
            },
            child: Text(
              user.isLocked ? "Mở" : "Khóa",
              style: TextStyle(
                color: user.isLocked ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
