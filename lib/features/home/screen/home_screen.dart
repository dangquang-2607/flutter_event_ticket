import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../../../core/app_routes.dart';
import '../../profile/screen/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final box = GetStorage();
  String userName = "";
  List<dynamic> events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    userName = box.read("userName") ?? "Người dùng";
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    // Giữ nguyên logic fetch API của bạn
    try {
      final token = box.read("accessToken");
      final url = Uri.parse("https://events-ticket.lehuuhieu.dev/api/events");

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          events = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        // Get.snackbar("Lỗi", "Không tải được sự kiện");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
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
        title: Text(
          "Eventick", 
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 42,
                          backgroundImage: AssetImage(
                            'assets/images/avatar/user.png'
                          ),
            ),
            onPressed: () {
              Get.to(() => const ProfileScreen());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            Text(
              "Xin chào, $userName!",
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const Text(
              "Hãy khám phá những sự kiện tuyệt vời!",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            
            TextField(
              decoration: InputDecoration(
                hintText: "Tìm kiếm sự kiện...",
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
            const SizedBox(height: 24),

            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAction(
                  icon: Icons.event_available,
                  label: "Mua vé",
                  onTap: () => Get.toNamed(AppRoutes.events),
                ),
                _buildAction(
                  icon: Icons.confirmation_number,
                  label: "Vé của tôi",
                  onTap: () {
                    // TODO
                  },
                ),
                _buildAction(
                  icon: Icons.list_alt,
                  label: "Sự kiện",
                  onTap: () => Get.toNamed(AppRoutes.events),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Event section header - Nâng cấp mới
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Sự kiện nổi bật",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.events),
                  child: const Text(
                    "Xem tất cả",
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),

            // Event list
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (events.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Không có sự kiện nào sắp diễn ra.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  // Sử dụng widget card mới
                  return _buildEventCard(event);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Widget cho các hành động nhanh (Giữ nguyên thiết kế gốc vì đã đẹp)
  Widget _buildAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.deepPurple.shade100,
            child: Icon(icon, size: 28, color: Colors.deepPurple),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
  final location = event['location'] ?? 'Chưa xác định';
  final date = event["date"] ?? "N/A";

  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 4,
    shadowColor: Colors.deepPurple.withOpacity(0.1),
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.asset(
              "assets/images/events/event.png", 
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event["title"] ?? "Không có tiêu đề",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today, date),
                const SizedBox(height: 4),
                _buildInfoRow(Icons.location_on, location),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


  // Widget phụ trợ cho Event Card - Nâng cấp mới
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}