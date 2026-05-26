import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/services/event_service.dart';
import '../../../data/models/event_model.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final box = GetStorage();
  String userName = "";
  String userRole = "";
  List<Event> events = [];
  List<Event> filteredEvents = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    userName = box.read("userName") ?? "Người dùng";
    userRole = box.read("role") ?? "User";
    searchController.addListener(_filterEvents);
    fetchEvents();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchEvents() async {
    setState(() => isLoading = true);
    try {
      final result = await EventService.getEvents();
      if (!mounted) return;
      setState(() {
        events = result;
        _filterEvents();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      Get.snackbar("Lỗi", "Có lỗi xảy ra: $e");
    }
  }

  void _filterEvents() {
    final query = searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        filteredEvents = events;
      } else {
        filteredEvents = events
            .where(
              (e) =>
                  e.title.toLowerCase().contains(query) ||
                  e.location.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
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
              backgroundImage: AssetImage('assets/images/avatar/user.png'),
            ),
            onPressed: () {
              Get.to(() => const ProfileScreen());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchEvents,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  color: Colors.black87,
                ),
              ),
              const Text(
                "Hãy khám phá những sự kiện tuyệt vời!",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Tìm kiếm sự kiện...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => searchController.clear(),
                        )
                      : null,
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
                children: userRole.toLowerCase() == "organizer"
                    ? [
                        _buildAction(
                          icon: Icons.confirmation_number,
                          label: "Quản lý vé",
                          onTap: () => Get.toNamed(AppRoutes.ticketManagement),
                        ),
                        _buildAction(
                          icon: Icons.people,
                          label: "Quản lý người dùng",
                          onTap: () => Get.toNamed(AppRoutes.userManagement),
                        ),
                        _buildAction(
                          icon: Icons.event_note,
                          label: "Quản lý sự kiện",
                          onTap: () => Get.toNamed(AppRoutes.events),
                        ),
                      ]
                    : [
                        _buildAction(
                          icon: Icons.event_available,
                          label: "Mua vé",
                          onTap: () => Get.toNamed(AppRoutes.events),
                        ),
                        _buildAction(
                          icon: Icons.confirmation_number,
                          label: "Vé của tôi",
                          onTap: () {},
                        ),
                        _buildAction(
                          icon: Icons.list_alt,
                          label: "Sự kiện",
                          onTap: () => Get.toNamed(AppRoutes.events),
                        ),
                      ],
              ),

              const SizedBox(height: 30),

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
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (filteredEvents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      searchController.text.isNotEmpty
                          ? "Không tìm thấy sự kiện nào."
                          : "Không có sự kiện nào sắp diễn ra.",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(filteredEvents[index]);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildEventCard(Event event) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.deepPurple.withValues(alpha: 0.1),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
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
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    "${event.startTime.day}/${event.startTime.month}/${event.startTime.year}",
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(Icons.location_on, event.location),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
