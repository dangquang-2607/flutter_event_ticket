import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/services/event_service.dart';
import '../../../data/models/event_model.dart';
import '../../profile/screens/profile_screen.dart';
import '../../events/screens/event_detail_screen.dart';
import '../../profile/screens/my_tickets_screen.dart';

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
  
  String selectedCategory = "Tất cả";
  final List<String> categories = ["Tất cả", "Nhạc hội", "Công nghệ", "Hội thảo"];

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
    userName = box.read("userName") ?? "Người dùng";
    userRole = box.read("role") ?? "User";
    searchController.addListener(_applyFiltersAndSearch);
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
        _applyFiltersAndSearch();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      Get.snackbar("Lỗi", "Có lỗi xảy ra khi tải dữ liệu: $e",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  void _applyFiltersAndSearch() {
    final query = searchController.text.toLowerCase().trim();
    final cat = selectedCategory.toLowerCase();

    setState(() {
      filteredEvents = events.where((e) {
        // Apply search query
        final matchesSearch = query.isEmpty ||
            e.title.toLowerCase().contains(query) ||
            e.location.toLowerCase().contains(query);

        // Apply category filter
        bool matchesCategory = true;
        if (cat != "tất cả") {
          if (cat == "nhạc hội") {
            matchesCategory = e.title.toLowerCase().contains("nhạc") || 
                              e.title.toLowerCase().contains("concert") || 
                              e.description.toLowerCase().contains("nhạc");
          } else if (cat == "công nghệ") {
            matchesCategory = e.title.toLowerCase().contains("công nghệ") || 
                              e.title.toLowerCase().contains("tech") || 
                              e.title.toLowerCase().contains("flutter") ||
                              e.description.toLowerCase().contains("công nghệ");
          } else if (cat == "hội thảo") {
            matchesCategory = e.title.toLowerCase().contains("hội thảo") || 
                              e.title.toLowerCase().contains("seminar") || 
                              e.description.toLowerCase().contains("hội thảo");
          }
        }

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final featured = events.take(3).toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchEvents,
          color: primaryAmethyst,
          backgroundColor: cardColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Xin chào, $userName! 👋",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Khám phá các sự kiện hot nhất",
                            style: TextStyle(fontSize: 14, color: textSecondary),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Get.to(() => const ProfileScreen()),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryAmethyst, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: primaryAmethyst.withValues(alpha: 0.15),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 22,
                            backgroundImage: AssetImage('assets/images/avatar/user.png'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sleek Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: borderColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      style: const TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        hintText: "Tìm kiếm tên sự kiện, địa điểm...",
                        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                        prefixIcon: const Icon(Icons.search, color: primaryAmethyst),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20, color: textSecondary),
                                onPressed: () => searchController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Action Dashboard
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: userRole.toLowerCase() == "organizer"
                        ? [
                            _buildSaaSAction(
                              icon: Icons.confirmation_number_outlined,
                              label: "Quản lý vé",
                              color: primaryAmethyst,
                              onTap: () => Get.toNamed(AppRoutes.ticketManagement),
                            ),
                            _buildSaaSAction(
                              icon: Icons.people_outline_rounded,
                              label: "Quản lý User",
                              color: primaryDark,
                              onTap: () => Get.toNamed(AppRoutes.userManagement),
                            ),
                            _buildSaaSAction(
                              icon: Icons.event_note_outlined,
                              label: "Sự kiện của tôi",
                              color: accentTeal,
                              onTap: () => Get.toNamed(AppRoutes.events),
                            ),
                          ]
                        : [
                            _buildSaaSAction(
                              icon: Icons.local_activity_outlined,
                              label: "Mua vé",
                              color: primaryAmethyst,
                              onTap: () => Get.toNamed(AppRoutes.events),
                            ),
                            _buildSaaSAction(
                              icon: Icons.confirmation_number_outlined,
                              label: "Vé của tôi",
                              color: primaryDark,
                              onTap: () => Get.to(() => const MyTicketsScreen()),
                            ),
                            _buildSaaSAction(
                              icon: Icons.explore_outlined,
                              label: "Khám phá",
                              color: accentTeal,
                              onTap: () => Get.toNamed(AppRoutes.events),
                            ),
                          ],
                  ),
                ),
                const SizedBox(height: 28),

                // Featured Events (Carousel Slider)
                if (featured.isNotEmpty && searchController.text.isEmpty && selectedCategory == "Tất cả") ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: primaryAmethyst,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Sự kiện nổi bật 🌟",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: featured.length,
                      itemBuilder: (context, index) {
                        return _buildSaaSFeaturedCard(featured[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Explore & Quick Filters Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: primaryDark,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Khám phá theo danh mục",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Category Chips List
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: primaryAmethyst,
                          backgroundColor: cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? primaryAmethyst : borderColor,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                selectedCategory = cat;
                                _applyFiltersAndSearch();
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Main Events List
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(child: CircularProgressIndicator(color: primaryAmethyst)),
                  )
                else if (filteredEvents.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            "Không tìm thấy sự kiện nào phù hợp.",
                            style: TextStyle(fontSize: 15, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      return _buildSaaSNormalCard(filteredEvents[index]);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaaSAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: textPrimary, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaaSFeaturedCard(Event event) {
    final dateStr = "${event.startTime.day}/${event.startTime.month}";
    final priceStr = event.price > 0 
        ? "${NumberFormat('#,##0', 'vi_VN').format(event.price)}đ" 
        : "Free";

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Event Image
            Image.asset(
              "assets/images/events/event.png",
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Tags (Date & Price)
            Positioned(
              top: 12,
              left: 12,
              child: Row(
                children: [
                  _buildTagBadge(dateStr, primaryAmethyst),
                  const SizedBox(width: 8),
                  _buildTagBadge(priceStr, accentTeal),
                ],
              ),
            ),
            // Content (Bottom)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => Get.to(() => EventDetailScreen(eventId: event.id!, userRole: userRole)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAmethyst,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Chi tiết vé", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaaSNormalCard(Event event) {
    final formattedPrice = event.price > 0 
        ? "${NumberFormat('#,##0', 'vi_VN').format(event.price)} đ"
        : "Miễn phí";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Get.to(() => EventDetailScreen(eventId: event.id!, userRole: userRole)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Event Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  "assets/images/events/event.png",
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              // Event Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: primaryAmethyst),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: const TextStyle(fontSize: 12, color: textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: primaryDark),
                        const SizedBox(width: 4),
                        Text(
                          "${event.startTime.day}/${event.startTime.month}/${event.startTime.year}",
                          style: const TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Price and arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedPrice,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: event.price > 0 ? primaryAmethyst : accentTeal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
          )
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
