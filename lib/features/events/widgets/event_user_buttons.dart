import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../../../core/constants/api_constants.dart';

class EventUserButtons extends StatefulWidget {
  final int eventId;
  const EventUserButtons({super.key, required this.eventId});

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

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isRegistered ? null : registerEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Tham gia sự kiện"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: isRegistered ? cancelRegistration : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Hủy tham gia"),
          ),
        ),
      ],
    );
  }
}

