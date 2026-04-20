import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class EventMembersList extends StatefulWidget {
  final int eventId;
  const EventMembersList({super.key, required this.eventId});

  @override
  State<EventMembersList> createState() => _EventMembersListState();
}

class _EventMembersListState extends State<EventMembersList> {
  List<dynamic> members = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    try {
      final box = GetStorage();
      final token = box.read("accessToken");

      final url = Uri.parse(
        "http://10.0.2.2:5054/api/events/${widget.eventId}/members",
      );
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("👥 Members Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          members = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❌ Lỗi tải danh sách tham gia: ${response.statusCode}",
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30),
        const Text(
          "Người tham gia",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : members.isEmpty
            ? const Text("Chưa có người tham gia nào.")
            : Column(
                children: members.map((m) {
                  final email = m["email"] ?? "N/A";
                  final date =
                      m["registrationDate"]?.toString().substring(0, 16) ?? "";
                  return ListTile(
                    leading: const Icon(Icons.person, color: Colors.blue),
                    title: Text(email),
                    subtitle: Text("Đăng ký: $date"),
                  );
                }).toList(),
              ),
      ],
    );
  }
}
