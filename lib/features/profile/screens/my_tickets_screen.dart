import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  List<dynamic> tickets = [];
  bool isLoading = true;

  // Royal Amethyst Light & Slate Color System
  static const Color bgColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color primaryAmethyst = Color(0xFF7C3AED);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    fetchMyTickets();
  }

  Future<void> fetchMyTickets() async {
    setState(() => isLoading = true);
    try {
      final box = GetStorage();
      final token = box.read("accessToken");

      final url = Uri.parse("${AppConstants.profileEndpoint}/attended-events");
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          tickets = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        Get.snackbar("Lỗi", "Không thể tải danh sách vé: ${response.statusCode}",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar("Lỗi", "Lỗi mạng hoặc máy chủ: $e",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> cancelTicket(int registrationId) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 8),
            Text("Hủy đăng ký vé?", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Bạn có chắc chắn muốn hủy tham gia sự kiện này? Hành động này không thể hoàn tác.",
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Quay lại", style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Hủy vé"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      final box = GetStorage();
      final token = box.read("accessToken");

      final url = Uri.parse("${AppConstants.registrationsEndpoint}/cancel-registration/$registrationId");
      final response = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        Get.snackbar("Thành công", "Đã hủy đăng ký sự kiện thành công.",
            backgroundColor: Colors.green, colorText: Colors.white);
        fetchMyTickets();
      } else {
        setState(() => isLoading = false);
        Get.snackbar("Lỗi", "Không thể hủy vé: Lỗi ${response.statusCode}",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar("Lỗi", "Lỗi kết nối mạng: $e",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  void showQrTicketDialog(Map<String, dynamic> ticket) {
    final regId = ticket["registrationId"];
    final title = ticket["eventTitle"] ?? "Sự kiện";
    final qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=TICKET_REG_ID_$regId";

    Get.dialog(
      Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: primaryAmethyst.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                "Mã vé: #TICKET-$regId",
                style: const TextStyle(fontSize: 14, color: primaryAmethyst, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              // White Card container for QR code scanning stability
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAmethyst.withValues(alpha: 0.1),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    qrUrl,
                    height: 180,
                    width: 180,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        height: 180,
                        width: 180,
                        child: Center(child: CircularProgressIndicator(color: primaryAmethyst)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        height: 180,
                        width: 180,
                        child: Center(child: Icon(Icons.qr_code, size: 80, color: Colors.grey)),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Đưa mã này cho ban tổ chức tại cổng soát vé.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAmethyst,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("Đóng", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return "N/A";
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Vé của tôi 🎟️",
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryAmethyst))
          : tickets.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: fetchMyTickets,
                  color: primaryAmethyst,
                  backgroundColor: cardColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return _buildTicketCard(ticket);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_outlined, size: 80, color: textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            const Text(
              "Bạn chưa đăng ký vé nào!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              "Hãy khám phá các sự kiện và tham gia ngay nhé.",
              style: TextStyle(fontSize: 14, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAmethyst,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: const Text("Khám phá sự kiện", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final title = ticket["eventTitle"] ?? "Sự kiện";
    final location = ticket["eventLocation"] ?? "Không rõ địa điểm";
    final startTime = _formatDateTime(ticket["eventStartTime"]);
    final status = ticket["eventStatus"] ?? "Sắp diễn ra";
    final regId = ticket["registrationId"];

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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryAmethyst.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryAmethyst),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: borderColor),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: primaryAmethyst),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(fontSize: 14, color: textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: accentTeal),
                const SizedBox(width: 8),
                Text(
                  startTime,
                  style: const TextStyle(fontSize: 14, color: textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showQrTicketDialog(ticket),
                    icon: const Icon(Icons.qr_code_rounded, size: 18),
                    label: const Text("Xem vé QR", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryAmethyst,
                      side: const BorderSide(color: primaryAmethyst, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => cancelTicket(regId),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text("Hủy vé", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFFEF4444),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
