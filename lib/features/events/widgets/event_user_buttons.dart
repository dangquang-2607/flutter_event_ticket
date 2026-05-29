import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import '../../../core/constants/api_constants.dart';
import '../screens/payment_screen.dart';

class EventUserButtons extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final double price;

  const EventUserButtons({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.price,
  });

  @override
  State<EventUserButtons> createState() => _EventUserButtonsState();
}

class _EventUserButtonsState extends State<EventUserButtons> {
  bool isRegistered = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkRegistration();
  }

  /// Lấy token từ GetStorage (thống nhất với toàn bộ ứng dụng)
  String? _getToken() {
    final box = GetStorage();
    return box.read("accessToken");
  }

  // Kiểm tra trạng thái đăng ký từ backend
  Future<void> checkRegistration() async {
    setState(() => isLoading = true);
    try {
      final token = _getToken();

      final url = Uri.parse(
        "${AppConstants.registrationsEndpoint}/check/${widget.eventId}",
      );

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          isRegistered = data["isRegistered"] ?? false;
        });
      } else {
        setState(() => isRegistered = false);
      }
    } catch (e) {
      setState(() => isRegistered = false);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Tham gia sự kiện
  Future<void> registerEvent() async {
    setState(() => isLoading = true);
    try {
      final token = _getToken();
      final url = Uri.parse(
        "${AppConstants.registrationsEndpoint}/register-event",
      );

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"eventId": widget.eventId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => isRegistered = true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đăng ký sự kiện thành công")),
        );
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${data["message"] ?? "Đã xảy ra lỗi"}")),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Lỗi: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Hủy tham gia sự kiện
  Future<void> cancelRegistration() async {
    setState(() => isLoading = true);
    try {
      final token = _getToken();
      final url = Uri.parse(
        "${AppConstants.registrationsEndpoint}/cancel-registration/${widget.eventId}",
      );

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"eventId": widget.eventId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => isRegistered = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Hủy đăng ký thành công")),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Lỗi: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> registerEventAndShowSuccess() async {
    setState(() => isLoading = true);
    try {
      final token = _getToken();
      final url = Uri.parse(
        "${AppConstants.registrationsEndpoint}/register-event",
      );

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"eventId": widget.eventId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => isRegistered = true);
        if (!mounted) return;
        Get.to(() => PaymentSuccessScreen(eventTitle: widget.eventTitle))?.then((_) {
          checkRegistration();
        });
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${data["message"] ?? "Đăng ký thất bại"}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi kết nối: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryAmethyst = Color(0xFF7C3AED);
    const accentTeal = Color(0xFF0D9488);
    const crimsonRed = Color(0xFFEF4444);

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(color: primaryAmethyst),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isRegistered
                ? null
                : () {
                    if (widget.price > 0) {
                      Get.to(() => PaymentScreen(
                            eventId: widget.eventId,
                            eventTitle: widget.eventTitle,
                            price: widget.price,
                          ))?.then((_) {
                        checkRegistration();
                      });
                    } else {
                      registerEventAndShowSuccess();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentTeal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              disabledForegroundColor: const Color(0xFF94A3B8),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            child: Text(isRegistered ? "Đã đăng ký" : "Tham gia sự kiện"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isRegistered ? cancelRegistration : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: crimsonRed,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFF1F5F9),
              disabledForegroundColor: const Color(0xFFCBD5E1),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            child: const Text("Hủy tham gia"),
          ),
        ),
      ],
    );
  }
}

