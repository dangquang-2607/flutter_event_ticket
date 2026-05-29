import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../../../core/constants/api_constants.dart';

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
        "${AppConstants.eventsEndpoint}/${widget.eventId}/members",
      );
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          members = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          members = [];
          isLoading = false;
        });
        debugPrint("Lỗi tải danh sách tham gia: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      debugPrint("Lỗi khi tải thành viên sự kiện: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryAmethyst = Color(0xFF7C3AED);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30, color: Color(0xFFE2E8F0)),
        Text(
          "Người tham gia (${members.length})",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        isLoading
            ? const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: primaryAmethyst),
              ))
            : members.isEmpty
            ? const Text(
                "Chưa có người tham gia nào (0).",
                style: TextStyle(color: Color(0xFF475569), fontSize: 14),
              )
            : Column(
                children: members.map((m) {
                  final email = m["email"] ?? "N/A";
                  String date = "";
                  if (m["registrationDate"] != null) {
                    try {
                      final parsedDate = DateTime.parse(m["registrationDate"]);
                      date = "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
                    } catch (_) {
                      date = m["registrationDate"].toString().substring(0, 10);
                    }
                  } else {
                    date = "N/A";
                  }
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: primaryAmethyst, size: 20),
                      ),
                      title: Text(
                        email,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      subtitle: Text(
                        "Đăng ký ngày: $date",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }
}
