import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  // 👈 Kiểm tra trạng thái đăng ký từ backend
  Future<void> checkRegistration() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");

      // API check đăng ký
      final url = Uri.parse(
        "http://10.0.2.2:5054/api/registrations/check/${widget.eventId}",
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
        // Giả sử API trả về { "isRegistered": true/false }
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

  // 👈 Tham gia sự kiện
  Future<void> registerEvent() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");
      final url = Uri.parse(
        "http://10.0.2.2:5054/api/registrations/register-event",
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đăng ký sự kiện thành công")),
        );
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${data["message"] ?? "Đã xảy ra lỗi"}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Lỗi: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 👈 Hủy tham gia sự kiện
  Future<void> cancelRegistration() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");
      final url = Uri.parse(
        "http://10.0.2.2:5054/api/registrations/cancel-registration/${widget.eventId}",
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Hủy đăng ký thành công")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi: ${response.statusCode}")),
        );
      }
    } catch (e) {
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
